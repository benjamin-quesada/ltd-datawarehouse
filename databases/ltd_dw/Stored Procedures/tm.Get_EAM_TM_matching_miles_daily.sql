SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   PROCEDURE [tm].[Get_EAM_TM_matching_miles_daily]
AS

/**********************

CREATED ON:		20220311
CREATED BY:		Eichberger
PURPOSE   :		Process Staged TM and EAM Mileage so it can be consumed by EAM Mileage and Fueling Reports

CHANGED ON:		20230626
CHANGED BY:		Eichberger
PURPOSE   :		Reduce number of days processed and remove temp tables to instantiated tables

EXAMPLE	  :		exec tm.[Get_EAM_TM_matching_miles_daily] 

**********************/


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
DROP TABLE IF EXISTS wrk.eam_tm_lastLifeMeter
SELECT Q.EQ_equip_no
	  ,Q.meter_1_reading
	  ,Q.datetime_in_service
	  ,Q.RN 
INTO -- select * from 
wrk.eam_tm_lastLifeMeter
FROM  (
SELECT EQ_equip_no
	  ,meter_1_reading
	  ,datetime_in_service
	  ,RN = ROW_NUMBER() OVER (PARTITION BY EQ_equip_no ORDER BY datetime_in_service DESC)
	  FROM [ltd-eam].proto.emsdba.JOB_main
	  WHERE datetime_in_service >= GETDATE()-90 
	  AND ISNUMERIC(EQ_equip_no) = 1 )
		Q 
WHERE rn IN (1,2)

DROP TABLE IF EXISTS wrk.eam_tm_wo_Meter
SELECT EQ_equip_no
	,DATEDIFF(DAY,last_datetime_in_service , recent_datetime_in_service ) days_diff
	,last_meter_1 - last_meter_2 miles_diff
	,cast(CASE
		WHEN DATEDIFF(DAY,last_datetime_in_service , recent_datetime_in_service ) <> 0
		THEN (last_meter_1 - last_meter_2) / DATEDIFF(DAY,last_datetime_in_service , recent_datetime_in_service ) 
		ELSE 0 END AS iNT ) avg_miles_per_day
	INTO -- SELECT * FROM 
	wrk.eam_tm_wo_Meter
	  FROM (
SELECT d.EQ_equip_no
	  ,d.recent_datetime_in_service
	  ,ISNULL(d.last_datetime_in_service,getdate()+1) last_datetime_in_service
	  ,d.last_meter_1
	  ,CASE WHEN d.last_meter_2 = 85.5 THEN d.last_meter_1 ELSE d.last_meter_2 END last_meter_2
	  FROM (
	SELECT EQ_equip_no
		,MAX(CASE WHEN rn = 1 THEN datetime_in_service ELSE NULL END) recent_datetime_in_service
		,MAX(CASE WHEN rn = 2 THEN datetime_in_service ELSE NULL END) last_datetime_in_service
		,MAX(CASE WHEN rn = 1 THEN meter_1_reading END) last_meter_1
		,MAX(CASE WHEN rn = 2 THEN meter_1_reading ELSE 85.5 END) last_meter_2
		FROM  wrk.eam_tm_lastLifeMeter
		GROUP by EQ_equip_no
		) 	d 
	) o 




DROP TABLE IF EXISTS wrk.eam_tm_stagedFuelData;
SELECT f.EQ_equip_no
	  ,f.ftk_date
	  ,f.ftk_cal_id
	  ,f.qty_fuel
	  ,f.fuel_miles 
INTO -- select * from 
wrk.eam_tm_stagedFuelData
FROM (
SELECT eq_equip_no,
       ftk_date,ftk_cal_id,
	   qty_fuel,
	   fuel_miles = [meter_1]
FROM
(
    SELECT eq_equip_no,
           ftk_date,
           CAST(CONVERT(VARCHAR(32),ftk_date,112) AS INT) + 100000000 ftk_cal_id,
		   qty_fuel,
		   [meter_1]
		   ,rn = ROW_NUMBER() OVER (PARTITION BY eq_equip_no ORDER BY ftk_date DESC)
    FROM [ltd-eam].proto.emsdba.ftk_main
    WHERE fuel_type = 'uls' AND ftk_date >= DATEADD(DAY,-90,GETDATE()) --AND EQ_equip_no = '1101'
) i
WHERE rn = 1
) f


