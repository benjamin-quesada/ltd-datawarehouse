SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   PROCEDURE [process].[novus_prod_download_job_maintenance]

AS
-- exec [process].[novus_prod_download_job_maintenance]


DECLARE @profile VARCHAR(255) = (
                    SELECT TOP(1) NAME
                    FROM msdb.dbo.sysmail_profile
                    )

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


DECLARE @day INT = (select day(GETDATE())) 
DECLARE @isrestored TINYINT = (
SELECT COUNT(*) FROM (
SELECT MAX(restore_date) rd FROM (
SELECT  
  [restore_date]
  FROM [ltd-DW2].[msdb].[dbo].[restorehistory]
  WHERE destination_database_name = 'Novus_PROD' ) h
  HAVING MAX(restore_date) BETWEEN EOMONTH(DATEADD(MONTH,-1,GETDATE())) AND EOMONTH(GETDATE()) ) c )
  
  IF @isrestored <> 0
  BEGIN
  
   EXEC msdb.dbo.sp_update_job  
    @job_name = N'File Processing - Get NovusPROD Db',  
    @new_name = N'File Processing - Get NovusPROD Db -- Monthly Download Complete',  
    @description = N'Monthly Download Complete.',  
    @enabled = 0 ;  

	END
 
  
  IF @isrestored = 0 AND @day >= 13
  BEGIN

EXEC msdb.dbo.sp_send_dbmail @profile_name = @profile
             ,@recipients = 'barb.eichberger@ltd.org'--;servicedesk@ltd.org' 
             ,@subject = 'INFO: Novus_PROD Restore'
             ,@body = 'The Novus_PROD database has not yet been detected for this month.'

END

IF @day = 1
BEGIN

    EXEC msdb.dbo.sp_update_job  
    @job_name = N'File Processing - Get NovusPROD Db -- Monthly Download Complete',  
    @new_name = N'File Processing - Get NovusPROD Db',  
    @description = N'Monthly Download Expected.',  
    @enabled = 1 ;  
END


	
END TRY	  


BEGIN CATCH

       
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
             ,@recipients = 'barb.eichberger@ltd.org'--;servicedesk@ltd.org' 
             ,@subject = @sub
             ,@body = @errormsg;

       RAISERROR (
                    @errormsg
                    ,@errsev
                    ,1
                    )
END CATCH
GO
