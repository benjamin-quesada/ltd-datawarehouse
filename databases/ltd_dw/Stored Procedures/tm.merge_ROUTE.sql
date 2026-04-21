SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [tm].[merge_ROUTE]
as
/*-----------LTD_GLOSSARY---------------
created by	:  B. Eichberger
created dt	:  2024-05-09
purpose	:  merge tm.ROUTE from ltd-tmdata.tmdatamart.dbo.ROUTE
use		:  exec [tm].[merge_ROUTE]

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


MERGE ltd_dw.[tm].[ROUTE] AS t
USING [LTD-TMDATA].tmdatamart.dbo.[ROUTE] AS s
ON (t.ROUTE_ID = s.ROUTE_ID)
WHEN MATCHED AND
(  ISNULL(t.ROUTE_GROUP_NAME,'') <> ISNULL(s.ROUTE_GROUP_NAME,'')
OR ISNULL(t.ROUTE_ABBR,'') <> ISNULL(s.ROUTE_ABBR,'')
OR ISNULL(t.ROUTE_NAME,'') <> ISNULL(s.ROUTE_NAME,'')
OR ISNULL(t.ISREVENUE,0) <> ISNULL(s.ISREVENUE,0)
OR ISNULL(t.ROUTE_TYPE_ID,0) <> ISNULL(s.ROUTE_TYPE_ID,0)
OR ISNULL(t.SOURCE_LINE_ID,0) <> ISNULL(s.SOURCE_LINE_ID,0)
OR ISNULL(t.MASTER_ROUTE_ID,0) <> ISNULL(s.MASTER_ROUTE_ID,0))
THEN UPDATE SET t.ROUTE_GROUP_NAME = s.ROUTE_GROUP_NAME
	,t.ROUTE_ABBR = s.ROUTE_ABBR
	,t.ROUTE_NAME = s.ROUTE_NAME
	,t.ISREVENUE = s.ISREVENUE
	,t.ROUTE_TYPE_ID = s.ROUTE_TYPE_ID
	,t.SOURCE_LINE_ID = s.SOURCE_LINE_ID
	,t.MASTER_ROUTE_ID = s.MASTER_ROUTE_ID
	,t.record_updated_date = SYSDATETIME()
WHEN NOT MATCHED BY TARGET THEN INSERT (
 ROUTE_ID
,ROUTE_GROUP_NAME
,ROUTE_ABBR
,ROUTE_NAME
,ISREVENUE
,ROUTE_TYPE_ID
,SOURCE_LINE_ID
,MASTER_ROUTE_ID
)
VALUES
(s.ROUTE_ID, s.ROUTE_GROUP_NAME, s.ROUTE_ABBR, s.ROUTE_NAME, s.ISREVENUE, s.ROUTE_TYPE_ID, s.SOURCE_LINE_ID, s.MASTER_ROUTE_ID)
WHEN NOT MATCHED BY SOURCE THEN DELETE	
OUTPUT $action INTO @outputTbl;


DECLARE @ins INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'INSERT')
DECLARE @upd INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'UPDATE')
DECLARE @del INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'DELETE')
DECLARE @prg VARCHAR(90) = @@SERVERNAME + '.ltd_dw.tm.merge_ROUTE'

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
SELECT 'TMDM',
'ltd_dw.tm.ROUTE',
'TM',
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
