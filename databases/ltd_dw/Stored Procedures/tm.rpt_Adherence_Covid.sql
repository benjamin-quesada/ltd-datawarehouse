SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [tm].[rpt_Adherence_Covid]

@startdate date = '3/29/2020',  @enddate date = '6/20/2020'

as
--/*
--subselect columns only needed for adherence tests or COVID schedule adjustments
--written into sproc to take advantage of SQL processor and remove some of the work
--from MS Excel layer.
--
-- collects data from transitMaster sources to be used in evaluating a period
-- of time of covid19 pandemic operations

-- CREATED BY:  B. Eichberger
-- CREATED DT:  7/7/2020
-- Principal:   J. Card (uses for excel reporting to analyze activity and ridership
--                       during COVID19 Period). 

--example: exec tm.rpt_Adherence_Covid '3/29/2020', '06/20/2020'


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

if @enddate is null
BEGIN
select @enddate = cast(getdate() as date)
END

declare
@startdt bigint = 100000000+cast(convert(VARCHAR(12), @startdate, 112) as INT)
,  @enddt bigint = 100000000+cast(convert(VARCHAR(12), @enddate, 112) as INT)

SELECT calendar_id
		,max(service_type_id) service_type_id
	into #ss_adh
	FROM [ltd-tmdata].tmmain.dbo.service_selection WITH (NOLOCK)
	WHERE 1=1
	AND calendar_id BETWEEN @startdt and @enddt
	GROUP BY calendar_id

create index tmp_idx_ss_adh on #ss_adh (calendar_id) 

	
select a.scheduled_time
	,the_date = sc.calendar_date
	,a.actual_arrival_time
	,a.adherence
	,a.actual_departure_time
	,a.late_waived_tp
	,a.early_waived_tp
	,a.missing_waived_tp
	,a.adjusted_missing_count
	,a.adjusted_ontime_count
	,a.adjusted_late_count
	,a.adjusted_early_count
	,a.calendar_id
	,a.time_point_id
	,a.block_id
	,a.route_direction_id
	,a.route_id
	,a.trip_id
	,a.time_table_version_id
	,[arrive] = tm.convert_spm_to_hh_mm_ss(a.actual_arrival_time)
	,[depart] = tm.convert_spm_to_hh_mm_ss(a.actual_departure_time)
	,[sched] = tm.convert_passing_time(a.scheduled_time)
	,trip_end = tm.convert_passing_time(t.trip_end_time) 
	,tst.trip_start_time
	,tst.trip_end_time
	into #tmpAdh from [ltd-tmdata].tmdatamart.dbo.adherence a WITH (NOLOCK)
	INNER JOIN [ltd-tmdata].tmmain.dbo.service_calendar sc WITH (NOLOCK) ON sc.calendar_id = a.calendar_id
	INNER JOIN [ltd-tmdata].tmmain.dbo.trip t WITH (NOLOCK) on t.trip_id = a.trip_id
	LEFT JOIN [ltd-tmdata].ltd_db.dbo.trips_scheduled_times tst WITH (NOLOCK) ON tst.trip_id = t.trip_id
	where sc.calendar_id between @startdt and @enddt
	
CREATE NONCLUSTERED INDEX [[idx_TmpAdh_time_table_version_includes]
ON #tmpAdh ([calendar_id],[trip_end_time])
INCLUDE ([scheduled_time],[the_date],[actual_arrival_time],[adherence],[actual_departure_time],[late_waived_tp],[early_waived_tp],[missing_waived_tp],[adjusted_missing_count],[adjusted_ontime_count],[adjusted_late_count],[adjusted_early_count],[time_point_id],[block_id],[route_direction_id],[route_id],[time_table_version_id],[arrive],[depart],[sched],[trip_end],[trip_start_time])


select *, left(route_direction_name, 1) linkRD 
into #rd
	from [ltd-tmdata].tmmain.dbo.route_direction WITH (NOLOCK)

select block_id, [block_abbr] into #b 
	from [ltd-tmdata].tmmain.dbo.[block] WITH (NOLOCK)

select time_point_id,time_point_abbr,time_pt_name into #tp
	from [ltd-tmdata].tmmain.dbo.time_point WITH (NOLOCK)

select service_type_id, [svc] = CASE WHEN service_type_text LIKE '%w%' THEN 'wkd' ELSE left(service_type_text, 3) END
	into #st
	from [ltd-tmdata].tmmain.dbo.service_type WITH (NOLOCK)

select route_id,route_abbr into #rte 
	from [ltd-tmdata].tmmain.dbo.[route] WITH (NOLOCK)

select * into #ttv
	from [ltd-tmdata].tmmain.dbo.time_table_version WITH (NOLOCK)

select * into #stps from [ltd-tmdata].ltd_db.dbo.ltd_significant_tps_from_tmmain WITH (NOLOCK) 
 
;
WITH incidentsW
AS (
	SELECT the_date
		,the_time
		,blk
		,[type]
		,the_time_spm 
	FROM [ltd-tmdata].ltd_db.dbo.ltd_incidents_from_tmmain WITH (NOLOCK)
	WHERE the_date BETWEEN @startdate AND @enddate
		AND [type] = 'white line'
	)
,incidentsD
AS (
	SELECT the_date
		,the_time
		,blk
		,[type]
		,the_time_spm
	FROM [ltd-tmdata].ltd_db.dbo.ltd_incidents_from_tmmain WITH (NOLOCK)
	WHERE the_date BETWEEN @startdate AND cast(@enddate AS DATE)
		AND [type] = 'Drop-Off Only'
	)


SELECT a.[the_date] 
	,[block] = b.block_abbr
	,a.trip_end
	,a.sched
	,a.arrive
	,a.depart
	,[adhere_min] = cast(round(CASE 
				WHEN a.scheduled_time = a.trip_end_time
					THEN a.scheduled_time - a.actual_arrival_time
				ELSE a.adherence
				END / 60.0, 2) AS NUMERIC(9, 2))
	,[dwell_min] = cast(round((a.actual_departure_time - a.actual_arrival_time) / 60.0, 2) AS NUMERIC(9, 2))
	,[adherence] = a.adherence
	,[rte] = rte.route_abbr
	,[rte_dir] = left(rd.route_direction_name, 1)
	,st.[svc]
	,[tp] = tp.time_point_abbr
	,[tp_name] = tp.time_pt_name
    ,[late_waived_tp] = a.late_waived_tp
    ,[early_waived_tp] = a.early_waived_tp
    ,[missing_waived_tp] = a.missing_waived_tp
	,[ltd_status] = case when a.adjusted_missing_count = 1 then 'missing'
                         when a.adjusted_ontime_count  = 1 then 'ontime'
                         when a.adjusted_late_count    = 1 then 'late'
                         when a.adjusted_early_count   = 1 then 'early'
                             else '???????' end
	,datename(dw, a.the_date) day_of_week
	,[sa_tp] = CASE WHEN stps.[route] IS NULL THEN 0 ELSE 1 END
	,[white_line] = CASE WHEN wl.the_date IS NULL THEN 'n' ELSE 'y' END
	,[drop_off_only] = CASE WHEN doo.the_date IS NULL THEN 'n' ELSE 'y' END
into #AdhSetup
FROM #tmpAdh a WITH (NOLOCK)
INNER JOIN #ttv ttv WITH (NOLOCK)
		 ON ttv.time_table_version_id = a.time_table_version_id
INNER JOIN #b b WITH (NOLOCK) ON b.block_id = a.block_id
INNER JOIN #tp tp WITH (NOLOCK) ON tp.time_point_id = a.time_point_id
INNER JOIN #ss_adh ss ON ss.calendar_id = a.calendar_id
INNER JOIN #st st WITH (NOLOCK) ON st.service_type_id = ss.service_type_id
LEFT JOIN #rte rte WITH (NOLOCK) ON rte.route_id = a.route_id
LEFT JOIN #rd rd ON rd.route_direction_id = a.route_direction_id
LEFT JOIN #stps stps ON stps.[route] = rte.route_abbr
	AND stps.direction = rd.linkRD
	AND stps.tp = tp.time_point_abbr
LEFT JOIN incidentsW wl ON wl.the_date = a.the_date
	AND wl.blk = b.block_abbr
	AND a.scheduled_time >= wl.the_time_spm
	AND wl.the_time_spm BETWEEN a.trip_start_time AND a.trip_end_time
LEFT JOIN incidentsD doo ON doo.the_date = a.the_date
	AND doo.blk = b.block_abbr
	AND a.scheduled_time >= doo.the_time_spm
	AND doo.the_time_spm BETWEEN a.trip_start_time AND a.trip_end_time
WHERE NOT (ttv.time_table_version_name = '1009b' AND rte.route_abbr LIKE '10[2-3]')
	AND rte.route_abbr <> '25'
	AND a.trip_end_time is not null


select r.*
,case when time_dec < 6 THEN 'AM'  
	WHEN time_dec >= 6 AND time_dec < 10 THEN 'AM Peak'  
	WHEN time_dec >= 10 AND time_dec < 13 THEN 'Mid-Morning'  
	WHEN time_dec >= 13 AND time_dec < 17 THEN 'PM Peak'
	WHEN time_dec >= 17 THEN 'PM' end as peak_period
,FORMAT(cast(cast([the_date] as varchar(12)) +' '+ cast(trip_end as varchar(12)) as datetime), 'M/d') as grp_date
--,cast(datepart(month,the_date) as varchar(3))+'/'+cast(datepart(day,the_date) as varchar(3)) as grp_date_forced
into #adherence
FROM (
select o.*
,time_dec = cast(cast(left(depart,2) as INT) + 
		cast(substring(depart,4,2) as float)/60 +
		cast(right(depart,2) as float)/3600	
			as decimal(6,3))
	from #AdhSetup o
WHERE depart is not null
) r

select [the_date] 
	,[block] 
	,trip_end
	,sched
	,arrive
	,depart
	,[adhere_min] 
	,[dwell_min] 
	,[adherence] 
	,[rte] 
	,[rte_dir]
	,[svc] 
	,[tp] 
	,[tp_name] 
    ,[late_waived_tp] 
    ,[early_waived_tp] 
    ,[missing_waived_tp] 
	,[ltd_status]
	,[day_of_week]
	,[sa_tp]
	,[white_line] 
	,[drop_off_only]
	,time_dec
	,peak_period from #adherence
GO
