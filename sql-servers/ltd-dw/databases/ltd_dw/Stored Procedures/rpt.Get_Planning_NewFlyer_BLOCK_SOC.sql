SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   PROCEDURE [rpt].[Get_Planning_NewFlyer_BLOCK_SOC]

AS

/*
CREATE BY:	bee
CREATE ON:  5/9/2022
PURPOSE	 :  To indicate the SOC a bus starts a block with and then what SOC it ends a block with.

exec [rpt].[Get_Planning_NewFlyer_BLOCK_SOC]

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


SELECT calendar_id, v.PROPERTY_TAG
INTO -- select distinct property_tag from 
#vehList
FROM [ltd-tmdata].tmdatamart.dbo.ADHERENCE a
JOIN ltd_dw.model.Vehicle_v v 
			 ON v.vehicle_id = a.VEHICLE_ID
WHERE CALENDAR_ID >= 120210501 AND v.bus_kind = 'Electric'
		GROUP BY calendar_id, v.PROPERTY_TAG


create TABLE #lastDatePP (rn INT IDENTITY(1,1), calId INT NOT NULL, calDt DATE NOT NULL,license_number int)
insert #lastDatePP (calId, calDt, license_number)
SELECT c.CALENDAR_ID calId, c.CALENDAR_DATE AS calDt, h.PROPERTY_TAG FROM tm.DW_CALENDAR c 
JOIN #vehList h ON h.CALENDAR_ID = c.CALENDAR_ID 
LEFT JOIN rpt.Planning_NewFlyer_BLOCK_SOC i ON i.calId = c.CALENDAR_ID AND i.license_number = h.PROPERTY_TAG
WHERE c.calendar_id >= 120210501 AND c.CALENDAR_DATE < CAST(GETDATE() AS DATE) AND i.calId IS null 
ORDER BY calid 

--select * from #lastDatePP order by calid
  declare @i int 
  declare @r int
  declare @currdt int
  select @i = 1
  select @r = (select max(rn) from #lastDatePP)

while @i <= @r
BEGIN


DECLARE @licId INT = (SELECT license_number FROM #lastDatePP WHERE rn = @i)
declare @calId INT = (SELECT calId FROM #lastDatePP WHERE rn = @i)

DROP TABLE IF EXISTS #tminfo

SELECT i.cal_msgspm_key,
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
	   CAST(i.calendar_id AS VARCHAR(32)) + RIGHT('000000' + CAST(p.ACTUAL_PULLOUT_TIME AS VARCHAR(32)),6) pullout_cal_spm,
	   CAST(i.calendar_id AS VARCHAR(32)) + RIGHT('000000' + CAST(p.ACTUAL_PULLIN_TIME AS VARCHAR(32)),6) pullin_cal_spm
INTO #tminfo
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
AND vh.bus_kind = 'Electric'
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
DROP TABLE IF EXISTS #prePivot

SELECT p.license_number,calid,[date And Time],[NF XPAND_SYS_SOC (PGN: 65349)] AS SOC,
			t.drive_id,t.vehicle_id ,
			CAST(calid AS VARCHAR(32)) + RIGHT('000000' + CAST([dbo].[F_DATE_TO_SEC_SINCE_MIDNITE]([date And Time]) AS varchar(32)),6) cal_spm_key
INTO #prePivot
FROM ltd_electric_bus.fact.newflyer_parameters_pivot p WITH (NOLOCK)
JOIN ltd_electric_bus.[dbo].[newflyer_trips] t ON t.license_number = p.license_number
			AND CAST(p.[Date And Time] AS DATETIME) BETWEEN t.[start_time_local] AND t.[end_time_local] 
			--JOIN ltd_electric_bus.dbo.newflyer_drive_store v WITH (NOLOCK) ON v.license_number = p.license_number
			--		AND CAST(p.[Date And Time] AS DATETIME) between CAST(v.start_time AS DATETIME) AND CAST(v.end_time AS DATETIME)
--LEFT JOIN model.Vehicle_v e ON e.PROPERTY_TAG = v.license_number
			WHERE 1=1
			AND p.calId = @calid 
			AND p.license_number = @licId
			AND ISNULL([NF XPAND_SYS_SOC (PGN: 65349)],0) > 0
ORDER BY calid desc

DROP TABLE IF EXISTS #pivotReady
SELECT u.license_number,badge,u.operator_name,
    u.drive_id,
	u.calid,
	u.[Date and Time],
    u.BLOCK_ABBR,
	u.SOC,
	rnu = ROW_NUMBER() OVER (PARTITION BY u.license_number,u.BLOCK_ABBR ORDER BY u.[Date and Time])
INTO #pivotReady
FROM (
SELECT pp.license_number,pp.cal_spm_key,tm.BADGE,
		COALESCE(tm.Last_Name,'') + ', ' +RTRIM(COALESCE(tm.First_Name + ' ','')) +
				CASE WHEN tm.MIDDLE_NAME IS NOT NULL THEN ' '+COALESCE(tm.Middle_Name,'') ELSE COALESCE(tm.Middle_Name,'') end AS operator_name ,
       pp.drive_id,
       pp.vehicle_id,
	   pp.[Date and Time],
	   pp.calid,
	   pp.SOC,
       tm.BLOCK_ABBR,
	   rnBegin = ROW_NUMBER() OVER (PARTITION BY pp.license_number,tm.BLOCK_ABBR, tm.badge ORDER BY cal_spm_key ASC),
	   rnEnd = ROW_NUMBER() OVER (PARTITION BY pp.license_number,tm.BLOCK_ABBR, tm.badge ORDER BY cal_spm_key DESC)
	FROM #prePivot pp
	JOIN #tminfo tm ON tm.veh = pp.license_number
AND pp.cal_spm_key BETWEEN tm.pullout_cal_spm AND tm.pullin_cal_spm
GROUP BY 
pp.license_number,pp.cal_spm_key,tm.BADGE,
		COALESCE(tm.Last_Name,'') + ', ' +RTRIM(COALESCE(tm.First_Name + ' ','')) +
				CASE WHEN tm.MIDDLE_NAME IS NOT NULL THEN ' '+COALESCE(tm.Middle_Name,'') ELSE COALESCE(tm.Middle_Name,'') end  ,
       pp.drive_id,
       pp.vehicle_id,
	   pp.[Date and Time],
	   pp.calid,
	   pp.SOC,
       tm.BLOCK_ABBR
) u
WHERE u.rnBegin = 1 OR u.rnEnd = 1;

DELETE FROM rpt.Planning_NewFlyer_BLOCK_SOC WHERE calid = @calid AND license_number = @licId

INSERT rpt.Planning_NewFlyer_BLOCK_SOC ( 
	[calId]
    ,[license_number]
    ,[badge]
    ,[operator_name]
    ,[block_abbr]
    ,[BEGIN_SOC]
    ,[END_SOC])
SELECT calId,i.license_number,badge, operator_name,
       i.[block_abbr],
       MAX(i.BEGIN_SOC) BEGIN_SOC,
       MAX(i.END_SOC) END_SOC 
FROM (
SELECT license_number,badge, operator_name,
       [block_abbr],calId,
	   [1] AS BEGIN_SOC,
	   [2] AS END_SOC
	   FROM #pivotReady pr
PIVOT
(MAX(SOC) 
FOR rnu IN ([1],[2])) pvt 
) i
GROUP BY 
calId,i.license_number,badge, operator_name,
       i.[block_abbr]


select @i = @i + 1

if @i > @r
BREAK
   ELSE CONTINUE

END

DROP TABLE IF EXISTS #pivotReady
DROP TABLE IF EXISTS #tminfo
DROP TABLE IF EXISTS #prePivot



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
