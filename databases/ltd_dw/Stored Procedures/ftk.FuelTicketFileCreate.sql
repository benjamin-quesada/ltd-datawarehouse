SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   PROCEDURE [ftk].[FuelTicketFileCreate] 
@FuelTicketDateStart VARCHAR(90) NULL,
@FuelTicketDateEnd VARCHAR(90) NULL,
@FuelTicketContext VARCHAR(30) NULL,
@PricePerkWh VARCHAR(256) NULL,
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

BEGIN TRY

DECLARE @OutputTbl TABLE ([Key] INT)
declare @newFuelTicketKey INT

-- exec [ftk].[FuelTicketFileCreate]  '1/1/2022','1/31/2022','Test',0, 'LTD\Barb Eichberger'

	INSERT [ftk].[kWh_fuel_ticket_files] (
	   [FuelTicketDateStart]
      ,[FuelTicketDateEnd]
      ,[FuelTicketContext]
	  ,[PricePerkWh]
      ,[FuelTicketCreatedBy]
	  ,[FuelTicketHistoryRankorder]
		)
	OUTPUT INSERTED.[FuelTicketKey] INTO @OutputTbl([Key])
	SELECT 
		 @FuelTicketDateStart
		,@FuelTicketDateEnd
		,@FuelTicketContext
		,@PricePerkWh
		,@ftkUser
		,1 -- [FuelTicketHistoryRankorder] 


	-- do not allow entering a new FuelTicket with the same code, desc, group and ltdcode that is currently active
	-- can enter one combo that was deactivated previously
	-- select * from [ftk].[kWh_fuel_ticket_files] delete from [ftk].[kWh_fuel_ticket_files] where ftkFuelTicketKey >= 19
	-- truncate table [ftk].[kWh_fuel_ticket_files]
	select @newFuelTicketKey = (select top(1) [Key] from @OutputTbl ORDER BY [Key])
	UPDATE [ftk].[kWh_fuel_ticket_files]
	SET [historyFuelTicketKey] = @newFuelTicketKey
	WHERE [historyFuelTicketKey] is null and [FuelTicketKey] = @newFuelTicketKey
	
-- output back to report
SELECT [FuelTicketKey]
	  --,[historyFuelTicketKey]
       ,[FuelTicketDateStart]
      ,[FuelTicketDateEnd]
      ,[FuelTicketContext]
	  ,[PricePerkWh]
      ,[FuelTicketCreatedBy]
	  ,[FuelTicketCreateDate]
	  ,[FuelTicketHistoryRankorder]
FROM [ftk].[kWh_fuel_ticket_files] 
WHERE [FuelTicketHistoryRankorder] = 1 AND FuelTicketKey = @newFuelTicketKey
		
END TRY	  

BEGIN CATCH

       DECLARE @profile VARCHAR(255) = (
                    SELECT TOP(1) [NAME]
                    FROM msdb.dbo.sysmail_profile ORDER BY [NAME]
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
