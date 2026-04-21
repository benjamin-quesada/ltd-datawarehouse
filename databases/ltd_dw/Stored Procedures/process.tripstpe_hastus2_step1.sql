SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE   PROCEDURE [process].[tripstpe_hastus2_step1]

@currentUser VARCHAR(42)

AS

-- =============================================
-- Author:		B. Eichberger
-- Create date: 20221110
-- Description:	Process tripstpe for planning and marketing
--				Step 1: the reminder about the file location

-- =============================================

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

--DECLARE @currentuser VARCHAR(90) = 'Heather'
DECLARE @isRunning INT = (
SELECT SUM(rc) FROM (
select ISNULL(COUNT(*),0) rc FROM SSISDB.catalog.executions WHERE project_name LIKE '%tripstpe%' AND end_time IS NULL
AND start_time >= DATEADD(MINUTE,-4,GETDATE())
UNION
SELECT ISNULL(COUNT(*),0)
FROM
(SELECT job.name, job.job_id, job.originating_server, activity.run_requested_date
, DATEDIFF(SECOND, activity.run_requested_date
, GETDATE()) AS Elapsed, activity.stop_execution_date
     FROM msdb.dbo.sysjobs_view job
          JOIN msdb.dbo.sysjobactivity activity ON job.job_id=activity.job_id
          JOIN msdb.dbo.syssessions sess ON sess.session_id=activity.session_id
          JOIN(SELECT MAX(agent_start_date) AS max_agent_start_date
               FROM msdb.dbo.syssessions) sess_max ON sess.agent_start_date=sess_max.max_agent_start_date
     WHERE run_requested_date IS NOT NULL AND stop_execution_date IS NULL AND job.name='File Processing - Tripstpe Hastus2 - Excel') i
	 ) t 
)
IF @isRunning = 0 
BEGIN

DECLARE @fixedUser VARCHAR(90) = (SELECT CASE WHEN @currentUser like '%Heather%' THEN 'LTD\Heather Lindsay' ELSE @currentUser END)	
DROP TABLE IF EXISTS process.JobStepState;
CREATE TABLE process.JobStepState
(
    Job_Name VARCHAR(90) NOT NULL, 
	VariableName varchar(25) NOT NULL,
    VariableValue varchar(25) NOT NULL,
	VariableValDate DATETIME2 DEFAULT SYSDATETIME() NOT NULL
)
GRANT SELECT ON process.JobStepState TO PUBLIC;
INSERT INTO process.JobStepState (Job_Name, VariableName, VariableValue)
VALUES ('File Processing - Tripstpe Hastus2 - Excel','UserFromPBIRS', @fixedUser
);


SELECT 
'
Greetings ' + LEFT(REPLACE(@fixedUser,'LTD\',''),CHARINDEX(' ',ISNULL(@fixedUser,9999))-5) + '
 
Please make sure you have dropped the tripstpe.xlsx file into this folder: Z:\hastus2\tripstpe\

Once that is complete, click here.
 '
 AS banner
END 

IF @isRunning <> 0 
BEGIN
SELECT 
'
Greetings ' + LEFT(REPLACE(@fixedUser,'LTD\',''),CHARINDEX(' ',ISNULL(@fixedUser,9999))-5) + '
 
The tripstpe job is running right now. Please come back later.
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
