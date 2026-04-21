SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [process].[new_ttv_after_calendaring_step2] @currentUser VARCHAR(42), @p_ttv VARCHAR(42)

AS

/*================LTD_GLOSSARY=============================
 Author:		B Eichberger
 Create date:	20241231
 Description:	Process TTV Calendaring for bids
 example:		exec process.new_ttv_after_calendaring_step2 'LTD\Barb Eichberger'
			    (the parameter is transferred from process.new_ttv_after_calendaring_step1
				via SSRS in the PBIRS)

 =============================================*/


SET NOCOUNT ON

DECLARE @SPROC VARCHAR(100)
SET @SPROC = OBJECT_SCHEMA_NAME(@@PROCID) + '.' + OBJECT_NAME(@@PROCID)+ ' (' + @currentUser + ')'

INSERT INTO DBA.[aud].[Object_Activity]
	([server_name], [database_name] ,[host_name], [System_User], [object_name]
	,[client_net_address], [local_net_address], [auth_Scheme], [last_read], [last_write]
	,[most_recent_sql_handle], [Timestamp], object_type)
SELECT DISTINCT @@SERVERNAME, DB_NAME(),HOST_NAME(),SYSTEM_USER, LEFT(@SPROC,100),
	client_net_address, local_net_address , auth_Scheme, last_read, last_write 
	,most_recent_sql_handle, CURRENT_TIMESTAMP AS [Timestamp], 'PROC'
FROM sys.dm_exec_connections 
WHERE session_id = @@SPID ;

BEGIN TRY


DECLARE @isRunning INT = (
	SELECT ISNULL(COUNT(*),0)
	FROM
		(SELECT job.name, job.job_id, job.originating_server, activity.run_requested_date
		, DATEDIFF(SECOND, activity.run_requested_date
		, GETDATE()) AS Elapsed, activity.stop_execution_date
			 FROM [LTD-ETL].msdb.dbo.sysjobs_view job
				  JOIN [LTD-ETL].msdb.dbo.sysjobactivity activity ON job.job_id=activity.job_id
				  JOIN [LTD-ETL].msdb.dbo.syssessions sess ON sess.session_id=activity.session_id
				  JOIN(SELECT MAX(agent_start_date) AS max_agent_start_date
					   FROM [LTD-ETL].msdb.dbo.syssessions) sess_max ON sess.agent_start_date=sess_max.max_agent_start_date
			 WHERE run_requested_date IS NOT NULL AND stop_execution_date IS NULL AND job.name='File Processing - New TTV After Calendaring'
		) i	
	) 
	
DECLARE @fixedUser VARCHAR(90) = (SELECT CASE WHEN @currentUser like '%Heather%' THEN 'LTD\Heather Lindsay' ELSE @currentUser END)	

IF @isRunning = 0 
BEGIN

EXEC [LTD-ETL].msdb.dbo.sp_start_job @job_name='File Processing - New TTV After Calendaring'


SELECT '
As requested by '+REPLACE(@fixedUser,'LTD\','')+', the New TTV Info processing job has run.

Please read all the information shown below.
 '
 AS banner
 END



IF @isRunning <> 0 
BEGIN


DECLARE @alreadyRunner VARCHAR(90) = (
SELECT VariableValue FROM process.JobStepStateNewTTV WHERE Job_Name = 'New TTV After Calendaring' )

SELECT 
'
Greetings ' + LEFT(REPLACE(@fixedUser,'LTD\',''),CHARINDEX(' ',ISNULL(@fixedUser,9999))-5) + '
 
The new TTV processing are already running by request of '+@alreadyRunner+'. 

You can close this page.
 '
 AS banner
END 

END TRY

BEGIN CATCH

       DECLARE @profile VARCHAR(255) = (
                    SELECT NAME
                    FROM msdb.dbo.sysmail_profile
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