DROP TABLE IF EXISTS wrk.eam_tm_prepbus
CREATE TABLE wrk.eam_tm_prepbus ([rn] [INT] IDENTITY(1,1) NOT NULL,
	[calendar_id] [INT] NOT NULL,
	[bus] [VARCHAR](9) NULL,
	[tm_miles] [NUMERIC](9, 2) NULL,
	[eam_miles] [NUMERIC](9, 2) NULL,
	[last_block] [VARCHAR](5) NULL,
	[miles_total_est] [NUMERIC](9, 2) NULL,
	[pull_in] [CHAR](5) NULL,
	[at_ltd] [SMALLINT] NULL,
	[life_total_meter_1] [NUMERIC](9, 2) NULL,
	[last_fuel_date] datetime NULL,
	[last_fuel_qty] [NUMERIC](9, 2) NULL)

INSERT -- select * from 
wrk.eam_tm_prepbus (
 s.[calendar_id]
,s.[bus]
,s.[tm_miles]
,s.[eam_miles]
,s.[last_block]
,s.[miles_total_est]
,s.[pull_in]
,s.[at_ltd]
,[life_total_meter_1]
,last_fuel_date
,last_fuel_qty)
SELECT c.calendar_id
,c.bus
,c.tm_miles
,isnull(c.eam_miles,c.miles_total_est) eam_miles
,c.last_block
,c.miles_total_est
,c.pull_in
,c.at_ltd
,c.meter_1_reading
,c.last_fuel_date
,c.last_fuel_qty -- select * 
FROM (
	SELECT s.calendar_id
		  ,s.bus
		  ,s.tm_miles
		  ,s.eam_miles eam_miles
		  ,s.last_block
		  ,ISNULL(s.miles_total_est,l.avg_miles_per_day) miles_total_est
		  ,s.pull_in
		  ,s.at_ltd
		  ,l.avg_miles_per_day
		  ,t.meter_1_reading
		  ,f.ftk_date last_fuel_date
		  ,f.qty_fuel last_fuel_qty,
		rowNbr = ROW_NUMBER() OVER (PARTITION BY s.calendar_id,s.bus ORDER BY s.rn DESC)
		FROM -- select * from 
		[tm].[bus_miles_active_daily_staging] s 
		LEFT JOIN -- select * from 
		wrk.eam_tm_wo_Meter l ON l.EQ_equip_no COLLATE SQL_Latin1_General_CP1_CI_AS = s.bus COLLATE SQL_Latin1_General_CP1_CI_AS 
		LEFT JOIN -- select * from 
		wrk.eam_tm_lastLifeMeter t ON t.EQ_equip_no COLLATE SQL_Latin1_General_CP1_CI_AS = s.bus COLLATE SQL_Latin1_General_CP1_CI_AS 
		LEFT JOIN wrk.eam_tm_stagedFuelData f ON f.EQ_equip_no COLLATE SQL_Latin1_General_CP1_CI_AS = s.bus COLLATE SQL_Latin1_General_CP1_CI_AS -- AND f.ftk_cal_id = s.calendar_id
		WHERE s.last_block IS NOT NULL 
		AND s.calendar_id >= CAST(CONVERT(VARCHAR(32), DATEADD(DAY,-5,GETDATE()),112) AS INT) + 100000000
		--AND s.bus = '1101'
	) c
WHERE c.rowNbr = 1 
GROUP BY 
c.calendar_id
,c.bus
,c.tm_miles
,c.eam_miles
,c.last_block
,c.miles_total_est
,c.pull_in
,c.at_ltd
,c.meter_1_reading
,c.last_fuel_date
,c.last_fuel_qty
,c.rowNbr



