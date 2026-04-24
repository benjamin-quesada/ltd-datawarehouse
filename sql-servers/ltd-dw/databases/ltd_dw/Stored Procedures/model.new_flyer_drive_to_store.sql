SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE   PROCEDURE [model].[new_flyer_drive_to_store]
AS

-- exec [model].[new_flyer_drive_to_store]

/*------------------LTD_GLOSSARY---------------
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

	

INSERT -- truncate table
model.newflyer_drive_store (
[start_spm_key]
      ,[end_spm_key]
      ,[drive_license_key]
      ,[drive_id]
      ,[license_number]
      ,[start_latitude]
      ,[start_longitude]
      ,[end_latitude]
      ,[end_longitude]
      ,[distance]
      ,[drive_duration]
      ,[drive_duration_seconds]
      ,[start_time]
      ,[end_time]
      ,[trip_start_spm]
      ,[trip_end_spm]
      ,[trip_start_calendar_id]
      ,[trip_end_calendar_id]
      ,[start_trip_glenwood]
      ,[end_trip_glenwood])
SELECT q.start_spm_key
,q.end_spm_key
,q.drive_license_key
,q.drive_id
,q.license_number
,q.start_latitude
,q.start_longitude
,q.end_latitude
,q.end_longitude
,q.distance
,q.drive_duration
,q.drive_duration_seconds
,q.start_time
,q.end_time
,q.trip_start_spm
,q.trip_end_spm
,q.trip_start_calendar_id
,q.trip_end_calendar_id
,q.start_trip_glenwood
,q.end_trip_glenwood
FROM (
	SELECT CAST(trip_start_calendar_id AS VARCHAR(32)) + RIGHT('000000'+ CAST(trip_start_spm AS VARCHAR(32)),6) start_spm_key
	,CAST(trip_end_calendar_id AS VARCHAR(32)) + RIGHT('000000'+ CAST(trip_end_spm AS VARCHAR(32)),6) end_spm_key 
	,CAST(drive_id AS VARCHAR(32)) + RIGHT('000000'+ CAST(license_number AS VARCHAR(32)),6) drive_license_key
	 , o.drive_id
	, o.license_number
	, o.start_latitude
	, o.start_longitude
	, o.end_latitude
	, o.end_longitude
	, o.distance
	, o.drive_duration
	, o.drive_duration_seconds
	, o.start_time
	, o.end_time
	, o.trip_start_spm
	, o.trip_end_spm
	, o.trip_start_calendar_id
	, o.trip_end_calendar_id
	,start_trip_glenwood = CASE WHEN p1.poly IS NOT NULL THEN 'N' ELSE 'Y' END
	,end_trip_glenwood = CASE WHEN p2.poly IS NOT NULL THEN 'N' ELSE 'Y' END
	FROM (
		SELECT [drive_id]
				  ,[license_number]
				  ,[start_latitude]
				  ,[start_longitude]
				  ,[end_latitude]
				  ,[end_longitude]
				  ,[distance]
				  ,[drive_duration]
				  ,drive_duration_seconds = (LEFT([drive_duration],2) * 3600 + SUBSTRING([drive_duration], 4,2) * 60 + SUBSTRING([drive_duration], 7,2))
				  ,CAST([start_time] AS DATETIME2) start_time
				  ,CAST([end_time] AS DATETIME2) end_time
				  ,trip_start_spm = DATEDIFF(SECOND, 0,DATEADD(DAY, 0 - DATEDIFF(DAY, 0, [start_time]), [start_time]))
				  ,trip_end_spm = DATEDIFF(SECOND, 0,DATEADD(DAY, 0 - DATEDIFF(DAY, 0, [end_time]), [end_time]))
				  ,trip_start_calendar_id = CAST(CONVERT(VARCHAR(32),CAST([start_time] AS DATE),112) AS INT) + 100000000
				  ,trip_end_calendar_id = CAST(CONVERT(VARCHAR(32),CAST([end_time] AS DATE),112) AS INT) + 100000000
			 FROM [ltd_dw].[dbo].[newflyer_vehparams] p WITH (NOLOCK)
			 WHERE ISNULL(start_latitude,0) <> 0
			   AND CAST([start_time] AS DATETIME2) >= '5/1/2021'
			   AND distance > 0
			   AND license_number IS NOT NULL
			   --AND drive_id = 71352566329 -- 71352566329
			 GROUP BY 
			 [drive_id]
				  ,[license_number]
				  ,[start_latitude]
				  ,[start_longitude]
				  ,[end_latitude]
				  ,[end_longitude]
				  ,[distance]
				  ,[drive_duration]
				  ,[start_time]
				  ,[end_time]
	 ) o  
	 LEFT JOIN (SELECT GEOGRAPHY::STGeomFromText(
				(SELECT geogCol2 FROM geo.SpatialTable WHERE geogName = 'Bus Yard Glenwood')
				, 4269 ) AS poly) p1 ON (geography::Point(o.[start_latitude],o.[start_longitude], 4269)).STIntersection(p1.poly).ToString() <> 'GEOMETRYCOLLECTION EMPTY'	
	 LEFT JOIN (SELECT GEOGRAPHY::STGeomFromText(
				(SELECT geogCol2 FROM geo.SpatialTable WHERE geogName = 'Bus Yard Glenwood')
				, 4269 ) AS poly) p2 ON (geography::Point(o.[end_latitude],o.[end_longitude], 4269)).STIntersection(p2.poly).ToString() <> 'GEOMETRYCOLLECTION EMPTY'
	) q 
WHERE NOT EXISTS (SELECT 1 FROM model.newflyer_drive_store WHERE drive_id = q.drive_id)
GROUP BY 
[start_spm_key]
      ,[end_spm_key]
      ,[drive_license_key]
      ,[drive_id]
      ,[license_number]
      ,[start_latitude]
      ,[start_longitude]
      ,[end_latitude]
      ,[end_longitude]
      ,[distance]
      ,[drive_duration]
      ,[drive_duration_seconds]
      ,[start_time]
      ,[end_time]
      ,[trip_start_spm]
      ,[trip_end_spm]
      ,[trip_start_calendar_id]
      ,[trip_end_calendar_id]
      ,[start_trip_glenwood]
      ,[end_trip_glenwood]	


INSERT model.newflyer_drive_store (
[start_spm_key]
,[end_spm_key]
,[drive_license_key]
,[drive_id]
,[license_number]
,[start_latitude]
,[start_longitude]
,[end_latitude]
,[end_longitude]
,[distance]
,[drive_duration]
,[drive_duration_seconds]
,[start_time]
,[end_time]
,[trip_start_spm]
,[trip_end_spm]
,[trip_start_calendar_id]
,[trip_end_calendar_id]
,[start_trip_glenwood]
,[end_trip_glenwood])
SELECT q.start_spm_key
,q.end_spm_key
,q.drive_license_key
,q.drive_id
,q.license_number
,q.start_latitude
,q.start_longitude
,q.end_latitude
,q.end_longitude
,q.distance
,q.drive_duration
,q.drive_duration_seconds
,q.start_time
,q.end_time
,q.trip_start_spm
,q.trip_end_spm
,q.trip_start_calendar_id
,q.trip_end_calendar_id
,q.start_trip_glenwood
,q.end_trip_glenwood
FROM (
	SELECT CAST(trip_start_calendar_id AS VARCHAR(32)) + RIGHT('000000'+ CAST(trip_start_spm AS VARCHAR(32)),6) start_spm_key
	,CAST(trip_end_calendar_id AS VARCHAR(32)) + RIGHT('000000'+ CAST(trip_end_spm AS VARCHAR(32)),6) end_spm_key 
	,CAST(drive_id AS VARCHAR(32)) + RIGHT('000000'+ CAST(license_number AS VARCHAR(32)),6) drive_license_key
	 , o.drive_id
	, o.license_number
	, o.latitude AS start_latitude
	, o.longitude AS start_longitude
	, o.end_latitude
	, o.end_longitude
	, o.distance
	, o.drive_duration
	, o.drive_duration_seconds
	, o.start_time
	, o.end_time
	, o.trip_start_spm
	, o.trip_end_spm
	, o.trip_start_calendar_id
	, o.trip_end_calendar_id
	,start_trip_glenwood = CASE WHEN p1.poly IS NOT NULL THEN 'N' ELSE 'Y' END
	,end_trip_glenwood = CASE WHEN p2.poly IS NOT NULL THEN 'N' ELSE 'Y' END
	FROM (
		SELECT [drive_id]
			  ,[license_number]
			  ,[latitude]
			  ,[longitude]
			  ,[end_latitude]
			  ,[end_longitude]
			  ,NULL AS distance
			  ,NULL AS drive_duration_seconds
			  ,NULL AS drive_duration
			  ,CAST([event_time] AS DATETIME2) AS start_time
			  ,CAST([end_time] AS DATETIME2) AS end_time
			  ,trip_start_spm = DATEDIFF(SECOND, 0,DATEADD(DAY, 0 - DATEDIFF(DAY, 0, [event_time]), [event_time]))
			  ,trip_end_spm = DATEDIFF(SECOND, 0,DATEADD(DAY, 0 - DATEDIFF(DAY, 0, [end_time]), [end_time]))
			  ,trip_start_calendar_id = CAST(CONVERT(VARCHAR(32),CAST([event_time] AS DATE),112) AS INT) + 100000000
			  ,trip_end_calendar_id = CAST(CONVERT(VARCHAR(32),CAST([end_time] AS DATE),112) AS INT) + 100000000
		  FROM [ltd_dw].[dbo].[newflyer_events] e WITH (NOLOCK)
		  WHERE event_time >= '5/1/2021' 
		  --AND drive_id = 71352566329
		  AND NOT EXISTS (SELECT 1 FROM model.newflyer_drive_store WHERE drive_id = e.drive_id)
		  GROUP BY [drive_id]
			  ,[license_number]
			  ,[latitude]
			  ,[longitude]
			  ,[end_latitude]
			  ,[end_longitude]
			  ,[event_time] 
			  ,[end_time]
		 ) o  
		 LEFT JOIN (SELECT GEOGRAPHY::STGeomFromText(
					(SELECT geogCol2 FROM geo.SpatialTable WHERE geogName = 'Bus Yard Glenwood')
					, 4269 ) AS poly) p1 ON (geography::Point(o.[latitude],o.[longitude], 4269)).STIntersection(p1.poly).ToString() <> 'GEOMETRYCOLLECTION EMPTY'	
		 LEFT JOIN (SELECT GEOGRAPHY::STGeomFromText(
					(SELECT geogCol2 FROM geo.SpatialTable WHERE geogName = 'Bus Yard Glenwood')
					, 4269 ) AS poly) p2 ON (geography::Point(o.[end_latitude],o.[end_longitude], 4269)).STIntersection(p2.poly).ToString() <> 'GEOMETRYCOLLECTION EMPTY'
	) q 
WHERE NOT EXISTS (SELECT 1 FROM model.newflyer_drive_store WHERE drive_id = q.drive_id)
GROUP BY 
q.start_spm_key
,q.end_spm_key
,q.drive_license_key
,q.drive_id
,q.license_number
,q.start_latitude
,q.start_longitude
,q.end_latitude
,q.end_longitude
,q.distance
,q.drive_duration
,q.drive_duration_seconds
,q.start_time
,q.end_time
,q.trip_start_spm
,q.trip_end_spm
,q.trip_start_calendar_id
,q.trip_end_calendar_id
,q.start_trip_glenwood
,q.end_trip_glenwood	







	
END TRY	  


BEGIN CATCH

       DECLARE @profile VARCHAR(255) = (
                    SELECT NAME
                    FROM msdb.dbo.sysmail_profile
                    )
       DECLARE @errormsg VARCHAR(max)
             ,@error INT
             ,@message VARCHAR(max)
             ,@xstate INT
             ,@errsev INT
             ,@sub VARCHAR(255);

       SELECT @error = ERROR_NUMBER()
             ,@errsev = ERROR_SEVERITY()
             ,@message = ERROR_MESSAGE()
             ,@xstate = XACT_STATE();

       SELECT @errormsg = 'Error in ' + isnull(@SPROC, '') + ': ' + cast(isnull(@error, '') AS NVARCHAR(32)) + '|' + coalesce(@message, '') + '|' + cast(isnull(@xstate, '') AS NVARCHAR(32)) + '|' +cast(isnull(@errsev, '') AS NVARCHAR(32))

       SELECT @sub = 'ERROR: ' + @SPROC

       EXEC msdb.dbo.sp_send_dbmail @profile_name = @profile
             ,@recipients = 'barb.eichberger@ltd.org'--;servicedesk@ltd.org' 
             ,@subject = @sub
             ,@body = @errormsg;

       RAISERROR (
                    @errormsg
                    ,@errsev
                    ,1
                    )
END CATCH
GO
