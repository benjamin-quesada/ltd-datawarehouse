SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE   PROCEDURE [tm].[Get_Adherence_metrics_drop_20241231]
as
-- exec tm.GET_ADHERENCE_METRICS


/*
  CREATED: 20201026
   AUTHOR: B EICHBERGER
  PURPOSE: Collect Expanded Daily Adherence data for longitudinal record in DW - WIP and to support Operations Monthly Reporting
CHANGEDON: 
 CHANGEBY: 
   CHANGE: 

*/



IF OBJECT_ID('tempdb.dbo.##sched_sel', 'U') IS NOT NULL
  DROP TABLE dbo.##sched_sel
IF OBJECT_ID('tempdb.dbo.##dtloopsADH', 'U') IS NOT NULL
  DROP TABLE dbo.##dtloopsADH
IF OBJECT_ID('tempdb.dbo.##rawADHERENCE_METRICS', 'U') IS NOT NULL
  DROP TABLE dbo.##rawADHERENCE_METRICS



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

DECLARE @OutputTbl TABLE (ActionName varchar(32))
declare @workstartdate datetime = sysdatetime()

update [process].[MergeLogs] 
set [MergeEndDatetime] = @workstartdate
   where mergecode = 'ADH'
     and [ObjectDestination] = 'LTD_DW.tm.ADHERENCE_METRICS'
	 AND [ObjectSource] = 'TM'
	 AND [ObjectProgram] = 'LTD_DW.tm.GET_ADHERENCE_METRICS'
	 AND [MergeEndDatetime] is null
	 AND recInsert = 0
	 AND recUpdate = 0
	 AND recDelete = 0


declare @startdt INT =  --120180101
(select isnull(min(calid), 120180101) from 
							(select isnull(max(calendar_id),120180701) calid from ltd_dw.[tm].[ADHERENCE_METRICS] WITH (NOLOCK) 
							 UNION
							 select isnull(max(cast(convert(varchar(32),record_updated_date,112) as INT)+100000000),100000000+convert(varchar(32),getdate()-1,112)) calid from ltd_dw.[tm].[ADHERENCE_METRICS] WITH (NOLOCK) 
							 UNION
							 select isnull(max(cast(convert(varchar(32),record_created_date,112) as INT)+100000000),100000000+convert(varchar(32),getdate()-1,112)) calid from ltd_dw.[tm].[ADHERENCE_METRICS] WITH (NOLOCK) 
							 ) o 
							 where calid <> 0 
						)
declare @enddINT INT = (select 100000000+convert(varchar(32),getdate()-1,112)) -- 120200331 -- 

--(select calendar_id, max(service_type_id) service_type_id from tmmain.dbo.service_selection group by calendar_id) ss on ss.calendar_id = sc.calendar_id
 
select distinct s.calendar_id ,max(service_type_id) service_type_id ,  d.calendar_date the_date
	into ##sched_sel 
	from tm.dw_calendar d
	JOIN [LTD-TMDATA].tmmain.dbo.service_selection s WITH (NOLOCK) 
	on s.calendar_id = d.calendar_id
where d.calendar_id >= @startdt
  and d.calendar_id <= @enddINT
			group by s.calendar_id, d.calendar_date 


