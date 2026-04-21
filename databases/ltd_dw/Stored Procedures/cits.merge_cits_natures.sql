SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [cits].[merge_cits_natures]
AS
/*-----------LTD_GLOSSARY---------------
 created by	:  B. Eichberger
 created dt	:  2025-04-02
 purpose	:  insert changes to natures of intput from staging into cits_nature_of_input
 use		:  exec cits.merge_cits_natures

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

DROP TABLE IF EXISTS #citsloadn
select ID, [Nature of Input], Category, IsActive, Filesource 
INTO #citsloadn 
FROM  [cits].[stage_Nature_of_Input]



MERGE [cits].[Nature_of_Input] AS t
USING #citsloadn AS s
ON (t.[ID] = s.[ID]
)
WHEN MATCHED AND (
	 ISNULL(t.[Nature of Input],'') <> ISNULL(s.[Nature of Input],'')
	OR ISNULL(t.Category,'') <> ISNULL(s.category,'')
	OR ISNULL(t.IsActive,0) <> ISNULL(s.IsActive,0)
	)
THEN UPDATE SET 
t.[FileSource] = s.[FileSource]
,t.[Nature of Input] = s.[Nature of Input]
,t.Category = s.category
,t.IsActive = s.IsActive
,record_updated_date = SYSDATETIME()
,record_update_count = ISNULL(record_update_count,0) + 1
WHEN NOT MATCHED BY TARGET
	THEN INSERT
		 (   [ID]
			,[filesource]
			,[Nature of Input]
			,Category
			,IsActive
		 )
VALUES
(s.ID, s.filesource, s.[Nature of Input], s.Category, s.IsActive)
OUTPUT $action INTO @outputTbl;

DECLARE @ins INT = (SELECT COUNT(*)FROM @outputTbl WHERE actionNm = 'INSERT');
DECLARE @upd INT = (SELECT COUNT(*)FROM @outputTbl WHERE actionNm = 'UPDATE');
DECLARE @prg VARCHAR(90) = @@SERVERNAME + '.ltd_dw.cits.merge_cits_natures';


	
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
SELECT 'CIDN'
,'ltd_dw.cits.cits_nature_of_input'
,'CITS'
,@prg
,ISNULL(@ins, 0)
,ISNULL(@upd, 0)
,0
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
