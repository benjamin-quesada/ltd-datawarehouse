SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   PROCEDURE [rpt].[Get_Planning_NewFlyer_SOC_w_Events_and_Params]

AS

/*
CREATE BY:	bee
CREATE ON:  5/19/2022
PURPOSE	 :  To indicate the SOC a bus starts a block with and then what SOC it ends a block with.
			This extended version to indicate events reltaed to energy use, as well as parameter for 
			total energy used.

exec [rpt].[Get_Planning_NewFlyer_SOC_w_Events_and_Params]

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

declare @startdate date = (select isnull(min(startdt),'4/1/2020') 
		from (select license_number,max(calendar_date) startdt from rpt.Planning_NewFlyer_BLOCK_SOC_Extended e
		join tm.dw_calendar r on r.calendar_id = e.calid group by license_number ) u )

drop table if exists #DateControl
CREATE TABLE #DateControl (rn INT IDENTITY(1,1), calId INT NOT NULL, calDt DATE NOT NULL, license_number INT NOT NULL )
insert #DateControl (calId, calDt, license_number)
SELECT calId,calDt,s.PROPERTY_TAG AS license_number from (
	SELECT c.CALENDAR_ID calId, c.CALENDAR_DATE AS calDt FROM tm.DW_CALENDAR c 
	LEFT JOIN rpt.Planning_NewFlyer_BLOCK_SOC_Extended i ON i.CalId = c.CALENDAR_ID
	WHERE c.calendar_id >=  120200401
	AND c.calendar_date <= GETDATE()-2 
	AND i.calId IS null 
	) t
CROSS JOIN (SELECT PROPERTY_TAG FROM model.Vehicle_v WHERE electric = 1) s


declare @i int 
declare @r int
select @i = 1
select @r = (select max(rn) from #DateControl)

while @i <= @r
BEGIN


DECLARE @licId INT = (SELECT license_number FROM #DateControl WHERE rn = @i)
declare @calId INT = (SELECT calId FROM #DateControl WHERE rn = @i)
declare @calDt DATE = (SELECT calDt FROM #DateControl WHERE rn = @i)


DROP TABLE IF EXISTS #prePivotkWh
CREATE TABLE #prePivotkWh (license_number INT, drive_id BIGINT, kWhUsed DECIMAL(18,5))
INSERT -- select * from 
#prePivotkWh (license_number,drive_id,kWhUsed)
SELECT a.license_number,v.drive_id,
max(last_input_value) AS kWhUsed
FROM dbo.newflyer_vehicleParameters a WITH (NOLOCK)
	JOIN dbo.newflyer_vehparams v WITH (NOLOCK) ON v.license_number = a.license_number
		AND CAST(a.last_input_time AS DATETIME) BETWEEN v.start_time AND v.end_time
WHERE a.parameter_type = 49838 AND last_input_value > 0 
		AND CAST(a.last_input_time AS DATETIME) = @calDt and a.license_number = @licId
GROUP BY a.license_number,v.drive_id


--DECLARE @spanStartDt DATE = (SELECT MIN(calDt) FROM #DateControl)
--DECLARE @spanEndDt DATETIME = (SELECT CAST(CAST(MAX(calDt) AS varchar(32)) + ' 23:59:59' AS DATETIME) FROM #DateControl)

DROP TABLE IF EXISTS #prePivotEvents
CREATE TABLE #prePivotEvents (license_number INT, drive_id BIGINT, HighAcceleration INT, HighBraking INT)
INSERT -- select * from 
#prePivotEvents (license_number, drive_id, HighAcceleration, HighBraking)  
SELECT n.license_number,n.drive_id ,
			SUM(CASE WHEN n.event_type_id = 50 THEN 1 else 0 END) HighAcceleration,
			SUM(CASE WHEN n.event_type_id = 53 THEN 1 else 0 END) HighBraking
FROM -- select * from 
dbo.newflyer_events n WITH (NOLOCK) -- where cast(event_time as datetime) between '2/1/2022' and '3/30/2022'
WHERE CAST(n.event_time AS DATETIME) = @calDt and n.license_number = @licId
			AND n.event_type_id IN (50,53)
GROUP BY n.license_number,n.drive_id		

DROP TABLE IF EXISTS #tminfo
create table #tminfo (cal_msgspm_key bigint, calendar_id int,veh int,rte varchar(12), rte_dir varchar(4),block_stop_order int
,geo_node_abbr varchar(12),operator_id int,route_direction_abbr varchar(12),route_direction_name varchar(120),route_abbr varchar(12)
,route_name varchar(120), isrevenue varchar(4), block_abbr varchar(12),badge varchar(12),first_name varchar(40), middle_name varchar(40),last_name varchar(40)
,time_table_version_name varchar(16),pullout_cal_spm bigint, pullin_cal_spm bigint)
insert #tminfo (cal_msgspm_key,calendar_id,veh,rte,rte_dir,block_stop_order,geo_node_abbr,operator_id, route_direction_abbr, route_direction_name,route_abbr
,route_name,isrevenue,block_abbr, badge, first_name, middle_name,last_name,time_table_version_name,pullout_cal_spm,pullin_cal_spm)
SELECT i.cal_msgspm_key,
       i.calendar_id,
       i.veh,
       i.RTE,
       i.RTE_DIR,
       i.BLOCK_STOP_ORDER,
       i.GEO_NODE_ABBR,
       i.OPERATOR_ID,
       rd.ROUTE_DIRECTION_ABBR,
       rd.ROUTE_DIRECTION_NAME,
       r.ROUTE_ABBR,
       r.ROUTE_NAME,
       r.ISREVENUE,
       b.BLOCK_ABBR,
       o.BADGE,
       o.FIRST_NAME,
       o.MIDDLE_NAME,
       o.LAST_NAME,
       v.TIME_TABLE_VERSION_NAME,
	   CAST(i.calendar_id AS VARCHAR(32)) + RIGHT('000000' + CAST(p.ACTUAL_PULLOUT_TIME AS VARCHAR(32)),6) pullout_cal_spm,
	   CAST(i.calendar_id AS VARCHAR(32)) + RIGHT('000000' + CAST(p.ACTUAL_PULLIN_TIME AS VARCHAR(32)),6) pullin_cal_spm
  FROM [ltd_dw].[fact].TM_Info i 
JOIN [LTD-TMDATA].tmdatamart.dbo.ROUTE_DIRECTION rd ON rd.ROUTE_DIRECTION_ID = i.ROUTE_DIRECTION_ID
JOIN [LTD-TMDATA].tmdatamart.dbo.[ROUTE] r ON r.ROUTE_ID = i.ROUTE_ID
JOIN [LTD-TMDATA].tmdatamart.dbo.[BLOCK] b ON b.BLOCK_ID = i.BLOCK_ID AND	b.TIME_TABLE_VERSION_ID = i.time_table_version_id
JOIN [LTD-TMDATA].tmdatamart.dbo.OPERATOR o ON o.OPERATOR_ID = i.OPERATOR_ID
JOIN [LTD-TMDATA].tmdatamart.dbo.TIME_TABLE_VERSION v ON v.TIME_TABLE_VERSION_ID = i.time_table_version_id
JOIN model.Vehicle_v vh ON vh.PROPERTY_TAG = i.veh
JOIN [LTD-TMDATA].tmdatamart.dbo.VEHICLE_PULLOUT_PULLIN p ON p.CALENDAR_ID = i.calendar_id 
		AND p.ACTUAL_PULLOUT_VEHICLE_ID = vh.VEHICLE_ID 
		AND p.PULLOUT_OPERATOR_ID = o.OPERATOR_ID 
WHERE 1=1 
AND i.cal_msgspm_key between CAST(CAST(@calid AS VARCHAR(32))+'000000' AS bigint) AND CAST(CAST(@calid AS VARCHAR(32))+'999999' AS bigint) 
AND i.calendar_id = @calid
AND vh.PROPERTY_TAG = @licId
AND vh.electric = 1
GROUP BY i.cal_msgspm_key,
       i.calendar_id,
       i.veh,
       i.RTE,
       i.RTE_DIR,
       i.BLOCK_STOP_ORDER,
       i.GEO_NODE_ABBR,
       i.OPERATOR_ID,
       i.LATITUDE,
       i.LONGITUDE,
       rd.ROUTE_DIRECTION_ABBR,
       rd.ROUTE_DIRECTION_NAME,
       r.ROUTE_ABBR,
       r.ROUTE_NAME,
       r.ISREVENUE,
       b.BLOCK_ABBR,
       o.BADGE,
       o.FIRST_NAME,
       o.MIDDLE_NAME,
       o.LAST_NAME,
       v.TIME_TABLE_VERSION_NAME,
	   CAST(i.calendar_id AS VARCHAR(32)) + RIGHT('000000' + CAST(p.ACTUAL_PULLOUT_TIME AS VARCHAR(32)),6) ,
	   CAST(i.calendar_id AS VARCHAR(32)) + RIGHT('000000' + CAST(p.ACTUAL_PULLIN_TIME AS VARCHAR(32)),6) 

	   --SELECT * FROM #tminfo
DROP TABLE IF EXISTS #prePivotSOC
create table --SELECT * FROM 
#prePivotSOC (license_number int, calid int, [date and time] datetime, soc decimal(18,6),drive_id bigint, vehicle_id int,cal_spm_key bigint)
insert #prePivotSOC (license_number, calid,[date and time],soc,drive_id,vehicle_id,cal_spm_key)
SELECT p.license_number,calid,[date And Time],[NF XPAND_SYS_SOC (PGN: 65349)] AS SOC,
			v.drive_id,v.vehicle_id ,
			CAST(calid AS VARCHAR(32)) + RIGHT('000000' + CAST([dbo].[F_DATE_TO_SEC_SINCE_MIDNITE]([date And Time]) AS varchar(32)),6) cal_spm_key
FROM fact.NewFlyer_Parameters_Pivot p WITH (NOLOCK)
			JOIN dbo.newflyer_vehparams v WITH (NOLOCK) ON v.license_number = p.license_number
					AND p.[date and time] BETWEEN cast(v.start_time as datetime) AND cast(v.end_time as datetime)
			WHERE 1=1
			AND p.[calId] = @calid -- 120220315	2022-03-15	20201
			AND p.license_number = @licId
			AND ISNULL([NF XPAND_SYS_SOC (PGN: 65349)],0) > 0



DROP TABLE IF EXISTS #pivotReady
SELECT u.license_number,badge,u.operator_name,
    u.drive_id,
	u.calid,
	u.[Date and Time],
    u.BLOCK_ABBR,
	u.SOC,
	rnu = ROW_NUMBER() OVER (PARTITION BY u.license_number,u.BLOCK_ABBR ORDER BY u.[Date and Time])
INTO -- select * from 
#pivotReady
FROM (
SELECT pp.license_number,pp.cal_spm_key,tm.BADGE,
		COALESCE(tm.Last_Name,'') + ', ' + LEFT(RTRIM(tm.First_Name),1) operator_name,
	   pp.drive_id,
       pp.vehicle_id,
	   pp.[Date and Time],
	   pp.calid,
	   pp.SOC,
       tm.BLOCK_ABBR,
	   rnBegin = ROW_NUMBER() OVER (PARTITION BY pp.license_number,tm.BLOCK_ABBR, tm.badge ORDER BY cal_spm_key asc),
	   rnEnd = ROW_NUMBER() OVER (PARTITION BY pp.license_number,tm.BLOCK_ABBR, tm.badge ORDER BY cal_spm_key desc)
	FROM #prePivotSOC pp
	LEFT JOIN #tminfo tm ON tm.veh = pp.license_number AND pp.cal_spm_key BETWEEN tm.pullout_cal_spm AND tm.pullin_cal_spm
GROUP BY 
pp.license_number,pp.cal_spm_key,tm.BADGE,
		COALESCE(tm.Last_Name,'') + ', ' +LEFT(RTRIM(tm.First_Name),1),
       pp.drive_id,
       pp.vehicle_id,
	   pp.[Date and Time],
	   pp.calid,
	   pp.SOC,
       tm.BLOCK_ABBR
) u
WHERE u.rnBegin = 1 OR u.rnEnd = 1;

--DELETE FROM rpt.Planning_NewFlyer_BLOCK_SOC_Extended WHERE calid = @calid AND license_number = @licId

INSERT rpt.Planning_NewFlyer_BLOCK_SOC_Extended ( 
	[calId]
      ,[license_number]
      ,[Badge]
      ,[operator_name]
      ,[drive_id]
      ,[block_abbr]
      ,[kWhUsed]
      ,[HighAcceleration]
      ,[HighBraking]
      ,[BEGIN_SOC]
      ,[END_SOC])
SELECT i.calId,i.license_number, Badge, operator_name,i.drive_id,
       i.[block_abbr],SUM(k.kWhUsed) kWhUsed, SUM(e.HighAcceleration) HighAcceleration, SUM(e.HighBraking) HighBraking,
       MAX(i.BEGIN_SOC) BEGIN_SOC,
       MAX(i.END_SOC) END_SOC 
FROM (
SELECT license_number, Badge, operator_name,drive_id,
       [block_abbr],calId,
	   [1] AS BEGIN_SOC,
	   [2] AS END_SOC
	  -- select * 
	  FROM #pivotReady pr
PIVOT
(MAX(SOC) 
FOR rnu IN ([1],[2])) pvt 
) i
LEFT OUTER JOIN #prePivotkWh k ON k.drive_id = i.drive_id
LEFT OUTER JOIN #prePivotEvents e ON e.drive_id = i.drive_id
GROUP BY 
i.calId,i.license_number,badge, operator_name,i.drive_id,i.[block_abbr]


DROP TABLE IF EXISTS #pivotReady
DROP TABLE IF EXISTS #tminfo
DROP TABLE IF EXISTS #prePivotSOC
DROP TABLE IF EXISTS #prePivotEvents
DROP TABLE IF EXISTS #prePivotkWh

select @i = @i + 1

if @i > @r
BREAK
   ELSE CONTINUE

END


DROP TABLE IF EXISTS #tminfo
DROP TABLE IF EXISTS #pivotReady
DROP TABLE IF EXISTS #prePivotSOC
DROP TABLE IF EXISTS #prePivotEvents
DROP TABLE IF EXISTS #prePivotkWh
drop table if exists #dat



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
