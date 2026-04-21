SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [abb].[Find_New Mac_Xrefs]
AS
/*
CREATED BY: B. Eichberger
CREATED ON: 8/31/2022
PURPOSE	  : Find new entries in EAM SUBSYS and alert IT to need for new xref 
			record (can't be automated fully because data entry doesn't always 
			get done the same time or day that the part is swapped out.

USE		  : Is scheduled in LTD-DW SQL agent:
			"Maintain Source Data - Detect new LINUXPL Subsystems Xref"


exec [abb].[Find_New Mac_Xrefs] 

------------------LTD_GLOSSARY---------------
UPDATED BY:	Sopheap Suy
UPDATED DT:  10/31/2024
purpose	 :  Add object activities on who, what, when call this object
			write this data to aud.object_activity table everytime it's called */


BEGIN TRY

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


DECLARE @newXref INT = 0
SELECT @newXref = (SELECT COUNT(*) FROM (
SELECT d.X_datetime_insert,
       d.X_userid_insert,
       d.EQ_equip_no,
       d.SUBSYS_subsystem,
       d.SUBPROP_subsys_prop,
       d.description,
       d.text_value,
	   REPLACE(d.text_value,':','') AS MaxXref 
FROM [ltd-eam].proto.[emsdba].[EQ_SUBSYS_DETAIL] d 
FULL OUTER JOIN [ltd_dw].[abb].[Fuel_Ticket_Mac_Xref] x ON REPLACE(d.text_value,':','') = x.[Mac Id] COLLATE SQL_Latin1_General_CP850_CI_AS
					  --AND d.EQ_equip_no NOT IN (SELECT [BUS NO] COLLATE SQL_Latin1_General_CP850_CI_AS FROM abb.Fuel_Ticket_Mac_Xref GROUP BY [BUS NO])
WHERE d.SUBSYS_subsystem = 'LINUXPL' 
					  AND d.SUBPROP_subsys_prop = 'POWER LINE #'
					  AND d.EQ_equip_no LIKE '2[0-9][0-9][0-9][0-9]'
					  AND d.description IS NOT NULL
					  AND x.[MAC ID] IS NULL
					  ) n )

IF @newXref > 0 
BEGIN
DECLARE @jname NVARCHAR(128)
select @jname = 'Maintain Source Data - LINUXPL Subsystems Xref'
declare @subj varchar(120) =  'New LINUXPL subsystem detected.'  
declare @msg varchar(max) = 'Check abb.[ltd-eam].proto.[emsdba].[EQ_SUBSYS_DETAIL] and [ltd_dw].[abb].[Fuel_Ticket_Mac_Xref] to create a new XREF record.'

EXEC msdb.dbo.sp_send_dbmail
    @profile_name = 'SQLData',
    @recipients = 'barb.eichberger@ltd.org',
    @subject = @subj,
	@body = @msg ;
END



END TRY

BEGIN CATCH

       DECLARE @profile VARCHAR(255) = (
                    SELECT TOP (1) NAME
                    FROM msdb.dbo.sysmail_profile
					ORDER BY Name DESC
                    )
       DECLARE @errormsg VARCHAR(MAX)
             ,@error INT
             ,@message VARCHAR(MAX)
             ,@xstate INT
             ,@errsev INT
             ,@sub VARCHAR(255);

       SELECT @error = ERROR_NUMBER()
             ,@errsev = ERROR_SEVERITY()
             ,@message = ERROR_MESSAGE()
             ,@xstate = XACT_STATE();

       SELECT @errormsg = 'Error in ' + ISNULL(@SPROC, '') + ': ' + CAST(ISNULL(@error, '') AS NVARCHAR(32)) + '|' + COALESCE(@message, '') + '|' + CAST(ISNULL(@xstate, '') AS NVARCHAR(32)) + '|' +CAST(ISNULL(@errsev, '') AS NVARCHAR(32))

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
