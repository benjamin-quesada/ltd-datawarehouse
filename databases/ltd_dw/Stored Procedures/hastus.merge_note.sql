SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE    PROCEDURE [hastus].[merge_note]
AS

/*-----------LTD_GLOSSARY---------------
UPDATED BY:	sopheap suy
UPDATED DT: 05/20/2025 
purpose	:	merge hastus.note from hastus.note_stg
use		:	exec hastus.merge_note

purpose	 :  Add object activities on who, what, when call this object
			write this data to aud.object_activity table everytime it's called */

SET NOCOUNT ON

DECLARE @SPROC VARCHAR(100)
SET @SPROC = OBJECT_SCHEMA_NAME(@@PROCID) + '.' + OBJECT_NAME(@@PROCID)

INSERT INTO dba.aud.Object_Activity
	(server_name, database_name ,host_name, [System_User], object_name
	,client_net_address, local_net_address, auth_Scheme, last_read, last_write
	,most_recent_sql_handle, Timestamp, object_type)
SELECT DISTINCT @@SERVERNAME, DB_NAME(),HOST_NAME(),SYSTEM_USER, @SPROC,
	client_net_address, local_net_address , auth_Scheme, last_read, last_write 
	,most_recent_sql_handle, CURRENT_TIMESTAMP AS Timestamp, 'PROC'
FROM sys.dm_exec_connections 
WHERE session_id = @@SPID ;

BEGIN TRY

DECLARE @cnt INT

SELECT @cnt = COUNT(*) FROM hastus.note_stg
IF ( @cnt > 0 )
-- check to see if there is any data in the table before processing
BEGIN

DECLARE @sdt DATETIME2 = SYSDATETIME()
DECLARE @outputTbl TABLE (actionNm VARCHAR(32))
MERGE hastus.note AS dst
USING hastus.note_stg AS src
ON (dst.note_id = src.note_id)
WHEN MATCHED AND (
                     ISNULL(dst.note_preferred_code, '') <> ISNULL(src.note_preferred_code, '')
                     OR ISNULL(dst.note_text, '') <> ISNULL(src.note_text, '')
                     OR ISNULL(dst.note_usage, '') <> ISNULL(src.note_usage, '')
                     OR ISNULL(dst.note_public_access, '') <> ISNULL(src.note_public_access, '')
                     OR ISNULL(dst.note_owner, '') <> ISNULL(src.note_owner, '')                    
                 ) THEN
    UPDATE SET dst.note_preferred_code = src.note_preferred_code,
               dst.note_text = src.note_text,
               dst.note_usage = src.note_usage,
               dst.note_public_access = src.note_public_access,
               dst.note_owner = src.note_owner,
               dst.record_create_date =  GETDATE()
WHEN NOT MATCHED BY TARGET THEN
    INSERT
    (
        note_id,
        note_preferred_code,
        note_text,
        note_usage,
        note_public_access,
        note_owner
    )
    VALUES
    (src.note_id, src.note_preferred_code, src.note_text, src.note_usage, src.note_public_access, src.note_owner )
WHEN NOT MATCHED BY SOURCE THEN
    DELETE
OUTPUT $action
INTO @outputTbl;
 
TRUNCATE TABLE hastus.note_stg ;
/*
DECLARE @ins INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'INSERT')
DECLARE @upd INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'UPDATE')
DECLARE @del INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'DELETE')
DECLARE @prg VARCHAR(90) = @@SERVERNAME + '.ltd_dw.' + @SPROC

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
SELECT  'POAPI' 
		,'ltd_dw.hastus.note' 
		,'hastus.note_stg'
		,@prg  
		,ISNULL(@ins,0) 
		,ISNULL(@upd,0)
		,ISNULL(@del,0)
		,@sdt 
		,SYSDATETIME()
	*/
END

END TRY	  

BEGIN CATCH

       DECLARE @profile VARCHAR(255) = (
                    SELECT TOP 1 NAME
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

       SELECT @errormsg = 'Error in ' + ISNULL(@SPROC, '') + ':'  + CAST(ISNULL(@error, '') AS NVARCHAR(32)) + '|' + COALESCE(@message, '') + '|' + CAST(ISNULL(@xstate, '') AS NVARCHAR(32)) + '|' +CAST(ISNULL(@errsev, '') AS NVARCHAR(32))

       SELECT @sub = 'ERROR: ' + @SPROC

       EXEC msdb.dbo.sp_send_dbmail @profile_name = @profile
             ,@recipients = 'data@ltd.org' 
             ,@subject = @sub
             ,@body = @errormsg;

       RAISERROR (
                    @errormsg
                    ,@errsev
                    ,1
                    )
END CATCH
GO