DROP TABLE IF EXISTS wrk.eam_tm_stagedMiles
SELECT [calendar_id]
      ,[bus]
      ,[tm_miles] = ISNULL([tm_miles],0)
      ,[eam_miles] = ISNULL([eam_miles],0)
      ,[last_block] = ISNULL([last_block],0)
      ,[miles_total_est] = ISNULL([miles_total_est],0)
      ,[pull_in] = ISNULL([pull_in],'00:00')
      ,[at_ltd] = ISNULL([at_ltd],0) 
	  ,[life_total_meter_1] = ISNULL([life_total_meter_1],0)
	  ,[last_fuel_date] = ISNULL([last_fuel_date],0)
	  ,last_fuel_qty = ISNULL(last_fuel_qty,0)
INTO -- select * from 
wrk.eam_tm_stagedMiles 
FROM (
SELECT i.[calendar_id]
      ,i.[bus]
      ,i.[tm_miles]
      ,i.[eam_miles]
      ,i.[last_block]
      ,i.[miles_total_est]
      ,i.[pull_in]
      ,i.[at_ltd] 
	  ,i.[life_total_meter_1]
	  ,i.[last_fuel_date]
	  ,i.last_fuel_qty
FROM wrk.eam_tm_prepbus i 
) m
GROUP BY [calendar_id]
      ,[bus]
      ,[tm_miles]
      ,[eam_miles]
      ,[last_block]
      ,[miles_total_est]
      ,[pull_in]
      ,[at_ltd] 
	  ,[life_total_meter_1]
	  ,[last_fuel_date]
	  ,last_fuel_qty


INSERT -- truncate table -- select * from 
[eam].[eam_tm_matching_miles_daily]
	([calendar_id]
      ,[bus]
      ,[tm_miles]
      ,[eam_miles]
      ,[last_block]
      ,[miles_total_est]
      ,[pull_in]
      ,[at_ltd]
	  ,[life_total_meter_1]
	  ,[last_fuel_date]
	  ,[last_fuel_qty]
)
SELECT w.calendar_id,
	   w.bus,
	   w.tm_miles,
       CAST(w.eam_miles as INT) eam_miles,
       w.last_block,
       CAST(w.miles_total_est as INT) miles_total_est,
       w.pull_in,
       w.at_ltd,
       w.life_total_meter_1,
       w.last_fuel_date,
       w.last_fuel_qty FROM (
SELECT s.[calendar_id]
      ,s.[bus]
      ,MAX(s.[tm_miles]) [tm_miles]
      ,MAX(s.[eam_miles]) [eam_miles]
      ,MAX(s.[last_block]) [last_block]
      ,MAX(s.[miles_total_est]) [miles_total_est]
      ,s.[pull_in]
      ,s.[at_ltd]
	  ,s.[life_total_meter_1]
	  ,s.[last_fuel_date]
	  ,s.[last_fuel_qty]
	  ,e.calendar_id eCal
	  ,e.bus eBus
FROM wrk.eam_tm_stagedMiles s
LEFT OUTER JOIN (SELECT * FROM [eam].[eam_tm_matching_miles_daily] WITH (NOLOCK)) e
				ON e.bus = s.bus 
					AND e.calendar_id = s.calendar_id 
					AND ISNULL(e.tm_miles,0) = ISNULL(s.tm_miles,0)
GROUP BY 
s.[calendar_id]
      ,s.[bus]
      ,s.[pull_in]
      ,s.[at_ltd]
	  ,s.[life_total_meter_1]
	  ,s.[last_fuel_date]
	  ,s.[last_fuel_qty]
	  ,e.calendar_id 
	  ,e.bus 
		
 ) w
WHERE eCal IS null

--DELETE FROM [eam].[eam_tm_matching_miles_daily] where calendar_id <= CAST(CONVERT(VARCHAR(32),DATEADD(DAY,-5,GETDATE()),112) AS INT) + 100000000

--SELECT * FROM [eam].[eam_tm_matching_miles_daily] order by calendar_id desc

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