declare @startdate DATE = (select min(the_date) from ##sched_sel)
declare @enddate DATE = (select max(the_date) from ##sched_sel)


DECLARE @INTERVAL   INT = 10;
-- a method to break the work into bite sized chunks
-- set up a series of dates in needed size of days
-- to loop through
-- -->
;WITH T(N) AS (SELECT N FROM (VALUES (0),(0),(0),(0),(0),(0),(0),(0),(0),(0)) AS X(N))
,  NUMS(N) AS (SELECT TOP((DATEDIFF(DAY,@startdate,@enddate) / @INTERVAL ) +1) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 AS N
               FROM T T1,T T2,T T3,T T4)

SELECT
    NM.N rnbr
   ,DATEADD(DAY,(NM.N * @INTERVAL),@startdate) AS OUT_DATE_FM
   ,DATEADD(DAY, 9,DATEADD(DAY,(NM.N * @INTERVAL),@startdate) ) AS OUT_DATE_TO
into ##dtloopsADH
FROM NUMS   NM ;

alter table ##dtloopsADH add out_int_fm as (cast(convert(varchar(22),out_date_fm, 112) as BIGINT)+100000000)
alter table ##dtloopsADH add out_int_to as (cast(convert(varchar(22),out_date_to, 112) as BIGINT)+100000000)

--select * from ##dtloopsADH order by out_date_FM

declare @loopstartdt datetime = sysdatetime()
 --set up and loop
declare @i BIGINT = 0
declare @r BIGINT = (select max(rnbr) from ##dtloopsADH)
declare @loopNbr INT

declare @loopStart INT
declare @loopEnd INT



if (select isnull(count(*),0) from ##dtloopsADH) > 0
BEGIN

WHILE @i <= @r

BEGIN


select @loopStart = (select out_int_fm from ##dtloopsADH where rnbr = @i) 
select @loopEnd = (select out_int_to from ##dtloopsADH where rnbr = @i) 

create table ##rawADHERENCE_METRICS(
	[adherence_id] [int] NOT NULL,
	[calendar_id] [numeric](10, 0) NOT NULL,
	[the_date] [datetime] NOT NULL,
	[day_type] [varchar](7) NOT NULL,
	[ttv_id] [numeric](5, 0) NOT NULL,
	[ttv] [varchar](30) NOT NULL,
	[bid] [varchar](4) NULL,
	[block_id] [numeric](10, 0) NULL,
	[block] [varchar](9) NOT NULL,
	[block_numeric] [int] NULL,
	[emx_block] [varchar](1) NOT NULL,
	[taxi_block] [varchar](1) NOT NULL,
	[trip_start] [numeric](10, 0) NULL,
	[trip_end] [char](5) NULL,
	[sched] [char](5) NULL,
	[sched_spm] [numeric](10, 0) NULL,
	[actual_arrival_spm] [int] NULL,
	[actual_departure_spm] [int] NULL,
	[arrive] [char](8) NULL,
	[depart] [char](8) NULL,
	[adhere_sec] [numeric](11, 0) NULL,
	[adhere_min] [numeric](9, 2) NULL,
	[dwell_sec] [int] NULL,
	[dwell_min] [numeric](9, 2) NULL,
	[adherence] [numeric](5, 0) NULL,
	[arrival_adhere_mins] [numeric](6, 2) NULL,
	[end_of_trip] [varchar](1) NOT NULL,
	[trip_end_important_tp] [varchar](1) NOT NULL,
	[trip_end_missed] [int] NULL,
	[trip_end_ontime] [int] NULL,
	[trip_end_late_0_2] [int] NULL,
	[trip_end_late_2_4] [int] NULL,
	[trip_end_late_4_6] [int] NULL,
	[trip_end_late_6_plus] [int] NULL,
	[sched_interval] [varchar](5) NOT NULL,
	[actual_interval] [varchar](5) NOT NULL,
	[trip_id] [numeric](10, 0) NULL,
	[revenue_id] [char](1) NULL,
	[rte] [varchar](8) NULL,
	[rte_dir] [varchar](1) NULL,
	[rte_public] [varchar](8) NULL,
	[rte_and_dir] [varchar](10) NULL,
	[rte_rural] [varchar](9) NULL,
	[rev_rte] [varchar](1) NOT NULL,
	[pattern] [varchar](10) NULL,
	[the_bus] [varchar](20) NULL,
	[odometer] [numeric](9, 2) NOT NULL,
	[sched_miles_since_last] [numeric](9, 2) NOT NULL,
	[bus_class] [varchar](7) NULL,
	[artic] [varchar](1) NULL,
	[emx_bus] [varchar](1) NULL,
	[service_type] [varchar](30) NOT NULL,
	[service_type_general] [varchar](9) NOT NULL,
	[svc] [varchar](3) NULL,
	[run] [varchar](10) NOT NULL,
	[block_stop_order] [int] NOT NULL,
	[pattern_geo_node_seq] [numeric](7, 0) NULL,
	[stop_no] [varchar](8) NOT NULL,
	[stop_name] [varchar](75) NOT NULL,
	[tp] [varchar](8) NULL,
	[tp_name] [varchar](50) NULL,
	[sa_tp] [int] NOT NULL,
	[trip_start_stop] [varchar](8) NULL,
	[trip_start_stop_name] [varchar](75) NULL,
	[trip_end_stop] [varchar](8) NULL,
	[trip_end_stop_name] [varchar](75) NULL,
	[operator_id] [numeric](5, 0) NULL,
	[badge] [varchar](20) NULL,
	[operator_first] [varchar](20) NULL,
	[operator_last] [varchar](20) NULL,
	[operator] [varchar](23) NULL,
	[operators_supervisor] [varchar](25) NULL,
	[operator_jobcode] [varchar](8) NULL,
	[is_layover] [bit] NULL,
	[white_line] [varchar](1) NOT NULL,
	[drop_off_only] [varchar](1) NOT NULL,
	[ltd_status] [varchar](9) NOT NULL,
	[waiver_id] [numeric](5, 0) NULL,
	[waiver_description] [varchar](2000) NULL,
	[waivers_in_one] [varchar](3) NOT NULL,
	[waiver_late_ok] [numeric](1, 0) NULL,
	[waiver_early_ok] [numeric](1, 0) NULL,
	[waiver_missed_ok] [numeric](1, 0) NULL,
	[late_waived_tp] [numeric](5, 0) NULL,
	[early_waived_tp] [numeric](5, 0) NULL,
	[missing_waived_tp] [numeric](5, 0) NULL,
	[late_count] [numeric](7, 0) NULL,
	[early_count] [numeric](7, 0) NULL,
	[ontime_count] [numeric](7, 0) NULL,
	[missing_count] [numeric](7, 0) NULL,
	[adjusted_late] [numeric](5, 0) NULL,
	[adjusted_early] [numeric](5, 0) NULL,
	[adjusted_ontime] [numeric](5, 0) NULL,
	[adjusted_missing] [numeric](5, 0) NULL,
	[layover_late_allowed] [numeric](5, 0) NULL,
	[layover_early_allowed] [numeric](5, 0) NULL,
	[spm_planner] [varchar](3) NOT NULL,
	[bsi] [tinyint] NULL,
	[overload_id] [int] NULL,
	[fom] [int] NULL,
	[valid_odometer] [int] NOT NULL,
	[valid_adherence] [int] NOT NULL,
	[valid_position] [int] NOT NULL)

INSERT -- select * from 
 ##rawADHERENCE_METRICS 
 (	   [adherence_id]
      ,[calendar_id]
      ,[the_date]
      ,[day_type]
      ,[ttv_id]
      ,[ttv]
      ,[bid]
      ,[block_id]
      ,[block]
      ,[block_numeric]
      ,[emx_block]
      ,[taxi_block]
      ,[trip_start]
      ,[trip_end]
      ,[sched]
      ,[sched_spm]
      ,[actual_arrival_spm]
      ,[actual_departure_spm]
      ,[arrive]
      ,[depart]
      ,[adhere_sec]
      ,[adhere_min]
      ,[dwell_sec]
      ,[dwell_min]
      ,[adherence]
      ,[arrival_adhere_mins]
      ,[end_of_trip]
      ,[trip_end_important_tp]
      ,[trip_end_missed]
      ,[trip_end_ontime]
      ,[trip_end_late_0_2]
      ,[trip_end_late_2_4]
      ,[trip_end_late_4_6]
      ,[trip_end_late_6_plus]
      ,[sched_interval]
      ,[actual_interval]
      ,[trip_id]
      ,[revenue_id]
      ,[rte]
      ,[rte_dir]
      ,[rte_public]
      ,[rte_and_dir]
      ,[rte_rural]
      ,[rev_rte]
      ,[pattern]
      ,[the_bus]
      ,[odometer]
      ,[sched_miles_since_last]
      ,[bus_class]
      ,[artic]
      ,[emx_bus]
      ,[service_type]
      ,[service_type_general]
      ,[svc]
      ,[run]
      ,[block_stop_order]
      ,[pattern_geo_node_seq]
      ,[stop_no]
      ,[stop_name]
      ,[tp]
      ,[tp_name]
      ,[sa_tp]
      ,[trip_start_stop]
      ,[trip_start_stop_name]
      ,[trip_end_stop]
      ,[trip_end_stop_name]
      ,[operator_id]
      ,[badge]
      ,[operator_first]
      ,[operator_last]
      ,[operator]
      ,[operators_supervisor]
      ,[operator_jobcode]
      ,[is_layover]
      ,[white_line]
      ,[drop_off_only]
      ,[ltd_status]
      ,[waiver_id]
      ,[waiver_description]
      ,[waivers_in_one]
      ,[waiver_late_ok]
      ,[waiver_early_ok]
      ,[waiver_missed_ok]
      ,[late_waived_tp]
      ,[early_waived_tp]
      ,[missing_waived_tp]
      ,[late_count]
      ,[early_count]
      ,[ontime_count]
      ,[missing_count]
      ,[adjusted_late]
      ,[adjusted_early]
      ,[adjusted_ontime]
      ,[adjusted_missing]
      ,[layover_late_allowed]
      ,[layover_early_allowed]
      ,[spm_planner]
      ,[bsi]
      ,[overload_id]
      ,[fom]
      ,[valid_odometer]
      ,[valid_adherence]
      ,[valid_position]
 )
select distinct 
	   a.adherence_id
	  ,[calendar_id]            = a.calendar_id
      ,[the_date]               = sc.calendar_date
      ,[day_type]               = case when left(datename(dw, sc.calendar_date), 1) = 's' then 'weekend' else 'weekday' end 
      ,[ttv_id]                 = a.time_table_version_id
      ,[ttv]                    = ttv.time_table_version_name
      ,[bid]                    = left(ttv.time_table_version_name, 4)
      ,[block_id]               = a.block_id
      ,[block]                  = b.block_abbr
      ,[block_numeric]          = cast(b.block_abbr as int)
      ,[emx_block]              = case when substring(right('000' + b.block_abbr, 4), 2, 1) = '9' then 'y' else 'n' end     
      ,[taxi_block]             = case when substring(right('000' + b.block_abbr, 4), 2, 1) = '3' then 'y' else 'n' end
      ,[trip_start]             = tst.trip_start_time
      ,[trip_end]               = ltd_dw.tm.convert_passing_time(t.trip_end_time)
      --,[trip_end_sql]           = null  --las 01/07/2018 case when t.trip_end_time > =  (24 * 3600) then null else cast(dbo.convert_passing_time(t.trip_end_time) as time(0)) end
      ,[sched]                  = ltd_dw.tm.convert_passing_time(a.scheduled_time)
      --,[sched_sql]              = null  --las 01/07/2018 case when a.scheduled_time > =  (24 * 3600) then null else cast(dbo.convert_passing_time(a.scheduled_time) as time(0)) end
      ,[sched_spm]              = a.scheduled_time
      ,[actual_arrival_spm]     = a.actual_arrival_time
      ,[actual_departure_spm]   = a.actual_departure_time
      ,[arrive]                 = ltd_dw.tm.convert_spm_to_hh_mm_ss(a.actual_arrival_time)
      --,[arrive_sql]             = null  --las 01/07/2018 case when a.actual_arrival_time > = (24 * 3600) then null else cast(dbo.convert_spm_to_hh_mm_ss(a.actual_arrival_time) as time(0)) end
      ,[depart]                 = ltd_dw.tm.convert_spm_to_hh_mm_ss(a.actual_departure_time)
      --,[depart_sql]             = null  --las 01/07/2018 case when a.actual_departure_time > = (24 * 3600) then null else cast(dbo.convert_spm_to_hh_mm_ss(a.actual_departure_time) as time(0)) end
      ,[adhere_sec]             = case when a.scheduled_time = t.trip_end_time then a.scheduled_time - a.actual_arrival_time else a.adherence end
      ,[adhere_min]             = cast(round(case when a.scheduled_time = t.trip_end_time then a.scheduled_time - a.actual_arrival_time else a.adherence end / 60.0, 2) as numeric(9, 2)) 
      ,[dwell_sec]              = a.actual_departure_time - a.actual_arrival_time
      ,[dwell_min]              = cast(round((a.actual_departure_time - a.actual_arrival_time) / 60.0, 2) as numeric(9, 2))
      ,[adherence]              = a.adherence
      ,[arrival_adhere_mins]    = cast((a.scheduled_time - a.actual_arrival_time) / 60.0 as numeric(6,2))
      ,[end_of_trip]            = case when a.scheduled_time = t.trip_end_time then 'y' else 'n' end
      ,[trip_end_important_tp]  = case when tp.time_point_abbr in('eugsta','wcf','02601','ss_sta','lccsta','uosta','ss_f','ss_g','ss_h','es_s','es_t','xgatoa') then 'y' else 'n' end
      ,[trip_end_missed]        = case when a.scheduled_time <> t.trip_end_time then null when a.actual_arrival_time is null then 1 else 0 end
      ,[trip_end_ontime]        = case when a.scheduled_time <> t.trip_end_time then null when a.scheduled_time - a.actual_arrival_time >= 0 then 1 else 0 end
      ,[trip_end_late_0_2]      = case when a.scheduled_time <> t.trip_end_time then null when a.scheduled_time - a.actual_arrival_time between  -120 and   -1 then 1 else 0 end
      ,[trip_end_late_2_4]      = case when a.scheduled_time <> t.trip_end_time then null when a.scheduled_time - a.actual_arrival_time between  -240 and -121 then 1 else 0 end
      ,[trip_end_late_4_6]      = case when a.scheduled_time <> t.trip_end_time then null when a.scheduled_time - a.actual_arrival_time between  -360 and -241 then 1 else 0 end
      ,[trip_end_late_6_plus]   = case when a.scheduled_time <> t.trip_end_time then null when a.scheduled_time - a.actual_arrival_time between -1800 and -361 then 1 else 0 end
      ,[sched_interval]         = '00:00' -- las 01/07/2018 cast(round((a.scheduled_time      - pa.scheduled_time)        / 60.0, 2) as numeric(9, 2))
      ,[actual_interval]        = '00:00' -- las 01/07/2018 cast(round((a.actual_arrival_time - pa.actual_departure_time) / 60.0, 2) as numeric(9, 2))
      ,[trip_id]                = t.trip_id
      ,[revenue_id]             = a.revenue_id
      ,[rte]                    = rte.route_abbr
      ,[rte_dir]                = left(rd.route_direction_name, 1)
      ,[rte_public]             = case when rte.route_abbr like '10[1-9]' then 'emx' else rte.route_abbr end
      ,[rte_and_dir]            = rte.route_abbr + '-' + left(rd.route_direction_name, 1)
      ,[rte_rural]              = case when rte.route_abbr is null or isnumeric(left(rte.route_abbr, 1)) = 0 then null else case when left(rte.route_abbr, 1) = '9' then 'rural' else 'non-rural' end end 
      ,[rev_rte]                = case when rte.route_abbr is null or isnumeric(left(rte.route_abbr, 1)) = 0 then 'n' else 'y' end 
      ,[pattern]                = p.pattern_abbr
      ,[the_bus]                = v.veh
      ,[odometer]               = isnull(cast(a.odometer / 100.00 as numeric(9,2)),0)
      ,[sched_miles_since_last] = isnull(cast(round(a.sched_dist_from_last_geo_node / 5280.0, 2) as numeric(9, 2)),0)
      ,[bus_class]              = v.bus_class
      ,[artic]                  = v.artic
      ,[emx_bus]                = v.emx_bus
      ,[service_type]           = st.service_type_text 
      ,[service_type_general]   = case when st.service_type_text like '%w%'  then 'weekday'
                                       when st.service_type_text like '%sa%' then 'saturday'
                                       when st.service_type_text like '%su%' then 'sunday'
                                                                             else 'undefined' 
                                  end 
      ,[svc]                    = case when st.service_type_text like '%w%' then 'wkd' else left(st.service_type_text, 3) end
      ,[run]                    = r.run_designator
	  ,[block_stop_order]       = a.block_stop_order
	  ,[pattern_geo_node_seq]   = a.pattern_geo_node_seq
      ,[stop_no]                = gn.geo_node_abbr
      ,[stop_name]              = gn.geo_node_name
      ,[tp]                     = tp.time_point_abbr
      ,[tp_name]                = tp.time_pt_name
      ,[sa_tp]                  = case when stps.[route] is null then 0 else 1 end 
      ,[trip_start_stop]        = tsgn.geo_node_abbr
      ,[trip_start_stop_name]   = tsgn.geo_node_name
      ,[trip_end_stop]          = tegn.geo_node_abbr
      ,[trip_end_stop_name]     = tegn.geo_node_name
      ,[operator_id]            = a.operator_id
      ,[badge]                  = o.badge
      ,[operator_first]         = o.first_name
      ,[operator_last]          = o.last_name
      ,[operator]               = o.last_name + ', ' + left(o.first_name, 1)
      ,[operators_supervisor]   = ltdo.supervisor
      ,[operator_jobcode]       = ltdo.jobcode
      ,[is_layover]             = a.is_layover
      ,[white_line]             = case when wl.the_date  is null then 'n' else 'y' end
      ,[drop_off_only]          = case when doo.the_date is null then 'n' else 'y' end
      ,[ltd_status]             = case when a.adjusted_missing_count = 1 then 'missing'
                                       when a.adjusted_ontime_count  = 1 then 'ontime'
                                       when a.adjusted_late_count    = 1 then 'late'
                                       when a.adjusted_early_count   = 1 then 'early'
                                                                         else 'undefined'
                                  end
      ,[waiver_id]             = saw.scheduled_waiver_id
      ,[waiver_description]    = saw.remark
      ,[waivers_in_one]        = case when saw.early_allowed_flag = 1 then 'e' else '' end + case when saw.late_allowed_flag = 1 then 'l' else '' end + case when saw.missed_allowed_flag = 1 then 'm' else '' end 
      ,[waiver_late_ok]        = saw.late_allowed_flag
      ,[waiver_early_ok]       = saw.early_allowed_flag
      ,[waiver_missed_ok]      = saw.missed_allowed_flag
      ,[late_waived_tp]        = a.late_waived_tp
      ,[early_waived_tp]       = a.early_waived_tp
      ,[missing_waived_tp]     = a.missing_waived_tp
      ,[late_count]            = a.late_count
      ,[early_count]           = a.early_count
      ,[ontime_count]          = a.ontime_count
      ,[missing_count]         = a.missing_count
      ,[adjusted_late]         = a.adjusted_late_count 
      ,[adjusted_early]        = a.adjusted_early_count 
      ,[adjusted_ontime]       = a.adjusted_ontime_count 
      ,[adjusted_missing]      = a.adjusted_missing_count
      ,[layover_late_allowed]  = a.layover_late_allowed
      ,[layover_early_allowed] = a.layover_early_allowed
      ,[spm_planner]           = isnull(spmr.planner, '**') 
      ,[bsi]                   = a.is_batchstorage
      ,[overload_id]           = a.overload_id
      --,[adherence_id]          = a.adherence_id
      ,[fom]                   = (a.validity & power(2,0)) + (a.validity & power(2,1)) + (a.validity & power(2,2)) + (a.validity & power(2,3)) 
      ,[valid_odometer]        = case when a.validity & power(2,5) = power(2,5) then 1 else 0 end 
      ,[valid_adherence]       = case when a.validity & power(2,6) = power(2,6) then 1 else 0 end 
      ,[valid_position]        = case when a.validity & power(2,7) = power(2,7) then 1 else 0 end 
  from      [LTD-TMDATA].tmdatamart.dbo.adherence                    a
 inner join [LTD-TMDATA].tmmain.dbo.service_calendar                 sc   WITH (NOLOCK) on sc.calendar_id            = a.calendar_id
 inner join ##sched_sel												 ss   WITH (NOLOCK) on ss.calendar_id = sc.calendar_id 
 inner join [LTD-TMDATA].tmmain.dbo.time_table_version               ttv  WITH (NOLOCK) on ttv.time_table_version_id = a.time_table_version_id  
 inner join [LTD-TMDATA].tmmain.dbo.geo_node                         gn   WITH (NOLOCK) on gn.geo_node_id            = a.geo_node_id
 inner join [LTD-TMDATA].tmmain.dbo.[block]                            b    WITH (NOLOCK) on b.block_id                = a.block_id
 inner join [LTD-TMDATA].tmmain.dbo.run                              r    WITH (NOLOCK) on r.run_id                  = a.run_id
 inner join [LTD-TMDATA].tmmain.dbo.time_point                       tp   WITH (NOLOCK) on tp.time_point_id          = a.time_point_id
 --inner join (select calendar_id, max(service_type_id) service_type_id from tmmain.dbo.service_selection group by calendar_id) ss on ss.calendar_id = sc.calendar_id
 inner join [LTD-TMDATA].tmmain.dbo.service_type                     st   WITH (NOLOCK) on st.service_type_id        = ss.service_type_id
  --left join #haveAdhIDs												hv	  WITH (NOLOCK) on hv.adherence_id			 = a.adherence_id
  left join [LTD-TMDATA].tmmain.dbo.trip                             t    WITH (NOLOCK) on t.trip_id                 = a.trip_id
  left join [LTD-TMDATA].ltd_db.dbo.trips_scheduled_times            tst  WITH (NOLOCK) on tst.trip_id               = t.trip_id
  left join [LTD-TMDATA].tmmain.dbo.[route]                          rte  WITH (NOLOCK) on rte.route_id              = a.route_id
  left join [LTD-TMDATA].tmmain.dbo.route_direction                  rd   WITH (NOLOCK) on rd.route_direction_id     = a.route_direction_id
  left join [LTD-TMDATA].tmmain.dbo.pattern                          p    WITH (NOLOCK) on p.pattern_id              = a.pattern_id
  left join [LTD-TMDATA].tmmain.dbo.operator                         o    WITH (NOLOCK) on o.operator_id             = a.operator_id
  left join [LTD-TMDATA].tmmain.dbo.geo_node                         tsgn WITH (NOLOCK) on tsgn.geo_node_id          = t.trip_start_node_id
  left join [LTD-TMDATA].tmmain.dbo.geo_node                         tegn WITH (NOLOCK) on tegn.geo_node_id          = t.trip_end_node_id
  left join [LTD-TMDATA].tmmain.dbo.ltd_operator_info                ltdo WITH (NOLOCK) on ltdo.badge                = o.badge
  left join [LTD-TMDATA].tmmain.dbo.ltd_vehicle_info                 v    WITH (NOLOCK) on v.vehicle_id              = a.vehicle_id
  left join [LTD-TMDATA].tmdailylog.dbo.sched_adhere_waiver          saw  WITH (NOLOCK) on saw.waiver_id             = a.sched_adhere_waiver_id
  left join [LTD-TMDATA].tmmain.dbo.ltd_spm_responsibility_per_route spmr WITH (NOLOCK) on spmr.[route]              = rte.route_abbr
  left join [LTD-TMDATA].tmmain.dbo.ltd_significant_tps              stps WITH (NOLOCK) on stps.[route]              = rte.route_abbr and stps.direction = left(rd.route_direction_name, 1) and stps.tp = tp.time_point_abbr
  left join [LTD-TMDATA].tmmain.dbo.ltd_incidents                    wl   WITH (NOLOCK) on wl.the_date               = sc.calendar_date 
                                                            and wl.blk                    = b.block_abbr 
                                                            and wl.type                   = 'white line' 
                                                            and a.scheduled_time          >= wl.the_time_spm
                                                            and wl.the_time_spm           between tst.trip_start_time and tst.trip_end_time
  left join [LTD-TMDATA].tmmain.dbo.ltd_incidents                    doo  WITH (NOLOCK) on doo.the_date              = sc.calendar_date 
                                                            and doo.blk                   = b.block_abbr 
                                                            and doo.type                  = 'drop-off only'
                                                            and a.scheduled_time          >= doo.the_time_spm
                                                            and doo.the_time_spm          between tst.trip_start_time and tst.trip_end_time
 where not (ttv.time_table_version_name = '1009b' and rte.route_abbr like '10[2-3]')
   and rte.route_abbr <> '25'  -- shawna added exclusion for training route 05/26/2015
   and a.calendar_id >= @loopStart  
   and a.calendar_id <= @loopEnd


create table #OutPCTbl9142 (adhcount BIGINT)
create table #OutPCTbl9242 (adhcount BIGINT)
create table #OutPCTbl9342 (adhcount BIGINT)

 
INSERT [tm].[ADHERENCE_METRICS](
	[adherence_id]
,	[calendar_id]
,	[the_date]
,	[day_type]
,	[ttv_id]
,	[ttv]
,	[bid]
,	[block_id]
,	[block]
,	[block_numeric]
,	[emx_block]
,	[taxi_block]
,	[trip_start]
,	[trip_end]
,	[sched]
,	[sched_spm]
,	[actual_arrival_spm]
,	[actual_departure_spm]
,	[arrive]
,	[depart]
,	[adhere_sec]
,	[adhere_min]
,	[dwell_sec]
,	[dwell_min]
,	[adherence]
,	[arrival_adhere_mins]
,	[end_of_trip]
,	[trip_end_important_tp]
,	[trip_end_missed]
,	[trip_end_ontime]
,	[trip_end_late_0_2]
,	[trip_end_late_2_4]
,	[trip_end_late_4_6]
,	[trip_end_late_6_plus]
,	[sched_interval]
,	[actual_interval]
,	[trip_id]
,	[revenue_id]
,	[rte]
,	[rte_dir]
,	[rte_public]
,	[rte_and_dir]
,	[rte_rural]
,	[rev_rte]
,	[pattern]
,	[the_bus]
,	[odometer]
,	[sched_miles_since_last]
,	[bus_class]
,	[artic]
,	[emx_bus]
,	[service_type]
,	[service_type_general]
,	[svc]
,	[run]
,	[block_stop_order]
,	[pattern_geo_node_seq]
,	[stop_no]
,	[stop_name]
,	[tp]
,	[tp_name]
,	[sa_tp]
,	[trip_start_stop]
,	[trip_start_stop_name]
,	[trip_end_stop]
,	[trip_end_stop_name]
,	[operator_id]
,	[badge]
,	[operator_first]
,	[operator_last]
,	[operator]
,	[operators_supervisor]
,	[operator_jobcode]
,	[is_layover]
,	[white_line]
,	[drop_off_only]
,	[ltd_status]
,	[waiver_id]
,	[waiver_description]
,	[waivers_in_one]
,	[waiver_late_ok]
,	[waiver_early_ok]
,	[waiver_missed_ok]
,	[late_waived_tp]
,	[early_waived_tp]
,	[missing_waived_tp]
,	[late_count]
,	[early_count]
,	[ontime_count]
,	[missing_count]
,	[adjusted_late]
,	[adjusted_early]
,	[adjusted_ontime]
,	[adjusted_missing]
,	[layover_late_allowed]
,	[layover_early_allowed]
,	[spm_planner]
,	[bsi]
,	[overload_id]
,	[fom]
,	[valid_odometer]
,	[valid_adherence]
,	[valid_position])
OUTPUT INSERTED.adherence_id into #OutPCTbl9142 (adhcount)
select
 s.[adherence_id]
,s.[calendar_id]
,s.[the_date]
,s.[day_type]
,s.[ttv_id]
,s.[ttv]
,s.[bid]
,s.[block_id]
,s.[block]
,s.[block_numeric]
,s.[emx_block]
,s.[taxi_block]
,s.[trip_start]
,s.[trip_end]
,s.[sched]
,s.[sched_spm]
,s.[actual_arrival_spm]
,s.[actual_departure_spm]
,s.[arrive]
,s.[depart]
,s.[adhere_sec]
,s.[adhere_min]
,s.[dwell_sec]
,s.[dwell_min]
,s.[adherence]
,s.[arrival_adhere_mins]
,s.[end_of_trip]
,s.[trip_end_important_tp]
,s.[trip_end_missed]
,s.[trip_end_ontime]
,s.[trip_end_late_0_2]
,s.[trip_end_late_2_4]
,s.[trip_end_late_4_6]
,s.[trip_end_late_6_plus]
,s.[sched_interval]
,s.[actual_interval]
,s.[trip_id]
,s.[revenue_id]
,s.[rte]
,s.[rte_dir]
,s.[rte_public]
,s.[rte_and_dir]
,s.[rte_rural]
,s.[rev_rte]
,s.[pattern]
,s.[the_bus]
,s.[odometer]
,s.[sched_miles_since_last]
,s.[bus_class]
,s.[artic]
,s.[emx_bus]
,s.[service_type]
,s.[service_type_general]
,s.[svc]
,s.[run]
,s.[block_stop_order]
,s.[pattern_geo_node_seq]
,s.[stop_no]
,s.[stop_name]
,s.[tp]
,s.[tp_name]
,s.[sa_tp]
,s.[trip_start_stop]
,s.[trip_start_stop_name]
,s.[trip_end_stop]
,s.[trip_end_stop_name]
,s.[operator_id]
,s.[badge]
,s.[operator_first]
,s.[operator_last]
,s.[operator]
,s.[operators_supervisor]
,s.[operator_jobcode]
,s.[is_layover]
,s.[white_line]
,s.[drop_off_only]
,s.[ltd_status]
,s.[waiver_id]
,s.[waiver_description]
,s.[waivers_in_one]
,s.[waiver_late_ok]
,s.[waiver_early_ok]
,s.[waiver_missed_ok]
,s.[late_waived_tp]
,s.[early_waived_tp]
,s.[missing_waived_tp]
,s.[late_count]
,s.[early_count]
,s.[ontime_count]
,s.[missing_count]
,s.[adjusted_late]
,s.[adjusted_early]
,s.[adjusted_ontime]
,s.[adjusted_missing]
,s.[layover_late_allowed]
,s.[layover_early_allowed]
,s.[spm_planner]
,s.[bsi]
,s.[overload_id]
,s.[fom]
,s.[valid_odometer]
,s.[valid_adherence]
,s.[valid_position]
from ##rawADHERENCE_METRICS s 
where not exists (
	select 1 from tm.ADHERENCE_METRICS 
		where  [calendar_id] = s.[calendar_id]
		AND [adherence_id] = s.[adherence_id]
		AND isnull([block_id],0) = isnull(s.[block_id],0)
		AND isnull(ttv_id,0) = isnull(s.ttv_id,0)
		AND isnull(trip_id,0) = isnull(s.trip_id,0)
		and isnull(run,0) = isnull(s.run,0)
		and isnull(rte_dir,'') = isnull(s.rte_dir,'')
		and isnull(stop_no,'') = isnull(s.stop_no,'')
		and isnull(pattern,0) = isnull(s.pattern,0)
		and isnull(tp,0) = isnull(s.tp,0)
		)

UPDATE t
set t.[the_date] = s.[the_date]
,t.[day_type] = s.[day_type]
,t.[ttv_id] = s.[ttv_id]
--,t.[ttv] = s.[ttv]
,t.[bid] = s.[bid]
--,t.[block_id] = s.[block_id]
,t.[block] = s.[block]
,t.[block_numeric] = s.[block_numeric]
,t.[emx_block] = s.[emx_block]
,t.[taxi_block] = s.[taxi_block]
,t.[trip_start] = s.[trip_start]
,t.[trip_end] = s.[trip_end]
,t.[sched] = s.[sched]
,t.[sched_spm] = s.[sched_spm]
,t.[actual_arrival_spm] = s.[actual_arrival_spm]
,t.[actual_departure_spm] = s.[actual_departure_spm]
,t.[arrive] = s.[arrive]
,t.[depart] = s.[depart]
,t.[adhere_sec] = s.[adhere_sec]
,t.[adhere_min] = s.[adhere_min]
,t.[dwell_sec] = s.[dwell_sec]
,t.[dwell_min] = s.[dwell_min]
,t.[adherence] = s.[adherence]
,t.[arrival_adhere_mins] = s.[arrival_adhere_mins]
,t.[end_of_trip] = s.[end_of_trip]
,t.[trip_end_important_tp] = s.[trip_end_important_tp]
,t.[trip_end_missed] = s.[trip_end_missed]
,t.[trip_end_ontime] = s.[trip_end_ontime]
,t.[trip_end_late_0_2] = s.[trip_end_late_0_2]
,t.[trip_end_late_2_4] = s.[trip_end_late_2_4]
,t.[trip_end_late_4_6] = s.[trip_end_late_4_6]
,t.[trip_end_late_6_plus] = s.[trip_end_late_6_plus]
,t.[sched_interval] = s.[sched_interval]
,t.[actual_interval] = s.[actual_interval]
--,t.[trip_id] = s.[trip_id]
,t.[revenue_id] = s.[revenue_id]
,t.[rte] = s.[rte]
--,t.[rte_dir] = s.[rte_dir]
,t.[rte_public] = s.[rte_public]
,t.[rte_and_dir] = s.[rte_and_dir]
,t.[rte_rural] = s.[rte_rural]
,t.[rev_rte] = s.[rev_rte]
,t.[pattern] = s.[pattern]
,t.[the_bus] = s.[the_bus]
,t.[odometer] = s.[odometer]
,t.[sched_miles_since_last] = s.[sched_miles_since_last]
,t.[bus_class] = s.[bus_class]
,t.[artic] = s.[artic]
,t.[emx_bus] = s.[emx_bus]
,t.[service_type] = s.[service_type]
,t.[service_type_general] = s.[service_type_general]
,t.[svc] = s.[svc]
--,t.[run] = s.[run]
,t.[block_stop_order] = s.[block_stop_order]
--,t.[pattern_geo_node_seq] = s.[pattern_geo_node_seq]
--,t.[stop_no] = s.[stop_no]
,t.[stop_name] = s.[stop_name]
--,t.[tp] = s.[tp]
,t.[tp_name] = s.[tp_name]
,t.[sa_tp] = s.[sa_tp]
,t.[trip_start_stop] = s.[trip_start_stop]
,t.[trip_start_stop_name] = s.[trip_start_stop_name]
,t.[trip_end_stop] = s.[trip_end_stop]
,t.[trip_end_stop_name] = s.[trip_end_stop_name]
,t.[operator_id] = s.[operator_id]
,t.[badge] = s.[badge]
,t.[operator_first] = s.[operator_first]
,t.[operator_last] = s.[operator_last]
,t.[operator] = s.[operator]
,t.[operators_supervisor] = s.[operators_supervisor]
,t.[operator_jobcode] = s.[operator_jobcode]
,t.[is_layover] = s.[is_layover]
,t.[white_line] = s.[white_line]
,t.[drop_off_only] = s.[drop_off_only]
,t.[ltd_status] = s.[ltd_status]
,t.[waiver_id] = s.[waiver_id]
,t.[waiver_description] = s.[waiver_description]
,t.[waivers_in_one] = s.[waivers_in_one]
,t.[waiver_late_ok] = s.[waiver_late_ok]
,t.[waiver_early_ok] = s.[waiver_early_ok]
,t.[waiver_missed_ok] = s.[waiver_missed_ok]
,t.[late_waived_tp] = s.[late_waived_tp]
,t.[early_waived_tp] = s.[early_waived_tp]
,t.[missing_waived_tp] = s.[missing_waived_tp]
,t.[late_count] = s.[late_count]
,t.[early_count] = s.[early_count]
,t.[ontime_count] = s.[ontime_count]
,t.[missing_count] = s.[missing_count]
,t.[adjusted_late] = s.[adjusted_late]
,t.[adjusted_early] = s.[adjusted_early]
,t.[adjusted_ontime] = s.[adjusted_ontime]
,t.[adjusted_missing] = s.[adjusted_missing]
,t.[layover_late_allowed] = s.[layover_late_allowed]
,t.[layover_early_allowed] = s.[layover_early_allowed]
,t.[spm_planner] = s.[spm_planner]
,t.[bsi] = s.[bsi]
,t.[overload_id] = s.[overload_id]
,t.[fom] = s.[fom]
,t.[valid_odometer] = s.[valid_odometer]
,t.[valid_adherence] = s.[valid_adherence]
,t.[valid_position] = s.[valid_position] 
,t.[record_updated_date] = sysdatetime()
OUTPUT deleted.adherence_id into #OutPCTbl9242
from tm.ADHERENCE_METRICS t
join ##rawADHERENCE_METRICS s on 
			t.[calendar_id] = s.[calendar_id]
		AND t.[adherence_id] = s.[adherence_id]
		AND t.[block_id] = s.[block_id]
		AND t.ttv_id = s.ttv_id
		AND t.trip_id = s.trip_id
		and t.run = s.run
		and t.rte_dir = s.rte_dir
		and t.stop_no = s.stop_no
		and t.pattern = s.pattern
		and t.tp = s.tp
	WHERE
		    s.[calendar_id] is not null
		AND s.[adherence_id] is not null
		AND s.[block_id] is not null
		AND s.ttv_id is not null
		AND s.trip_id is not null
		and s.run is not null
		and s.rte_dir is not null
		and s.stop_no is not null
		and s.pattern is not null
		and s.tp is not null
AND
(s.[the_date] <> t.[the_date]
OR s.[day_type] <> t.[day_type]
OR s.[ttv] <> t.[ttv]
OR s.[bid] <> t.[bid]
OR s.[block] <> t.[block]
OR s.[block_numeric] <> t.[block_numeric]
OR s.[emx_block] <> t.[emx_block]
OR s.[taxi_block] <> t.[taxi_block]
OR isnull(s.[trip_start],0) <> isnull(t.[trip_start],0)
OR isnull(s.[trip_end],'') <> isnull(t.[trip_end],'')
OR s.[sched] <> t.[sched]
OR s.[sched_spm] <> t.[sched_spm]
OR s.[actual_arrival_spm] <> t.[actual_arrival_spm]
OR s.[actual_departure_spm] <> t.[actual_departure_spm]
OR s.[arrive] <> t.[arrive]
OR s.[depart] <> t.[depart]
OR s.[adhere_sec] <> t.[adhere_sec]
OR s.[adhere_min] <> t.[adhere_min]
OR s.[dwell_sec] <> t.[dwell_sec]
OR s.[dwell_min] <> t.[dwell_min]
OR s.[adherence] <> t.[adherence]
OR s.[arrival_adhere_mins] <> t.[arrival_adhere_mins]
OR s.[end_of_trip] <> t.[end_of_trip]
OR s.[trip_end_important_tp] <> t.[trip_end_important_tp]
OR isnull(s.[trip_end_missed],0) <> isnull(t.[trip_end_missed],0)
OR isnull(s.[trip_end_ontime],0) <> isnull(t.[trip_end_ontime],0)
OR isnull(s.[trip_end_late_0_2],0) <> isnull(t.[trip_end_late_0_2],0)
OR isnull(s.[trip_end_late_2_4],0) <> isnull(t.[trip_end_late_2_4],0)
OR isnull(s.[trip_end_late_4_6],0) <> isnull(t.[trip_end_late_4_6],0)
OR isnull(s.[trip_end_late_6_plus],0) <> isnull(t.[trip_end_late_6_plus],0)
OR s.[sched_interval] <> t.[sched_interval]
OR s.[actual_interval] <> t.[actual_interval]
OR isnull(s.[revenue_id],'') <> isnull(t.[revenue_id],'')
OR s.[rte] <> t.[rte]
--OR s.[rte_dir] <> t.[rte_dir]
OR s.[rte_public] <> t.[rte_public]
OR s.[rte_and_dir] <> t.[rte_and_dir]
OR s.[rte_rural] <> t.[rte_rural]
OR s.[rev_rte] <> t.[rev_rte]
--OR s.[pattern] <> t.[pattern]
OR s.[the_bus] <> t.[the_bus]
OR s.[odometer] <> t.[odometer]
OR s.[sched_miles_since_last] <> t.[sched_miles_since_last]
OR s.[bus_class] <> t.[bus_class]
OR s.[artic] <> t.[artic]
OR s.[emx_bus] <> t.[emx_bus]
OR s.[service_type] <> t.[service_type]
OR s.[service_type_general] <> t.[service_type_general]
OR s.[svc] <> t.[svc]
--OR s.[run] <> t.[run]
OR s.[block_stop_order] <> t.[block_stop_order]
OR s.[pattern_geo_node_seq] <> t.[pattern_geo_node_seq]
--OR s.[stop_no] <> t.[stop_no]
OR s.[stop_name] <> t.[stop_name]
--OR s.[tp] <> t.[tp]
OR s.[tp_name] <> t.[tp_name]
OR s.[sa_tp] <> t.[sa_tp]
OR isnull(s.[trip_start_stop],'') <> isnull(t.[trip_start_stop],'')
OR isnull(s.[trip_start_stop_name],'') <> isnull(t.[trip_start_stop_name],'')
OR isnull(s.[trip_end_stop],'') <> isnull(t.[trip_end_stop],'')
OR isnull(s.[trip_end_stop_name],'') <> isnull(t.[trip_end_stop_name],'')
OR s.[operator_id] <> t.[operator_id]
OR s.[badge] <> t.[badge]
OR s.[operator_first] <> t.[operator_first]
OR s.[operator_last] <> t.[operator_last]
OR s.[operator] <> t.[operator]
OR s.[operators_supervisor] <> t.[operators_supervisor]
OR s.[operator_jobcode] <> t.[operator_jobcode]
OR s.[is_layover] <> t.[is_layover]
OR s.[white_line] <> t.[white_line]
OR s.[drop_off_only] <> t.[drop_off_only]
OR s.[ltd_status] <> t.[ltd_status]
OR isnull(s.[waiver_id],0) <> isnull(t.[waiver_id],0)
OR isnull(s.[waiver_description],'') <> isnull(t.[waiver_description],'')
OR isnull(s.[waivers_in_one],'') <> isnull(t.[waivers_in_one],'')
OR isnull(s.[waiver_late_ok],0) <> isnull(t.[waiver_late_ok],0)
OR isnull(s.[waiver_early_ok],0) <> isnull(t.[waiver_early_ok],0)
OR isnull(s.[waiver_missed_ok],0) <> isnull(t.[waiver_missed_ok],0)
OR isnull(s.[late_waived_tp],0) <> isnull(t.[late_waived_tp],0)
OR isnull(s.[early_waived_tp],0) <> isnull(t.[early_waived_tp],0)
OR isnull(s.[missing_waived_tp],0) <> isnull(t.[missing_waived_tp],0)
OR isnull(s.[late_count],0) <> isnull(t.[late_count],0)
OR isnull(s.[early_count],0) <> isnull(t.[early_count],0)
OR isnull(s.[ontime_count],0) <> isnull(t.[ontime_count],0)
OR isnull(s.[missing_count],0) <> isnull(t.[missing_count],0)
OR isnull(s.[adjusted_late],0) <> isnull(t.[adjusted_late],0)
OR isnull(s.[adjusted_early],0) <> isnull(t.[adjusted_early],0)
OR isnull(s.[adjusted_ontime],0) <> isnull(t.[adjusted_ontime],0)
OR isnull(s.[adjusted_missing],0) <> isnull(t.[adjusted_missing],0)
OR isnull(s.[layover_late_allowed],0) <> isnull(t.[layover_late_allowed],0)
OR isnull(s.[layover_early_allowed],0) <> isnull(t.[layover_early_allowed],0)
OR s.[spm_planner] <> t.[spm_planner]
OR isnull(s.[bsi],0) <> isnull(t.[bsi],0)
OR s.[overload_id] <> t.[overload_id]
OR isnull(s.[fom],0) <> isnull(t.[fom],0)
OR s.[valid_odometer] <> t.[valid_odometer]
OR s.[valid_adherence] <> t.[valid_adherence]
OR s.[valid_position] <> t.[valid_position] )


DELETE tm.ADHERENCE_METRICS
OUTPUT deleted.adherence_id into #OutPCTbl9342 
from tm.ADHERENCE_METRICS t
WHERE t.calendar_id between @loopstart and @loopend
and not exists (select 1 from ##rawADHERENCE_METRICS
				where   [calendar_id] = t.[calendar_id]
						AND [adherence_id] = t.[adherence_id]
						AND isnull([block_id],0) = isnull(t.[block_id],0)
						AND isnull(ttv_id,0) = isnull(t.ttv_id,0)
						AND isnull(trip_id,0) = isnull(t.trip_id,0)
						and isnull(run,0) = isnull(t.run,0)
						and isnull(rte_dir,'') = isnull(t.rte_dir,'')
						and isnull(stop_no,'') = isnull(t.stop_no,'')
						and isnull(pattern,0) = isnull(t.pattern,0)
						and isnull(tp,0) = isnull(t.tp,0)
				)

insert [wrk].[DeletedAdhID]
select adhcount, @loopstart, @loopend from #OutPCTbl9342

declare @n int = (select isnull(count(*),0) from #OutPCTbl9142 )
declare @u int = (select isnull(count(*),0) from #OutPCTbl9242 )
declare @d int = (select isnull(count(*),0) from #OutPCTbl9342 )


 insert [process].[MergeLogs] (
	   [MergeCode]
      ,[ObjectDestination]
      ,[ObjectSource]
      ,[ObjectProgram]
      ,[recInsert]
      ,[recUpdate]
      ,[recDelete]
      ,[MergeBeginDatetime]
	  ,[MergeEndDatetime])
	  Values(
	  'ADH', 'LTD_DW.tm.ADHERENCE_METRICS','TM','LTD_DW.tm.GET_ADHERENCE_METRICS_'+cast(@loopStart as varchar(14))
	  ,isnull(@n,0), isnull(@u,0), isnull(@d,0), @loopstartdt, sysdatetime())

IF OBJECT_ID('tempdb.dbo.#OutPCTbl9142', 'U') IS NOT NULL
  drop table #OutPCTbl9142 
IF OBJECT_ID('tempdb.dbo.#OutPCTbl9242', 'U') IS NOT NULL
  drop table #OutPCTbl9242 
IF OBJECT_ID('tempdb.dbo.#OutPCTbl9342', 'U') IS NOT NULL
  drop table #OutPCTbl9342 
IF OBJECT_ID('tempdb.dbo.##rawADHERENCE_METRICS', 'U') IS NOT NULL
  DROP TABLE dbo.##rawADHERENCE_METRICS

 
	select @i = @i + 1

	If @i > @r
		BREAK
		ELSE CONTINUE
	END

END	


IF OBJECT_ID('tempdb.dbo.##sched_sel', 'U') IS NOT NULL
  DROP TABLE dbo.##sched_sel
IF OBJECT_ID('tempdb.dbo.##dtloopsADH', 'U') IS NOT NULL
  DROP TABLE dbo.##dtloopsADH
IF OBJECT_ID('tempdb.dbo.##rawADHERENCE_METRICS', 'U') IS NOT NULL
  DROP TABLE dbo.##rawADHERENCE_METRICS


  
END TRY	  


BEGIN CATCH

       DECLARE @profile VARCHAR(255) = (
                    SELECT NAME
                    FROM msdb.dbo.sysmail_profile where name like '%SQL%'
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
