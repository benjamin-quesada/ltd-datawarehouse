SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [dbo].[Get_NewFlyer_ScheduledTMTrips]
@dtdatein date

as

/*---LTD_GLOSSARY----------------------
CREATED		: 12/09/2021
AUTHOR		: B Eichberger
PURPOSE		: TransitMaster New Flyer Trip and Route Connector
USE			: exec dbo.[Get_NewFlyer_ScheduledTMTrips] '01/02/2023' 
PURPOSE		: bring tm data into ltd-dw ltd_dw that halps align transit master activity
			  with New Flyer electric activity. 
			  Review for deprecation.

------------------LTD_GLOSSARY---------------
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


---------- FOR TEST
--USE ltd_dw
--GO
--DECLARE @dtdatein date = '12/07/2021'
---------- FOR TEST

declare @calin numeric(10,0) = dbo.F_DATE_TO_CALENDAR_ID(@dtdatein)
--SELECT @calin
delete from nf.ScheduleTM_WithNF_Drive where [CalId] = @calin


SELECT s.CALENDAR_ID,
	   v.PROPERTY_TAG,
       s.TIME_TABLE_VERSION_ID,
       s.BLOCK_ID,
       s.TRIP_ID,
	   MIN(s.SCHEDULED_TIME) SCHED_START,
	   MAX(s.SCHEDULED_TIME) SCHED_END,
	   t.TRIP_END_TIME,
	   s.ROUTE_ID,
       s.ROUTE_DIRECTION_ID,
       s.OPERATOR_ID,
       s.RUN_ID,
       s.WORK_PIECE_ID,
       s.VEHICLE_ID
INTO #SCHED
FROM [ltd-tmdata].tmdatamart.[dbo].[SCHEDULE] s WITH (NOLOCK)
JOIN [ltd-tmdata].tmdatamart.[dbo].[TRIP] t WITH (NOLOCK) ON t.TRIP_ID = s.TRIP_ID
JOIN [ltd-tmdata].tmdatamart.dbo.VEHICLE v WITH (NOLOCK) ON v.VEHICLE_ID = s.VEHICLE_ID
WHERE s.CALENDAR_ID = @calin
AND v.PROPERTY_TAG BETWEEN '20200' AND '20299'
GROUP BY 
       s.CALENDAR_ID,
	   v.PROPERTY_TAG,
       s.TIME_TABLE_VERSION_ID,
       s.BLOCK_ID,
       s.TRIP_ID,
	   t.TRIP_END_TIME,
	   s.ROUTE_ID,
       s.ROUTE_DIRECTION_ID,
       s.OPERATOR_ID,
       s.RUN_ID,
       s.WORK_PIECE_ID,
       s.VEHICLE_ID
OPTION (MAXDOP 1)

SELECT OPERATOR_ID,
       BADGE,
       FIRST_NAME,
       MIDDLE_NAME,
       LAST_NAME
 INTO #op FROM [ltd-tmdata].tmdatamart.dbo.OPERATOR
OPTION (MAXDOP 1)

SELECT ROUTE_ID,
       ROUTE_ABBR,
       ROUTE_NAME
 INTO #ro FROM  [ltd-tmdata].tmdatamart.dbo.[ROUTE]
OPTION (MAXDOP 1)

SELECT ROUTE_DIRECTION_ID,
       ROUTE_DIRECTION_ABBR,
       ROUTE_DIRECTION_NAME
 INTO #rd FROM  [ltd-tmdata].tmdatamart.dbo.ROUTE_DIRECTION 
OPTION (MAXDOP 1) 

 CREATE TABLE #nf_by_day
 (drive_id BIGINT NOT NULL DEFAULT 0 ,
  vehicle_id INT NULL,
  license_number INT NOT NULL,
  found_date_time DATETIME NOT NULL,
  spm INT NOT NULL,
  CalId INT NOT NULL)

INSERT #nf_by_day (drive_id, vehicle_id, license_number, found_date_time, spm,CalId)
SELECT drive_id,vehicle_id,license_number,event_time_local
,[dbo].[F_DATE_TO_SEC_SINCE_MIDNITE](CAST(event_time_local AS DATETIME)) spm
, CAST(CONVERT(VARCHAR(32),CAST(event_time_local AS DATE),112) AS INT)+100000000 CalId 
-- select * 
FROM ltd_electric_bus.[dbo].[newflyer_trip_events] WITH (NOLOCK)
WHERE CAST(CONVERT(VARCHAR(32),CAST(event_time_local AS DATE),112) AS INT)+100000000 = @calin

INSERT #nf_by_day (drive_id, vehicle_id, license_number, found_date_time, spm,CalId)
SELECT drive_id, vehicle_id,license_number,start_time
,[dbo].[F_DATE_TO_SEC_SINCE_MIDNITE](CAST(start_time AS DATETIME)) spm
, CAST(CONVERT(VARCHAR(32),CAST(start_time AS DATE),112) AS INT)+100000000 Calid
FROM ltd_electric_bus.dbo.newflyer_trips WITH (NOLOCK) 
WHERE CAST(CONVERT(VARCHAR(32),CAST(start_time AS DATE),112) AS INT)+10000000 = @calin
 
INSERT #nf_by_day (drive_id, vehicle_id, license_number, found_date_time, spm,CalId)
SELECT 0, vehicle_id,license_number,CAST(CAST(last_input_time AS DATETIME2) AS DATETIME)
,[dbo].[F_DATE_TO_SEC_SINCE_MIDNITE](CAST(CAST(last_input_time AS DATETIME2) AS DATETIME)) spm
, CAST(CONVERT(VARCHAR(32),CAST(CAST(last_input_time AS DATETIME2) AS DATE),112) AS INT) +100000000 calid
 FROM ltd_electric_bus.dbo.newflyer_Parameters WITH (NOLOCK)
 WHERE CAST(CONVERT(VARCHAR(32),CAST(CAST(last_input_time AS DATETIME2) AS DATE),112) AS INT) +100000000 = @calin

--INSERT #nf_by_day (drive_id, vehicle_id, license_number, found_date_time, spm,CalId)
--SELECT 0,vehicle_id,license_number,locationtime_local
--,[dbo].[F_DATE_TO_SEC_SINCE_MIDNITE](CAST(locationtime_local AS DATETIME)) spm
--, CAST(CONVERT(VARCHAR(32),CAST(locationtime_local AS DATE),112) AS INT)+100000000 CalId
-- FROM ltd_electric_bus.dbo.newflyer_trip_locations WITH (NOLOCK)
-- WHERE CAST(CONVERT(VARCHAR(32),CAST(locationtime_local AS DATE),112) AS INT)+100000000 = @calin

CREATE NONCLUSTERED INDEX [ix_temp_nf_LicenseCalIDSPM_INCLUDES]
ON #nf_by_day([license_number],[CalId],[spm])
INCLUDE ([drive_id],[vehicle_id],[found_date_time])

INSERT nf.ScheduleTM_WithNF_Drive (
	   [drive_id]
      ,[vehicle_id]
      ,[license_number]
      ,[CalId]
      ,[BLOCK_ID]
      ,[TRIP_ID]
      ,[LAST_NAME]
      ,[FIRST_NAME]
      ,[MIDDLE_NAME]
      ,[ROUTE_ABBR]
      ,[ROUTE_NAME]
      ,[ROUTE_DIRECTION_ABBR]
      ,[ROUTE_DIRECTION_NAME])
SELECT st2.drive_id,
       st2.vehicle_id,
       st2.license_number,
       st2.CalId,
       st2.BLOCK_ID,
       st2.TRIP_ID,
       st2.LAST_NAME,
       st2.FIRST_NAME,
       st2.MIDDLE_NAME,
       st2.ROUTE_ABBR,
       st2.ROUTE_NAME,
       st2.ROUTE_DIRECTION_ABBR,
       st2.ROUTE_DIRECTION_NAME 
FROM (
SELECT MAX(st.drive_id) 
OVER (PARTITION BY st.vehicle_id,st.license_number,st.CalId,st.BLOCK_ID,st.TRIP_ID,st.LAST_NAME,st.FIRST_NAME,st.MIDDLE_NAME,st.ROUTE_ABBR,st.ROUTE_DIRECTION_ABBR
ORDER BY trip_id ROWS UNBOUNDED PRECEDING)
drive_id,
       st.vehicle_id,
       st.license_number,
      st.CalId,
       st.BLOCK_ID,
       st.TRIP_ID,
       st.LAST_NAME,
       st.FIRST_NAME,
       st.MIDDLE_NAME,
       st.ROUTE_ABBR,
       st.ROUTE_NAME,
       st.ROUTE_DIRECTION_ABBR,
       st.ROUTE_DIRECTION_NAME FROM 
(SELECT nf.* ,
  s.BLOCK_ID,
  s.TRIP_ID,
  s.SCHED_START,
  s.SCHED_END,
  o.LAST_NAME,o.FIRST_NAME, o.MIDDLE_NAME,
  r.ROUTE_ABBR,r.ROUTE_NAME,
  LEFT(rd.ROUTE_DIRECTION_ABBR,1) ROUTE_DIRECTION_ABBR,rd.ROUTE_DIRECTION_NAME
FROM #nf_by_day nf
INNER JOIN #SCHED s ON s.PROPERTY_TAG = nf.license_number 
					AND s.CALENDAR_ID = nf.calId 
					AND s.SCHED_START <= nf.spm  
					AND s.SCHED_END >= nf.spm  
JOIN #op o ON o.OPERATOR_ID = s.OPERATOR_ID
JOIN #ro r ON r.ROUTE_ID = s.ROUTE_ID
JOIN #rd rd ON rd.ROUTE_DIRECTION_ID = s.ROUTE_DIRECTION_ID) st
) st2
WHERE st2.drive_id <> 0
GROUP BY 
st2.drive_id,
       st2.vehicle_id,
       st2.license_number,
       st2.CalId,
       st2.BLOCK_ID,
       st2.TRIP_ID,
       st2.LAST_NAME,
       st2.FIRST_NAME,
       st2.MIDDLE_NAME,
       st2.ROUTE_ABBR,
       st2.ROUTE_NAME,
       st2.ROUTE_DIRECTION_ABBR,
       st2.ROUTE_DIRECTION_NAME

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
