SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   PROCEDURE [tm].[merge_BLOCK]
AS
/*-----------LTD_GLOSSARY---------------
created by	:  b. eichberger
created dt	:  2024-05-09
purpose	:  merge DW tm.played_announcement from tm.played_announcement_v
				from [ltd-tmdata].tmdatamart.dbo.played_announcement
use		:  exec [tm].[merge_block]


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

MERGE ltd_dw.[tm].[BLOCK] AS t
USING [LTD-TMDATA].tmdatamart.dbo.BLOCK AS s
ON (t.BLOCK_ID = s.BLOCK_ID)
WHEN MATCHED AND ISNULL(t.TIME_TABLE_VERSION_ID,0) <> ISNULL(s.TIME_TABLE_VERSION_ID,0)
OR ISNULL(t.BLOCK_ABBR,'') <> ISNULL(s.BLOCK_ABBR,'')
OR ISNULL(t.BLOCK_NUM,0) <> ISNULL(s.BLOCK_NUM,0)
OR ISNULL(t.PADDLE_NOTES,'') <> ISNULL(s.PADDLE_NOTES,'')
OR ISNULL(t.SOURCE_BLOCK_ID,0) <> ISNULL(s.SOURCE_BLOCK_ID,0)
OR ISNULL(t.MASTER_BLOCK_ID,0) <> ISNULL(s.MASTER_BLOCK_ID,0)
OR ISNULL(t.SERVICE_TYPE_ID,0) <> ISNULL(s.SERVICE_TYPE_ID,0)
OR ISNULL(t.OPERATING_MODE_ID,0) <> ISNULL(s.OPERATING_MODE_ID,0)
THEN UPDATE SET t.TIME_TABLE_VERSION_ID = s.TIME_TABLE_VERSION_ID
	,t.BLOCK_ABBR = s.BLOCK_ABBR
	,t.BLOCK_NUM = s.BLOCK_NUM
	,t.PADDLE_NOTES = s.PADDLE_NOTES
	,t.SOURCE_BLOCK_ID = s.SOURCE_BLOCK_ID
	,t.MASTER_BLOCK_ID = s.MASTER_BLOCK_ID
	,t.SERVICE_TYPE_ID = s.SERVICE_TYPE_ID
	,t.OPERATING_MODE_ID = s.OPERATING_MODE_ID
	,t.record_updated_date = sysdatetime()
WHEN NOT MATCHED BY TARGET THEN INSERT (
BLOCK_ID
,TIME_TABLE_VERSION_ID
,BLOCK_ABBR
,BLOCK_NUM
,PADDLE_NOTES
,SOURCE_BLOCK_ID
,MASTER_BLOCK_ID
,SERVICE_TYPE_ID
,OPERATING_MODE_ID
)
VALUES
(s.BLOCK_ID, s.TIME_TABLE_VERSION_ID, s.BLOCK_ABBR, s.BLOCK_NUM, s.PADDLE_NOTES, s.SOURCE_BLOCK_ID, s.MASTER_BLOCK_ID, s.SERVICE_TYPE_ID, s.OPERATING_MODE_ID)
WHEN NOT MATCHED BY SOURCE THEN DELETE
OUTPUT $action INTO @outputTbl
;


DECLARE @ins INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'INSERT')
DECLARE @upd INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'UPDATE')
DECLARE @del INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'DELETE')
DECLARE @prg varchar(90) = @@SERVERNAME + '.ltd_dw.tm.merge_block'

insert process.mergeLogs
(		[MergeCode]
           ,[ObjectDestination]
           ,[ObjectSource]
           ,[ObjectProgram]
           ,[recInsert]
           ,[recUpdate]
           ,[recDelete]
           ,[MergeBeginDatetime]
           ,[MergeEndDatetime])
select 'TMDM',
'ltd_dw.tm.BLOCK',
'TM',
@prg,
isnull(@ins,0) ,ISNULL(@upd,0),ISNULL(@del,0),
@sdt,
sysdatetime()


DROP TABLE IF EXISTS #played;

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
