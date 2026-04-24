SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO







CREATE   PROCEDURE [process].[Eden_Extract_AR_step1]  @currentUser VARCHAR(42)

AS


-- ================LTD_GLOSSARY=============================
-- Author:		Sopheap Suy
-- Create date: 20240205
-- Description:	Process Eden Extract AR for finance
-- example:	exec process.Eden_Extract_AR @currentUser	

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

DECLARE @isRunning INT = (
SELECT SUM(rc) FROM 	
	( --t
	SELECT ISNULL(COUNT(*),0) rc
	FROM  
		( --i
		SELECT job.name, job.job_id, job.originating_server, activity.run_requested_date
		, DATEDIFF(SECOND, activity.run_requested_date
		, GETDATE()) AS Elapsed, activity.stop_execution_date
			 FROM [LTD-FINANCE].msdb.dbo.sysjobs_view job
				  JOIN [LTD-FINANCE].msdb.dbo.sysjobactivity activity ON job.job_id=activity.job_id
				  JOIN [LTD-FINANCE].msdb.dbo.syssessions sess ON sess.session_id=activity.session_id
				  JOIN(SELECT MAX(agent_start_date) AS max_agent_start_date
					   FROM [LTD-FINANCE].msdb.dbo.syssessions) sess_max ON sess.agent_start_date=sess_max.max_agent_start_date
			 WHERE activity.run_requested_date IS NOT NULL AND activity.stop_execution_date IS NULL AND job.name='Eden Extract AR') i
		 ) t 
	)
IF @isRunning = 0 
BEGIN

	DECLARE @fixedUser VARCHAR(90) = (SELECT CASE WHEN @currentUser like '%Heather%' THEN 'LTD\Heather Lindsay' ELSE @currentUser END)	
	DROP TABLE IF EXISTS process.JobStepStateEdenAR;
	CREATE TABLE process.JobStepStateEdenAR
	(
		Job_Name VARCHAR(90) NOT NULL, 
		VariableName varchar(25) NOT NULL,
		VariableValue varchar(25) NOT NULL,
		VariableValDate DATETIME2 DEFAULT SYSDATETIME() NOT NULL
	)
	GRANT SELECT ON process.JobStepStateEdenAR TO PUBLIC;
	INSERT INTO process.JobStepStateEdenAR (Job_Name, VariableName, VariableValue)
	VALUES ('Eden Extract AR','UserFromPBIRS', @fixedUser
	);


	SELECT 
	'
Greetings ' + LEFT(REPLACE(@fixedUser,'LTD\',''),CHARINDEX(' ',ISNULL(@fixedUser,9999))-5) + '
 
Click here to start Processing Eden Extract AR.

	 '
	 AS banner
END 

IF @isRunning <> 0 
BEGIN
SELECT 
'
Greetings ' + LEFT(REPLACE(@fixedUser,'LTD\',''),CHARINDEX(' ',ISNULL(@fixedUser,9999))-5) + '
 
The Eden Extract AR job is running right now. Please come back later.
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
