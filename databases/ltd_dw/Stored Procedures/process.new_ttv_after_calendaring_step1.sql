SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE  PROCEDURE [process].[new_ttv_after_calendaring_step1]  @currentUser VARCHAR(42), @p_ttv VARCHAR(42)

AS
/*================LTD_GLOSSARY=============================
 Author:		B Eichberger
 Create date:	20241231
 Description:	Process TTV Calendaring for bids
 example:		exec process.new_ttv_after_calendaring_step1 'LTD\Barb Eichberger', '2409x'
				(the parameter is transferred from process.new_ttv_after_calendaring_step1
				via SSRS in the PBIRS)

 =============================================*/


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

DECLARE @isRunning INT = (
SELECT SUM(rc) FROM 	
	( --t
	SELECT ISNULL(COUNT(*),0) rc
	FROM  
		( --i
		SELECT job.name, job.job_id, job.originating_server, activity.run_requested_date
		, DATEDIFF(SECOND, activity.run_requested_date
		, GETDATE()) AS Elapsed, activity.stop_execution_date
			 FROM [LTD-ETL].msdb.dbo.sysjobs_view job
				  JOIN [LTD-ETL].msdb.dbo.sysjobactivity activity ON job.job_id=activity.job_id
				  JOIN [LTD-ETL].msdb.dbo.syssessions sess ON sess.session_id=activity.session_id
				  JOIN(SELECT MAX(agent_start_date) AS max_agent_start_date
					   FROM [LTD-ETL].msdb.dbo.syssessions) sess_max ON sess.agent_start_date=sess_max.max_agent_start_date
			 WHERE activity.run_requested_date IS NOT NULL AND activity.stop_execution_date IS NULL AND job.name='File Processing - New TTV After Calendaring'
			 ) i
		) t 
	)
	
DECLARE @fixedUser VARCHAR(90) = (SELECT CASE WHEN @currentUser LIKE '%Heather%' THEN 'LTD\Heather Lindsay' ELSE @currentUser END)	
	
DECLARE @p_ttv_present NVARCHAR(max) = (SELECT TOP(1) time_table_version_name FROM [ltd-test-ordata].tmmain.[dbo].[TIME_TABLE_VERSION] WHERE time_table_version_name = @p_ttv)
IF ISNULL(@p_ttv_present,'The calendaring for this time table version is not complete. Go back to the tmplanner app and double check the requested bid name.')
			<> 'The calendaring for this time table version is not complete. Go back to the tmplanner app and double check the requested bid name.'
			AND @isRunning = 0
BEGIN


	DROP TABLE IF EXISTS process.JobStepStateNewTTV;
	CREATE TABLE process.JobStepStateNewTTV
	(
		Job_Name VARCHAR(90) NOT NULL, 
		VariableName varchar(25) NOT NULL,
		VariableValue varchar(25) NOT NULL,
		VariableValDate DATETIME2 DEFAULT SYSDATETIME() NOT NULL
	)
	-- select * from process.JobStepStateNewTTV
	GRANT SELECT ON process.JobStepStateNewTTV TO PUBLIC;
	INSERT INTO process.JobStepStateNewTTV (Job_Name, VariableName, VariableValue)
	VALUES ('New TTV After Calendaring','UserFromPBIRS', @fixedUser
	);
	INSERT INTO process.JobStepStateNewTTV (Job_Name, VariableName, VariableValue)
	VALUES ('New TTV After Calendaring','New Bid Value', @p_ttv
	);

 
SELECT 
	'
Greetings ' + LEFT(REPLACE(@fixedUser,'LTD\',''),CHARINDEX(' ',ISNULL(@fixedUser,9999))-5) + '
 
This is the New Bid Info step. This steps exists to help verify the bid name and settings. 

Please review the informational results after clicking here to create information results for new bid: '+ @p_ttv + '. 

Errors will be noted in the output when the process finishes.
	 '
	 AS banner
END


IF ISNULL(@p_ttv_present,'The calendaring for this time table version is not complete. Go back to the tmplanner app and double check the requested bid name.')
	<> 'The calendaring for this time table version is not complete. Go back to the tmplanner app and double check the requested bid name.'
	AND @isRunning <> 0
BEGIN

DECLARE @alreadyRunner VARCHAR(90) = (
SELECT VariableValue FROM process.JobStepStateNewTTV WHERE Job_Name = 'New TTV After Calendaring' AND VariableName = 'UserFromPBIRS')

SELECT 
'
Greetings ' + LEFT(REPLACE(@fixedUser,'LTD\',''),CHARINDEX(' ',ISNULL(@fixedUser,9999))-5) + '
 
The new TTV after calendaring steps are already running by request of '+@alreadyRunner+'. Please come back later.
 '
 AS banner
END 


IF ISNULL(@p_ttv_present,'The calendaring for this time table version is not complete. Go back to the tmplanner app and double check the requested bid name.')
	= 'The calendaring for this time table version is not complete. Go back to the tmplanner app and double check the requested bid name.'
	
BEGIN

SELECT 
'
Greetings ' + LEFT(REPLACE(@fixedUser,'LTD\',''),CHARINDEX(' ',ISNULL(@fixedUser,9999))-5) + '
 
The calendaring for this time table version is not complete. Go back to the tmplanner app and double check the requested bid name.
'
 
 AS banner
END 

END TRY

BEGIN CATCH

       DECLARE @profile VARCHAR(255) = (
                    SELECT TOP(1) NAME
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
