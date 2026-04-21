SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE   PROCEDURE [ftk].[FuelTicketFileDrop] 
@fuelticketkey INT,
@ftkUser VARCHAR(90)

AS

SET ANSI_WARNINGS OFF;

/*------------------LTD_GLOSSARY---------------
UPDATED BY:	Sopheap Suy
UPDATED DT:  10/31/2024
purpose	 :  Add object activities on who, what, when call this object
			write this data to aud.object_activity table everytime it's called */

SET NOCOUNT ON

DECLARE @SPROC VARCHAR(100)
SET @SPROC = OBJECT_SCHEMA_NAME(@@PROCID) + '.' + OBJECT_NAME(@@PROCID)

INSERT INTO DBA.[aud].[Object_Activity]
	([server_name], [database_name] ,[host_name], [System_User], [object_name]
	,[client_net_address], [local_net_address], [auth_Scheme], [last_read], [last_write]
	,[most_recent_sql_handle], [Timestamp], object_type)
SELECT DISTINCT @@SERVERNAME, DB_NAME(),HOST_NAME(),SYSTEM_USER, @SPROC,
	client_net_address, local_net_address , auth_Scheme, last_read, last_write 
	,most_recent_sql_handle, CURRENT_TIMESTAMP AS [Timestamp], 'PROC'
FROM sys.dm_exec_connections 
WHERE session_id = @@SPID ;


  -- exec [ftk].[FuelTicketFileDrop]  5,'LTD\Barb Eichberger'

BEGIN TRY

DROP TABLE IF EXISTS ##ftkOutputTbl


DECLARE @sqlnetuse NVARCHAR(900) 
DECLARE @sqlcmddrop NVARCHAR(1900)
DECLARE @sqlcmdnetDrop NVARCHAR(900)
DECLARE @FuelTicketStart DATE = (SELECT FuelTicketDateStart FROM ftk.kWh_fuel_ticket_files WHERE FuelTicketKey = @fuelticketkey)
DECLARE @FuelTicketEnd DATE = (SELECT FuelTicketDateEnd FROM ftk.kWh_fuel_ticket_files WHERE FuelTicketKey = @fuelticketkey)
DECLARE @dateintstart INT = (SELECT dbo.F_DATE_TO_CALENDAR_ID(@FuelTicketStart)-100000000)
DECLARE @dateintend  INT = (SELECT dbo.F_DATE_TO_CALENDAR_ID(@FuelTicketEnd)-100000000)

--SELECT @FuelTicketStart
--SELECT @FuelTicketEnd
--select @dateintstart
--SELECT @dateintend

create TABLE ##ftkOutputTbl (fuelstring VARCHAR(255))
INSERT ##ftkOutputTbl (fuelstring)
SELECT fuel_string  -- select * 
FROM [abb].Fuel_Ticket_Integration_TimeAdjusted_w_xref WHERE CAST(chgtday AS INT) BETWEEN @dateintstart AND @dateintend


EXECUTE sp_configure 'show advanced options', 1;  
RECONFIGURE;  
EXECUTE sp_configure 'xp_cmdshell', 1;  
RECONFIGURE;  

select @sqlnetuse = (SELECT 'net use I: \\ad.ltd.org\dfs\Fuel_Transactions')
select @sqlcmddrop = (SELECT 'bcp "select * from ##ftkOutputTbl" queryout "I:\ABB_'+RIGHT('0000000000'+CAST(@fuelticketkey AS varchar(10)),10)+'_'+CAST(@dateintstart AS VARCHAR(32))+'_'+CAST(@dateintend AS VARCHAR(32))+'.txt" -T -c') 
select @sqlcmdnetDrop = (SELECT 'net use I: /delete /y' )

EXEC master..xp_cmdshell @sqlcmdnetDrop, NO_OUTPUT
EXEC master..xp_cmdshell @sqlnetuse, NO_OUTPUT
EXEC master..xp_cmdshell @sqlcmddrop, NO_OUTPUT
EXEC master..xp_cmdshell @sqlcmdnetDrop, NO_OUTPUT

EXECUTE sp_configure 'show advanced options', 1;  
RECONFIGURE;  
EXECUTE sp_configure 'xp_cmdshell', 0;  
RECONFIGURE;  
  
UPDATE ftk.kWh_fuel_ticket_files
SET [FuelTicketFileDroppedBy] = @ftkUser WHERE FuelTicketKey = @fuelticketkey

INSERT [process].[FileDrop] (filedropname,FileDropGroup,FileDropRowCount)
SELECT 'ABB_'+RIGHT('0000000000'+CAST(@fuelticketkey AS varchar(20)),10)+'_'+CAST(@dateintstart AS VARCHAR(32))+'-'+CAST(@dateintend AS VARCHAR(32))+'.txt'
	,'FTK',(SELECT COUNT(*) FROM ##ftkOutputTbl)


SELECT fuelstring FROM ##ftkOutputTbl ORDER BY fuelstring

DROP TABLE IF EXISTS ##ftkOutputTbl

END TRY	  

BEGIN CATCH

       DECLARE @profile VARCHAR(255) = (
                    SELECT NAME
                    FROM msdb.dbo.sysmail_profile
                    )
       DECLARE @errormsg VARCHAR(max)
             ,@error INT
             ,@message VARCHAR(max)
             ,@xstate INT
             ,@errsev INT
             ,@sub VARCHAR(255);

       SELECT @error = ERROR_NUMBER()
             ,@errsev = ERROR_SEVERITY()
             ,@message = ERROR_MESSAGE()
             ,@xstate = XACT_STATE();

       SELECT @errormsg = 'Error in ' + isnull(@SPROC, '') + ': ' + cast(isnull(@error, '') AS NVARCHAR(32)) + '|' + coalesce(@message, '') + '|' + cast(isnull(@xstate, '') AS NVARCHAR(32)) + '|' +cast(isnull(@errsev, '') AS NVARCHAR(32))

       SELECT @sub = 'ERROR: ' + @SPROC

       EXEC msdb.dbo.sp_send_dbmail @profile_name = @profile
             ,@recipients = 'barb.eichberger@ltd.org' 
             ,@subject = @sub
             ,@body = @errormsg;

       RAISERROR (
                    @errormsg
                    ,@errsev
                    ,1
                    )
END CATCH



GO
