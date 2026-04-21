SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [cits].[merge_cits_deletes]
AS
/*-----------LTD_GLOSSARY---------------
 created by	:  B. Eichberger
 created dt	:  2025-04-02
 purpose	:  insert deletes from staging data into cits_deletes
 use		:  exec cits.merge_cits_deletes

 */

SET NOCOUNT ON;

DECLARE @SPROC VARCHAR(100);
SET @SPROC = OBJECT_SCHEMA_NAME(@@PROCID) + '.' + OBJECT_NAME(@@PROCID);

INSERT INTO dba.[aud].[Object_Activity]([server_name], [database_name], [host_name], [System_User], [object_name], [client_net_address], [local_net_address], [auth_Scheme], [last_read], [last_write], [most_recent_sql_handle], [Timestamp], object_type)
SELECT DISTINCT @@SERVERNAME, DB_NAME(), HOST_NAME(), SYSTEM_USER, @SPROC, client_net_address, local_net_address, auth_scheme, last_read, last_write, most_recent_sql_handle, CURRENT_TIMESTAMP AS [Timestamp], 'PROC'
FROM sys.dm_exec_connections
WHERE session_id=@@SPID;

BEGIN TRY

DECLARE @sdt DATETIME2 = SYSDATETIME();
DECLARE @outputTbl TABLE (actionNm VARCHAR(32));

DROP TABLE IF EXISTS #citsloaded
select * INTO #citsloaded 
FROM  cits.stage_CITS_Deletes
order by record_deleted_dt

--truncate table cits.[CITS_Deletes] 
MERGE cits.[CITS_Deletes] AS t
USING #citsloaded AS s
ON (t.[ID] = s.[ID]
)
WHEN MATCHED AND (
		   ISNULL(t.cits_last_deleted_dt, '1/1/2099') <> ISNULL(s.record_deleted_dt, '1/1/2099')
		OR ISNULL(t.cits_last_deleted_by, '') <> ISNULL(s.record_deleted_by, '')
	)
THEN UPDATE SET 
 t.cits_last_deleted_dt = s.record_deleted_dt
,t.cits_last_deleted_by = s.record_deleted_by
,t.[FileSource] = s.[FileSource]
WHEN NOT MATCHED BY TARGET
	THEN INSERT
		 (   [ID]
			,[filesource]
			,cits_last_deleted_dt
			,cits_last_deleted_by
		 )
VALUES
(s.ID, s.filesource, s.record_deleted_dt, s.record_deleted_by)
OUTPUT $action INTO @outputTbl;

DECLARE @outputDel TABLE (DeletedIDs VARCHAR(32));
DELETE FROM cits.CITS_Input
OUTPUT Deleted.ID INTO @outputDel
WHERE ID IN (SELECT DISTINCT id FROM #citsloaded)

DECLARE @ins INT = (SELECT COUNT(*)FROM @outputTbl WHERE actionNm = 'INSERT');
DECLARE @upd INT = (SELECT COUNT(*)FROM @outputTbl WHERE actionNm = 'UPDATE');
DECLARE @del INT = (SELECT ISNULL(COUNT(*),0) FROM @outputDel );
DECLARE @prg VARCHAR(90) = @@SERVERNAME + '.ltd_dw.cits.merge_cits_deletes';


	
INSERT process.MergeLogs
(
	[MergeCode]
   ,[ObjectDestination]
   ,[ObjectSource]
   ,[ObjectProgram]
   ,[recInsert]
   ,[recUpdate]
   ,[recDelete]
   ,[MergeBeginDatetime]
   ,[MergeEndDatetime]
)
SELECT 'CIDE'
,'ltd_dw.cits.cits_deletes'
,'CITS'
,@prg
,ISNULL(@ins, 0)
,ISNULL(@upd, 0)
,ISNULL(@del, 0)
,@sdt
,SYSDATETIME();



END TRY
BEGIN CATCH

DECLARE @profile VARCHAR(255) =
		(
			SELECT [name] FROM msdb.dbo.sysmail_profile
		);
DECLARE @errormsg VARCHAR(MAX)
,@error INT
,@message VARCHAR(MAX)
,@xstate INT
,@errsev INT
,@sub VARCHAR(255);

SELECT @error = ERROR_NUMBER()
,@errsev = ERROR_SEVERITY()
,@message = ERROR_MESSAGE()
,@xstate = XACT_STATE();

SELECT @errormsg = 'Error in ' + ISNULL(@SPROC, '') + ': ' + CAST(ISNULL(@error, '') AS NVARCHAR(32)) + '|' + COALESCE(@message, '') + '|' + CAST(ISNULL(@xstate, '') AS NVARCHAR(32)) + '|' + CAST(ISNULL(@errsev, '') AS NVARCHAR(32));

SELECT @sub = 'ERROR: ' + @SPROC;

EXEC msdb.dbo.sp_send_dbmail @profile_name = @profile
,@recipients = 'barb.eichberger@ltd.org'
,@subject = @sub
,@body = @errormsg;

RAISERROR(@errormsg, @errsev, 1);
END CATCH;
GO
