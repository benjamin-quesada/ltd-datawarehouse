SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE PROCEDURE [process].[bay_grid_step2]

@currentUser VARCHAR(90)

AS

/*

Editor		:	B. Eichberger
Edit date	:	20260609
Description	:	Adapt for migration back to LTD-DW - remove  references to [LTD-ETL]

Editor		:	B. Eichberger
Edit date	:	20260402
Description	:	Adapt for migration to LTD-ETL - change msdb job references to [LTD-ETL]

Author		:	B. Eichberger
Create date	:	20240710
Description	:	Process baygrid for planning and marketing
				Step 2: kick off processing and confirm for
					the @currentUser


UPDATED BY:	Sopheap Suy
UPDATED DT:  10/31/2024
purpose	 :  Add object activities on who, what, when call this object
			write this data to aud.object_activity table everytime it's called 
			
*/

SET NOCOUNT ON

DECLARE @SPROC VARCHAR(100)
SET @SPROC = OBJECT_SCHEMA_NAME(@@PROCID) + '.' + OBJECT_NAME(@@PROCID)

INSERT INTO DBA.[aud].[Object_Activity]
	([server_name], [database_name] ,[host_name], [System_User], [object_name]
	,[client_net_address], [local_net_address], [auth_Scheme], [last_read], [last_write]
	,[most_recent_sql_handle], [Timestamp], object_type)
SELECT DISTINCT @@SERVERNAME, DB_NAME(),HOST_NAME(),SYSTEM_USER, 'test',--@SPROC,
	client_net_address, local_net_address , auth_Scheme, last_read, last_write 
	,most_recent_sql_handle, CURRENT_TIMESTAMP AS [Timestamp], 'PROC'
FROM sys.dm_exec_connections 
WHERE session_id = @@SPID ;

BEGIN TRY

  --DECLARE @currentuser VARCHAR(120) = 'Heather'
DECLARE @isRunning INT = (
SELECT SUM(rc) FROM (
select ISNULL(COUNT(*),0) rc FROM SSISDB.catalog.executions WHERE project_name LIKE '%Load Bay Grid%' AND end_time IS NULL
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
     WHERE run_requested_date IS NOT NULL AND stop_execution_date IS NULL AND job.name='Maintain Source Data - Hastus Bay Use On Demand') i
	 ) t 
)

 

DECLARE @fixedUser VARCHAR(255) = (SELECT CASE WHEN @currentUser like '%Heather%' THEN 'LTD\Heather Lindsay' ELSE @currentUser END)	


IF @isRunning = 0 
BEGIN


EXEC msdb.dbo.sp_start_job @job_name='Maintain Source Data - Hastus Bay Use On Demand'

SELECT '
   As requested by '+REPLACE(@fixedUser,'LTD\','')+', the Bay Grid Processor has started.

   This process will update Bay Grid data and reporting objects
   in the data warehouse. Bay Grid use reports will be ready to 
   review when this proess is complete.

   You will receive an email (in about 3.5 minutes) when 
   the Bay Grid data processing is complete.

   You can close this page.
 '
 AS banner
 END

IF @isRunning <> 0 
BEGIN


SELECT 
'
Greetings ' + LEFT(REPLACE(@fixedUser,'LTD\',''),CHARINDEX(' ',ISNULL(@fixedUser,9999))-5) + '
 
The Bay Grid job was already running. Please come back later.

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
GRANT EXECUTE ON  [process].[bay_grid_step2] TO [public]
GO
