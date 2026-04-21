SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE       PROCEDURE [hastus].[merge_trip_stop_time]
AS

/*-----------LTD_GLOSSARY---------------
UPDATED BY:	Sopheap Suy
UPDATED DT: 05/20/2025 
purpose	:	merge hastus.trip_stop_time from hastus.trip_stop_time_stg
use		:	exec hastus.merge_trip_stop_time

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
DECLARE @bid VARCHAR(5)

SELECT @cnt = COUNT(*) FROM hastus.trip_stop_time_stg
IF ( @cnt > 0 )
-- check to see if there is any data in the table before processing
BEGIN

SELECT @bid = MAX( route_version)
FROM hastus.trip_stop_time_stg;

UPDATE hastus.trip_stop_time_stg
SET trip_note_id = NULL
WHERE LTRIM(RTRIM(trip_note_id)) = ''

UPDATE hastus.trip_stop_time_stg
SET trip_stop_note_id = NULL
WHERE LTRIM(RTRIM(trip_stop_note_id)) = ''

UPDATE hastus.trip_stop_time_stg
SET trip_stop_is_time_point = NULL
WHERE LTRIM(RTRIM(trip_stop_is_time_point)) = ''

SELECT DISTINCT route_version,
	LTRIM(RTRIM(route_id)) route_id,
	LTRIM(RTRIM(route_description)) route_description ,
	LTRIM(RTRIM(trip_number)) trip_number ,
	LTRIM(RTRIM(trip_note_id)) trip_note_id ,
	LTRIM(RTRIM(trip_stop_place)) trip_stop_place ,
	LTRIM(RTRIM(stop_id)) stop_id ,
	LTRIM(RTRIM(trip_stop_arrival_time)) trip_stop_arrival_time ,
	LTRIM(RTRIM(trip_stop_note_id)) trip_stop_note_id ,
	LTRIM(RTRIM(trip_stop_is_time_point)) trip_stop_is_time_point ,
	LTRIM(RTRIM(trip_point_place_description)) trip_point_place_description ,
	LTRIM(RTRIM(trip_operating_days)) trip_operating_days
	INTO #trip_stop_time
FROM hastus.trip_stop_time_stg
WHERE stop_id IS NOT NULL

DECLARE @sdt DATETIME2 = SYSDATETIME()
DECLARE @outputTbl TABLE (actionNm VARCHAR(32))
MERGE hastus.trip_stop_time AS dst
USING #trip_stop_time AS src
ON (
       dst.route_version = src.route_version
       AND dst.route_id = src.route_id
       AND dst.trip_number = src.trip_number
       AND dst.stop_id = src.stop_id
       AND dst.trip_stop_arrival_time = src.trip_stop_arrival_time
	   AND dst.trip_operating_days = src.trip_operating_days
   )
WHEN MATCHED AND (
                     ISNULL(dst.route_description, '') <> ISNULL(src.route_description, '')
                     OR ISNULL(dst.trip_note_id, '') <> ISNULL(src.trip_note_id, '')
                     OR ISNULL(dst.trip_stop_place, '') <> ISNULL(src.trip_stop_place, '')
                     OR ISNULL(dst.trip_stop_note_id, '') <> ISNULL(src.trip_stop_note_id, '')
                     OR ISNULL(dst.trip_stop_is_time_point, '') <> ISNULL(src.trip_stop_is_time_point, '')
                     OR ISNULL(dst.trip_point_place_description, '') <> ISNULL(src.trip_point_place_description, '')                     
                 ) THEN
    UPDATE SET dst.route_description = src.route_description,
               dst.trip_note_id = src.trip_note_id,
               dst.trip_stop_place = src.trip_stop_place,
               dst.trip_stop_note_id = src.trip_stop_note_id,
               dst.trip_stop_is_time_point = src.trip_stop_is_time_point,
               dst.trip_point_place_description = src.trip_point_place_description,
               dst.trip_operating_days = src.trip_operating_days,
               dst.record_create_date = GETDATE()
WHEN NOT MATCHED BY TARGET THEN
    INSERT
    (
        route_version,
        route_id,
        route_description,
        trip_number,
        trip_note_id,
        trip_stop_place,
        stop_id,
        trip_stop_arrival_time,
        trip_stop_note_id,
        trip_stop_is_time_point,
        trip_point_place_description,
        trip_operating_days
    )
    VALUES
    (src.route_version, src.route_id, src.route_description, src.trip_number, src.trip_note_id, src.trip_stop_place,
     src.stop_id, src.trip_stop_arrival_time, src.trip_stop_note_id, src.trip_stop_is_time_point,
     src.trip_point_place_description, src.trip_operating_days )
WHEN NOT MATCHED BY SOURCE AND dst.route_version = @bid THEN
    DELETE
OUTPUT $action
INTO @outputTbl;
 
TRUNCATE TABLE hastus.trip_stop_time_stg ;

UPDATE t1
SET t1.trip_point_place_description = t2.trip_point_place_description
FROM hastus.trip_stop_time t1
INNER JOIN hastus.trip_stop_time t2 
ON t1.trip_number = t2.trip_number
AND t1.trip_stop_arrival_time = t2.trip_stop_arrival_time
AND t1.trip_operating_days = t2.trip_operating_days
AND t1.route_version = t2.route_version
where (t1.trip_stop_is_time_point IS NULL 
AND  t2.trip_stop_is_time_point IS NOT NULL)

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
		,'ltd_dw.hastus.trip_stop_time' 
		,'hastus.trip_stop_time_stg'
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
