SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE    PROCEDURE [process].[Eden_Extract_CR_step2]

@currentUser VARCHAR(42)

AS

-- =============================================
-- Author:		B. Eichberger
-- Create date: 20240326
-- Description:	Process Process Eden Extract CR for finance
--				Step 2: kick off processing and confirm for
--						the @currentUser
--
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

DECLARE @isRunning INT = (
	SELECT ISNULL(COUNT(*),0)
	FROM
		(SELECT job.name, job.job_id, job.originating_server, activity.run_requested_date
		, DATEDIFF(SECOND, activity.run_requested_date
		, GETDATE()) AS Elapsed, activity.stop_execution_date
			 FROM [LTD-FINANCE].msdb.dbo.sysjobs_view job
				  JOIN [LTD-FINANCE].msdb.dbo.sysjobactivity activity ON job.job_id=activity.job_id
				  JOIN [LTD-FINANCE].msdb.dbo.syssessions sess ON sess.session_id=activity.session_id
				  JOIN(SELECT MAX(agent_start_date) AS max_agent_start_date
					   FROM [LTD-FINANCE].msdb.dbo.syssessions) sess_max ON sess.agent_start_date=sess_max.max_agent_start_date
			 WHERE run_requested_date IS NOT NULL AND stop_execution_date IS NULL AND job.name='Eden Extract CR'
		) i	
	) 
IF @isRunning = 0 
BEGIN

DECLARE @fixedUser VARCHAR(90) =  (SELECT CASE WHEN @currentUser like '%Heather%' THEN 'LTD\Heather Lindsay' ELSE @currentUser END)	
EXEC [LTD-FINANCE].msdb.dbo.sp_start_job @job_name='Eden Extract CR'


SELECT '
As requested by '+REPLACE(@fixedUser,'LTD\','')+', the Eden CR Transactions Processor has started.

This process will create a file containing transactions entered into Eden and that need to be evaluated for import into Tyler Munis. The file will be dropped here in a few minutes: \\ltd-finance\Extracts

You can close this page.
 '
 AS banner
 END

IF @isRunning <> 0 
BEGIN
--EXEC msdb.dbo.sp_start_job @job_name='File Processing - Tripstpe Hastus2 - Excel'

SELECT 
'
Greetings ' + LEFT(REPLACE(@fixedUser,'LTD\',''),CHARINDEX(' ',ISNULL(@fixedUser,9999))-5) + '
 
The Eden CR Transactions Processor job is alraedy running. Please come back later.

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
