SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   PROCEDURE [model].[newflyer_parameter_values]

AS
-- exec [model].[newflyer_parameter_values_v2] 

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

DROP TABLE IF EXISTS #veh_nfp 
CREATE TABLE #veh_nfp  (rn INT IDENTITY(1,1),license_number varchar(32),lastdate date)
INSERT #veh_nfp  (license_number,lastdate)
SELECT EQ_equip_no AS license_number,isnull(lastdate,'4/1/2021') lastdate FROM model.Vehicle v
	LEFT JOIN (SELECT MAX(last_input_time) lastdate,license_number from [model].[NewFlyer_Parameters] GROUP BY license_number) 
				d ON d.license_number = v.EQ_equip_no 
	WHERE electric = 1 AND is_retired_or_sold = 0 
	GROUP BY EQ_equip_no,lastdate

--SELECT * FROM #veh_nfp
DECLARE @startdate DATE = (	SELECT MIN(lastdate) FROM #veh_nfp )
DECLARE @CutoffDate date = DATEADD(DAY, -2, getdate())


;WITH seq(n) AS 
(
  SELECT 0 UNION ALL SELECT n + 1 FROM seq
  WHERE n < DATEDIFF(DAY, @StartDate, @CutoffDate)
),
d(d) AS 
(
  SELECT DATEADD(DAY, n, @StartDate) FROM seq
),
src AS
(
  SELECT
    TheDate         = CONVERT(date, d),
    calendar_id	 = convert(varchar(32),d,112)+100000000
  FROM d
)
SELECT rn = row_number() over (order by thedate),
* 
into #dttable
FROM src
  ORDER BY TheDate
  OPTION (MAXRECURSION 0);
--select * from #dttable order by rn


SELECT rn = ROW_NUMBER() OVER (ORDER BY d.TheDate,v.license_number),
d.TheDate,d.calendar_id,v.license_number 
INTO #loopmaker
FROM #dttable d 
INNER JOIN  #veh_nfp  v ON v.lastdate <= d.thedate

DECLARE @i INT = 1
DECLARE @r INT = (SELECT MAX(rn) FROM #loopmaker)

WHILE @i <= @r
BEGIN
DECLARE @licCurr INT = (SELECT license_number FROM #loopmaker WHERE rn = @i)
declare @dtCurr date = (SELECT thedate FROM #loopmaker WHERE rn = @i)



DROP TABLE IF EXISTS wrk.prepPARVAL;
DROP TABLE IF EXISTS wrk.locMODELPAR;
DROP TABLE IF EXISTS wrk.polyPolygon;
DROP TABLE IF EXISTS wrk.ParamOutput;

CREATE TABLE wrk.locMODELPAR (license_number int,last_input_time datetime,GPS_LAT NUMERIC(16,8),GPS_LON NUMERIC(16,8))


INSERT wrk.locMODELPAR (license_number,last_input_time,GPS_LAT,GPS_LON)
SELECT  o.license_number,
		cast(o.last_input_time as datetime) last_input_time,
		SUM(o.GPS_LAT) GPS_LAT,
		SUM(o.GPS_LON) GPS_LON 
FROM (
SELECT  t.license_number,
        CAST(t.last_input_time AS DATETIME) last_input_time,
		CASE WHEN t.parameter_type = 280 THEN t.last_input_value ELSE 0 END AS GPS_LAT ,
		CASE WHEN t.parameter_type = 281 THEN t.last_input_value ELSE 0 END AS GPS_LON 
FROM dbo.newflyer_vehicleParameters t
	WHERE t.parameter_type IN (280,281) 
	AND t.license_number = @licCurr
	AND t.last_input_value IS NOT NULL
	AND cast(t.last_input_time as date) = @dtCurr
	AND t.license_number IS NOT NULL
	GROUP BY t.license_number,
			CAST(t.last_input_time AS DATETIME) ,
			CASE WHEN t.parameter_type = 280 THEN t.last_input_value ELSE 0 END ,
			CASE WHEN t.parameter_type = 281 THEN t.last_input_value ELSE 0 END        
	) o
GROUP BY  o.license_number,o.last_input_time
HAVING 
	SUM(o.GPS_LAT) <> 0 AND SUM(o.GPS_LON) <> 0



DROP TABLE IF EXISTS wrk.polyPolygon
select y.poly INTO wrk.polyPolygon FROM (
SELECT GEOGRAPHY::STGeomFromText((SELECT geogCol2 FROM geo.SpatialTable WHERE geogName = 'Glenwood Extended'), 4269 ) AS poly) y 


SELECT CAST(CAST( CONVERT(varchar(32), cast(t.last_input_time as datetime),112) AS int)+100000000 AS VARCHAR(32))
	+ RIGHT('000000'+CAST([dbo].[F_DATE_TO_SEC_SINCE_MIDNITE](cast(t.last_input_time as datetime)) AS VARCHAR(8)),6) AS parameter_spm_key
, CAST(CAST( CONVERT(varchar(32), cast(t.last_input_time as datetime),112) AS int)+100000000 AS VARCHAR(32)) as start_calendar_id
, cast(RIGHT('000000'+CAST([dbo].[F_DATE_TO_SEC_SINCE_MIDNITE](cast(t.last_input_time as datetime)) AS VARCHAR(8)),6) AS INT) start_spm
, parameter_type
, replace(replace(parameter_type_description,'GPS_Speed','GPS Speed'),'_',' ') parameter_type_description
, t.license_number
, t.last_input_value
, cast(t.last_input_time as datetime) last_input_time 
, l.GPS_LAT
, l.GPS_LON
INTO wrk.prepPARVAL
FROM [dbo].[newflyer_vehicleParameters] t WITH (NOLOCK) 
JOIN wrk.locMODELPAR l ON cast(l.last_input_time as datetime)= cast(t.last_input_time as datetime) AND l.license_number = t.license_number  
where t.license_number = @licCurr 
and parameter_type NOT IN (280,281,13068)
AND t.last_input_value IS NOT NULL
AND cast(t.last_input_time as date) = @dtCurr
GROUP BY parameter_type
, replace(replace(t.parameter_type_description,'GPS_Speed','GPS Speed'),'_',' ') 
, t.license_number
, t.last_input_value
, cast(t.last_input_time as datetime)
, l.GPS_LAT
, l.GPS_LON


INSERT [model].[NewFlyer_Parameters](
[parameter_spm_key]
	  ,parameter_type_key
	  ,drive_license_key
      ,[license_number]
      ,[last_input_value]
      ,[last_input_time]
      ,[start_calendar_id]
      ,[start_spm]
      ,[GPS_LAT]
      ,[GPS_LON]
      ,[param_cal_id]
      ,[DriveOrGlenwood])
SELECT h.parameter_spm_key,
	   e.parameter_type_key as parameter_type_key,
	   CAST(i.drive_id AS VARCHAR(32)) + RIGHT('000000'+ CAST(h.license_number AS VARCHAR(32)),6) drive_license_key ,
       h.license_number,
       h.last_input_value,
       h.last_input_time,
       h.start_calendar_id,
       h.start_spm,
       h.GPS_LAT,h.GPS_LON,
	   param_cal_id,
       CASE WHEN point.STIntersection(poly).ToString() LIKE 'POINT%' THEN 'DRIVE' ELSE 'GLENWOOD' END DriveOrGlenwood
FROM (
SELECT r.parameter_spm_key,
       r.parameter_type,
	   r.parameter_type_description,
       r.license_number,
       r.last_input_value,
       cast(r.last_input_time as datetime) last_input_time,
	   start_calendar_id,
	   start_spm,
       r.parameter_spm_key as param_cal_id,
       r.GPS_LAT,r.GPS_LON,
       p.poly,
	   geography::Point(r.GPS_LAT,r.GPS_LON, 4269) AS point
FROM wrk.prepPARVAL r
CROSS JOIN wrk.polyPolygon p
	WHERE cast(r.last_input_time as date) = @dtCurr
	AND r.license_number = @licCurr
) h
INNER JOIN model.dim_parameter_type e on e.parameter_type = h.parameter_type and e.parameter_type_description = h.parameter_type_description
LEFT JOIN [fact].[new_flyer_drives] i on i.license_number = h.license_number
			and h.param_cal_id between i.start_spm_key and i.end_spm_key
WHERE NOT EXISTS (select 1 from [model].[NewFlyer_Parameters] s where
			s.parameter_spm_key = h.parameter_spm_key
		and s.parameter_type_key = e.parameter_type_key
		and s.license_number = h.license_number
		and s.param_cal_id = h.param_cal_id)



DROP TABLE IF EXISTS wrk.prepPARVAL;
DROP TABLE IF EXISTS wrk.locMODELPAR;
DROP TABLE IF EXISTS wrk.polyPolygon;
DROP TABLE IF EXISTS wrk.ParamOutput;

select @i = @i + 1

if @i > @r
BREAK
	ELSE CONTINUE

END



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

       --EXEC msdb.dbo.sp_send_dbmail @profile_name = @profile
       --      ,@recipients = 'barb.eichberger@ltd.org' 
       --      ,@subject = @sub
       --      ,@body = @errormsg;

       RAISERROR (
                    @errormsg
                    ,@errsev
                    ,1
                    )
END CATCH
GO
