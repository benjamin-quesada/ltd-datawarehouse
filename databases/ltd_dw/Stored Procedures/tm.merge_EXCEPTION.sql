SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   PROCEDURE [tm].[merge_EXCEPTION]
AS
/*-----------LTD_GLOSSARY---------------
created by	:  b. eichberger
created dt	:  2024-03-26
purpose	:  merge tm.EXCEPTION from ltd-tmdata.tmmain.dbo.EXCEPTION
use		:  exec [tm].[merge_EXCEPTION]


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


MERGE ltd_dw.tm.EXCEPTION AS t
USING [LTD-TMDATA].tmmain.[dbo].[EXCEPTION] AS s
ON ( t.EXC_ID = s.EXC_ID)
WHEN MATCHED AND (ISNULL(t.EXC_NAME,'') <> ISNULL(s.EXC_NAME,'')
				 OR ISNULL(t.EXC_ABBR,'') <> ISNULL(s.EXC_ABBR,'')
				 OR ISNULL(t.DAY_FLAGS,0) <> ISNULL(s.DAY_FLAGS,0)
				 OR ISNULL(t.EXCLUSION_NUMBER,0) <> ISNULL(s.EXCLUSION_NUMBER,0)
				 OR ISNULL(t.AGENCY_ID,0) <> ISNULL(s.AGENCY_ID,0) )
THEN UPDATE SET t.EXC_ID = s.EXC_ID
	,t.EXC_NAME = s.EXC_NAME
	,t.EXC_ABBR = s.EXC_ABBR
	,t.DAY_FLAGS = s.DAY_FLAGS
	,t.EXCLUSION_NUMBER = s.EXCLUSION_NUMBER
	,t.AGENCY_ID = s.AGENCY_ID
	,t.record_updated_date = SYSDATETIME()
WHEN NOT MATCHED BY TARGET THEN INSERT (
EXC_ID
,EXC_NAME
,EXC_ABBR
,DAY_FLAGS
,EXCLUSION_NUMBER
,AGENCY_ID
)
VALUES
(s.EXC_ID, s.EXC_NAME, s.EXC_ABBR, s.DAY_FLAGS, s.EXCLUSION_NUMBER, s.AGENCY_ID)
WHEN NOT MATCHED BY SOURCE THEN DELETE	
OUTPUT $action INTO @outputTbl;


DECLARE @ins INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'INSERT')
DECLARE @upd INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'UPDATE')
DECLARE @del INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'DELETE')
DECLARE @prg VARCHAR(90) = @@SERVERNAME + '.ltd_dw.tm.merge_EXCEPTION'

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
select 'TMEX',
'ltd_dw.tm.EXCEPTION',
'TMMAIN',
@prg,
isnull(@ins,0) ,ISNULL(@upd,0),ISNULL(@del,0),
@sdt,
sysdatetime()



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
