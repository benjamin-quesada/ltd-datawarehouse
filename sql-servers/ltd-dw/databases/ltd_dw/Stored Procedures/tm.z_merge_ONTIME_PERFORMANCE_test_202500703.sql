SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [tm].[z_merge_ONTIME_PERFORMANCE_test_202500703]
AS
/*-----------LTD_GLOSSARY---------------
 created by	:  b. eichberger
 created dt	:  2024-03-26
 purpose	:  merge tm.ONTIME_PERFORMANCE from ltd-tmdata.tmmain.dbo.ONTIME_PERFORMANCE
 use		:  exec [tm].[merge_ONTIME_PERFORMANCE]
			   is called by SQL Agent "Job Maintain Source Data - TM Merges"

 note		:  three views access this table data for On Time Performance report
			   http://ltd-test-bi/reports/powerbi/Transit%20Operations/On%20Time%20Performance


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

DECLARE @sdt DATETIME2 = SYSDATETIME()
DECLARE @outputTbl TABLE (actionNm VARCHAR(32));



MERGE ltd_dw.tm.ONTIME_PERFORMANCE AS t
USING ltd_dw.tm.[ontime_performance_v] AS s
ON (t.svc = s.svc
AND t.the_date = s.the_date
AND t.rte = s.rte
AND t.rte_dir = s.rte_dir
AND t.emx_block = s.emx_block
AND t.trip_end = s.trip_end
AND t.sa_tps = s.sa_tps)
WHEN MATCHED AND (
   ISNULL(t.ontime,0) <> ISNULL(s.ontime,0)
OR ISNULL(t.early,0) <> ISNULL(s.early,0)
OR ISNULL(t.late,0) <> ISNULL(s.late,0)
OR ISNULL(t.missing,0) <> ISNULL(s.missing,0)
OR ISNULL(t.not_missing,0) <> ISNULL(s.not_missing,0)
OR ISNULL(t.time_points,0) <> ISNULL(s.time_points,0) )
THEN UPDATE SET 
	 t.ontime = s.ontime
	,t.early = s.early
	,t.late = s.late
	,t.missing = s.missing
	,t.not_missing = s.not_missing
	,t.report_updated_date = SYSDATETIME()
	, t.time_points  = s.time_points
WHEN NOT MATCHED BY TARGET THEN INSERT (
svc
,the_date
,rte
,rte_dir
,emx_block
,trip_end
,sa_tps
,time_points
,ontime
,early
,late
,missing
,not_missing
)
VALUES
(s.svc, s.the_date, s.rte, s.rte_dir, s.emx_block, s.trip_end, s.sa_tps, s.time_points, s.ontime, s.early, s.late, s.missing, s.not_missing)
WHEN NOT MATCHED BY SOURCE THEN DELETE
OUTPUT $action INTO @outputTbl;


DECLARE @ins INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'INSERT')
DECLARE @upd INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'UPDATE')
DECLARE @del INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'DELETE')
DECLARE @prg VARCHAR(90) = @@SERVERNAME + '.ltd_dw.tm.merge_ONTIME_PERFORMANCE'

INSERT process.mergeLogs
(		[MergeCode]
           ,[ObjectDestination]
           ,[ObjectSource]
           ,[ObjectProgram]
           ,[recInsert]
           ,[recUpdate]
           ,[recDelete]
           ,[MergeBeginDatetime]
           ,[MergeEndDatetime])
SELECT 'OTP',
'ltd_dw.tm.ONTIME_PERFORMANCE',
'TMDM',
@prg,
ISNULL(@ins,0) ,ISNULL(@upd,0),ISNULL(@del,0),
@sdt,
SYSDATETIME()



END TRY	  

BEGIN CATCH

       DECLARE @profile VARCHAR(255) = (
                    SELECT [NAME]
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
