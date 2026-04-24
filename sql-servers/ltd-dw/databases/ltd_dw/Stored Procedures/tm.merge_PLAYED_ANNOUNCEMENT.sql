SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   PROCEDURE [tm].[merge_PLAYED_ANNOUNCEMENT]
AS
/*-----------LTD_GLOSSARY---------------
created by	:  b. eichberger
created dt	:  2024-05-09
purpose	:  merge DW tm.played_announcement from tm.played_announcement_v
				from [ltd-tmdata].tmdatamart.dbo.played_announcement
use		:  exec [tm].[merge_played_announcement]

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

DECLARE @dtLast INT = (
SELECT [dbo].[F_DATE_TO_CALENDAR_ID](MIN(dtLast)) FROM (
	SELECT MIN(record_created_date) dtLast FROM ltd_dw.[tm].[played_announcement]
	UNION 
	SELECT MIN(record_updated_date) dtLast FROM ltd_dw.[tm].[played_announcement] ) m
) 
DROP TABLE IF EXISTS #played;
SELECT v.* INTO #played
FROM tm.played_announcement_v v
LEFT JOIN ltd_dw.[tm].[played_announcement] a ON a.PLAYED_ANNOUNCEMENT_ID = v.PLAYED_ANNOUNCEMENT_ID
WHERE a.played_announcement_id IS NULL AND v.CALENDAR_ID >= @dtLast
ORDER BY v.PLAYED_ANNOUNCEMENT_ID DESC


MERGE ltd_dw.[tm].[played_announcement] AS t
USING #played AS s
ON (t.PLAYED_ANNOUNCEMENT_ID = s.PLAYED_ANNOUNCEMENT_ID)
WHEN MATCHED AND (
   ISNULL(t.ANNOUNCEMENT_ID,0) <> ISNULL(s.ANNOUNCEMENT_ID,0)
OR ISNULL(t.ANNOUNCEMENT_GROUP_ID,0) <> ISNULL(s.ANNOUNCEMENT_GROUP_ID,0)
OR ISNULL(t.CALENDAR_ID,0) <> ISNULL(s.CALENDAR_ID,0)
OR ISNULL(t.TIME_OF_DAY_ID,0) <> ISNULL(s.TIME_OF_DAY_ID,0)
OR ISNULL(t.ROUTE_ID,0) <> ISNULL(s.ROUTE_ID,0)
OR ISNULL(t.ROUTE_DIRECTION_ID,0) <> ISNULL(s.ROUTE_DIRECTION_ID,0)
OR ISNULL(t.BLOCK_ID,0) <> ISNULL(s.BLOCK_ID,0)
OR ISNULL(t.BLOCK_STOP_ORDER,0) <> ISNULL(s.BLOCK_STOP_ORDER,0)
OR ISNULL(t.OVERLOAD_ID,0) <> ISNULL(s.OVERLOAD_ID,0)
OR ISNULL(t.GEO_NODE_ID,0) <> ISNULL(s.GEO_NODE_ID,0)
OR ISNULL(t.RUN_ID,0) <> ISNULL(s.RUN_ID,0)
OR ISNULL(t.LATITUDE,0) <> ISNULL(s.LATITUDE,0)
OR ISNULL(t.LONGITUDE,0) <> ISNULL(s.LONGITUDE,0)
OR ISNULL(t.LOCAL_TIMESTAMP,'1/1/1900') <> ISNULL(s.LOCAL_TIMESTAMP,'1/1/1900')
OR ISNULL(t.[STATUS],0) <> ISNULL(s.[STATUS],0)
OR ISNULL(t.PLAYED_COMPLETE,0) <> ISNULL(s.PLAYED_COMPLETE,0)
OR ISNULL(t.AUDIOFILE_CORRUPT_MISSING,0) <> ISNULL(s.AUDIOFILE_CORRUPT_MISSING,0)
OR ISNULL(t.TEXTFILE_CORRUPT_MISSING,0) <> ISNULL(s.TEXTFILE_CORRUPT_MISSING,0)
OR ISNULL(t.INDEX_MISSING,0) <> ISNULL(s.INDEX_MISSING,0)
OR ISNULL(t.NO_AUDIO,0) <> ISNULL(s.NO_AUDIO,0)
OR ISNULL(t.NO_TEXT,0) <> ISNULL(s.NO_TEXT,0)
OR ISNULL(t.ANNOUNCEMENT_INTERRUPTED,0) <> ISNULL(s.ANNOUNCEMENT_INTERRUPTED,0)
OR ISNULL(t.VEHICLE_ID,0) <> ISNULL(s.VEHICLE_ID,0))
THEN UPDATE 
SET t.ANNOUNCEMENT_ID = s.ANNOUNCEMENT_ID
	,t.ANNOUNCEMENT_GROUP_ID = s.ANNOUNCEMENT_GROUP_ID
	,t.CALENDAR_ID = s.CALENDAR_ID
	,t.TIME_OF_DAY_ID = s.TIME_OF_DAY_ID
	,t.ROUTE_ID = s.ROUTE_ID
	,t.ROUTE_DIRECTION_ID = s.ROUTE_DIRECTION_ID
	,t.BLOCK_ID = s.BLOCK_ID
	,t.BLOCK_STOP_ORDER = s.BLOCK_STOP_ORDER
	,t.OVERLOAD_ID = s.OVERLOAD_ID
	,t.GEO_NODE_ID = s.GEO_NODE_ID
	,t.RUN_ID = s.RUN_ID
	,t.LATITUDE = s.LATITUDE
	,t.LONGITUDE = s.LONGITUDE
	,t.LOCAL_TIMESTAMP = s.LOCAL_TIMESTAMP
	,t.[STATUS] = s.[STATUS]
	,t.PLAYED_COMPLETE = s.PLAYED_COMPLETE
	,t.AUDIOFILE_CORRUPT_MISSING = s.AUDIOFILE_CORRUPT_MISSING
	,t.TEXTFILE_CORRUPT_MISSING = s.TEXTFILE_CORRUPT_MISSING
	,t.INDEX_MISSING = s.INDEX_MISSING
	,t.NO_AUDIO = s.NO_AUDIO
	,t.NO_TEXT = s.NO_TEXT
	,t.ANNOUNCEMENT_INTERRUPTED = s.ANNOUNCEMENT_INTERRUPTED
	,t.VEHICLE_ID = s.VEHICLE_ID
	,t.record_updated_date = SYSDATETIME()
WHEN NOT MATCHED BY TARGET THEN INSERT (
PLAYED_ANNOUNCEMENT_ID
,ANNOUNCEMENT_ID
,ANNOUNCEMENT_GROUP_ID
,CALENDAR_ID
,TIME_OF_DAY_ID
,ROUTE_ID
,ROUTE_DIRECTION_ID
,BLOCK_ID
,BLOCK_STOP_ORDER
,OVERLOAD_ID
,GEO_NODE_ID
,RUN_ID
,LATITUDE
,LONGITUDE
,LOCAL_TIMESTAMP
,[STATUS]
,PLAYED_COMPLETE
,AUDIOFILE_CORRUPT_MISSING
,TEXTFILE_CORRUPT_MISSING
,INDEX_MISSING
,NO_AUDIO
,NO_TEXT
,ANNOUNCEMENT_INTERRUPTED
,VEHICLE_ID
)
VALUES
(s.PLAYED_ANNOUNCEMENT_ID, s.ANNOUNCEMENT_ID, s.ANNOUNCEMENT_GROUP_ID, s.CALENDAR_ID, s.TIME_OF_DAY_ID, s.ROUTE_ID, s.ROUTE_DIRECTION_ID, s.BLOCK_ID, s.BLOCK_STOP_ORDER, s.OVERLOAD_ID, s.GEO_NODE_ID, s.RUN_ID, s.LATITUDE, s.LONGITUDE, s.LOCAL_TIMESTAMP, s.STATUS, s.PLAYED_COMPLETE, s.AUDIOFILE_CORRUPT_MISSING, s.TEXTFILE_CORRUPT_MISSING, s.INDEX_MISSING, s.NO_AUDIO, s.NO_TEXT, s.ANNOUNCEMENT_INTERRUPTED, s.VEHICLE_ID)
OUTPUT $action INTO @outputTbl
;


DECLARE @ins INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'INSERT')
DECLARE @upd INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'UPDATE')
DECLARE @del INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'DELETE')
DECLARE @prg varchar(90) = @@SERVERNAME + '.ltd_dw.tm.merge_played_announcement'

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
'ltd_dw.tm.played_announcement',
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
