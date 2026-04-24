SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create procedure [apc].[ltd_p_apc_survey_with_passengermiles_a]
 @suppress bit = 0 
/* 
PURPOSE: used to populate the report "APC Survey Data with Passenger Mileage"
		 Z:\tmapp\v27 ltd report source

   AUTHOR: beichberger
     DATE: 20190718
    PARAM: 0 for no filtering by numeric stop names, 1 = filter out non numeric stop names (stations, etc).
CHANGEDON: 20200121
 CHANGEBY: b eichberger
   CHANGE: Added error handling.

   exec [apc].[ltd_p_apc_survey_with_passengermiles] 0


*/
AS 

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

-----------------------------TEST
	--DECLARE @suppress bit = 0 
-----------------------------TEST


--UPDATE [ltd_dw].[apc].[apc_survey_data] SET [fileSource] = REPLACE(REPLACE([fileSource],'\\ltd-glnfas2\Workgroup\SP&M\APC_Survey\2023\Survey_Data_Entry_Sheets_TEST_07102023\',''),'.xlsx','')
--UPDATE [ltd_dw].[apc].[apc_survey_data] SET [fileSource] = REPLACE(REPLACE([fileSource],'\\ltd-glnfas2\Workgroup\SP&M\APC_Survey\2023\SurveyData2023\',''),'.xlsx','')


--UPDATE [ltd_dw].[apc].apc_survey_trips SET [fileSource] = REPLACE(REPLACE([fileSource],'\\ltd-glnfas2\Workgroup\SP&M\APC_Survey\2023\Survey_Data_Entry_Sheets_TEST_07102023\',''),'.xlsx','')
--UPDATE [ltd_dw].[apc].apc_survey_trips SET [fileSource] = REPLACE(REPLACE([fileSource],'\\ltd-glnfas2\Workgroup\SP&M\APC_Survey\2023\SurveyData2023\',''),'.xlsx','')

if (select count(*) from sys.indexes where name = 'ix_tmpapcDt') = 0
BEGIN
create index ix_tmpapcDt on [apc].[apc_survey_data] (survey_date)
END

DROP TABLE IF EXISTS #caldays
SELECT distinct convert(VARCHAR(32), [survey_date], 112) + 100000000 calendar_id
		into #caldays -- select * 		
		FROM [apc].[apc_survey_data_a]
WHERE inserted_datetime >= '12/31/' + cast(year(getdate())-1 as varchar(12))

create index ix_tmpCal on #caldays (calendar_id)

DROP TABLE IF EXISTS #vehlist
SELECT i.vehicle_id, apct.bus
		into #vehlist 
		FROM -- select * from 
		ltd_dw.apc.apc_survey_trips apct WITH (NOLOCK) 
			--ON apct.[fileSource] = apc.fileSource
	LEFT JOIN model.Vehicle_v i ON i.EQ_equip_no = apct.bus
	group by i.vehicle_id, apct.bus 
			
DROP TABLE IF EXISTS #block
select *,case when substring(right('000' + block_abbr, 4), 2, 1) = '9' then 'y' else 'n' end emx_block
	 into #block from [ltd-tmdata].tmdatamart.dbo.[block] WITH (NOLOCK) where TIME_TABLE_VERSION_ID > 100

DROP TABLE IF EXISTS #rte
select * into 
#rte from [ltd-tmdata].tmdatamart.dbo.[route] WITH (NOLOCK) 

DROP TABLE IF EXISTS #badgenm
select employee_id,last_name, 
	CASE WHEN ISNULL(middle_name,'') = '' THEN '' ELSE
		UPPER(LEFT(middle_name,1))+'.' END middle_name,first_name 
INTO #badgenm 
FROM pds.Integration_EmpPerson WITH (NOLOCK) WHERE emp_person_status = 'Current'

drop TABLE IF exists #gxref
select PATTERN_ID, geo_node_id, pattern_geo_node_seq, TIME_TABLE_VERSION_ID 
INTO #gxref from [ltd-tmdata].tmmain.dbo.pattern_geo_node_xref WITH (NOLOCK)
where  TIME_TABLE_VERSION_ID > 100 

drop table IF EXISTS #passc
select 
p.[PASSENGER_COUNT_ID]
,p.[CALENDAR_ID]
,p.[TIME_TABLE_VERSION_ID]
,p.[ROUTE_DIRECTION_ID]
,p.[PATTERN_ID]
,p.[GEO_NODE_ID]
,p.[OPERATOR_ID]
,p.[RUN_ID]
,p.[WORK_PIECE_ID]
,p.[VEHICLE_ID]
,p.[BLOCK_ID]
,p.[TRIP_ID]
,p.[BLOCK_STOP_ORDER]
,p.[MESSAGE_TIME]
,p.[BOARD]
,p.[ALIGHT]
,p.[SCHED_DIST_FROM_LAST_GEO_NODE]
,p.[DEPARTURE_LOAD]
,p.[ARRIVAL_TIME]
,p.[DEPARTURE_TIME]
,p.[ROUTE_ID]
,p.[REVENUE_ID]
,p.[ODOMETER]
,p.[GEO_NODE_INTERVAL_ID]
,p.[TIME_POINT_INTERVAL_ID]
	   into #passc
	  FROM [ltd-tmdata].[tmdatamart].[dbo].[PASSENGER_COUNT] p WITH (NOLOCK)
		join #caldays c on c.calendar_id = p.CALENDAR_ID 
		join -- select * from 
			#vehlist v on v.vehicle_id = p.vehicle_id
-- select * from #passc order by calendar_id,route_id,route_direction_id
CREATE NONCLUSTERED INDEX [ix_tmpPassC2]
ON #passc ([ROUTE_ID])
INCLUDE ([PASSENGER_COUNT_ID],[CALENDAR_ID],[ROUTE_DIRECTION_ID],[PATTERN_ID],[GEO_NODE_ID],[VEHICLE_ID],[BLOCK_ID],[TRIP_ID],[REVENUE_ID],[ODOMETER],[BLOCK_STOP_ORDER],[MESSAGE_TIME],[BOARD],[ALIGHT],[SCHED_DIST_FROM_LAST_GEO_NODE],[DEPARTURE_LOAD])


create index IX_tmpBlk on #block (block_id) 
create index IX_tmpRte on #rte (route_id) 
create index IX_tmpPassc on #passc (calendar_id, passenger_count_id) INCLUDE (block_id,route_id,trip_id,pattern_id,geo_node_id)


declare @minpassdt varchar(32)
declare @maxpassdt varchar(32)
declare @passidstart varchar(32)
declare @passidend varchar(32)

select @minpassdt = (select min(calendar_id) from #passc)
select @maxpassdt = (select max(calendar_id) from #passc)

select @passidstart = (select min(passenger_count_id) from #passc)
select @passidend = (select max(passenger_count_id) from #passc)

drop table IF EXISTS #lmiles -- 1181916
select m.* into #lmiles from [ltd-tmdata].ltd_db.dbo.pc_load_and_passenger_miles m WITH (NOLOCK)
where m.passenger_count_id between @passidstart and @passidend
  --and m.calendar_id between @minpassdt and @maxpassdt

DROP TABLE IF EXISTS #sccal
select calendar_id, calendar_date
INTO -- SELECT * FROM  
#sccal from [ltd-tmdata].tmmain.dbo.service_calendar sc WITH (NOLOCK)
where sc.calendar_id in (select calendar_id from #caldays)

DROP TABLE IF EXISTS #trip
select trip_id, trip_end_time into #trip from [ltd-tmdata].tmmain.dbo.trip trp WITH (NOLOCK) 
where trp.trip_id in (select trip_id from #passc)
group by trip_id, trip_end_time

DROP TABLE IF EXISTS #gndet
select geo_node_id,geo_node_abbr, gn.geo_node_name into #gndet from [ltd-tmdata].tmmain.dbo.geo_node gn WITH (NOLOCK) 
where gn.geo_node_id in (select geo_node_id from #gxref)
group by geo_node_id,geo_node_abbr, gn.geo_node_name

DROP TABLE IF EXISTS #ttv
select time_table_version_id, activation_date,deactivation_date into #ttv from 
[ltd-tmdata].tmmain.dbo.time_table_version ttv WITH (NOLOCK)
join #sccal sc on sc.calendar_date BETWEEN ttv.activation_date AND ttv.deactivation_date


drop table IF EXISTS #tmpPC
CREATE TABLE #tmpPC(
	[REVENUE_ID] [char](1) NULL,
	[Calendar_ID] [numeric](10, 0) NOT NULL,
	[run_load] [int] NULL,
	[DEPARTURE_LOAD] [int] NULL,
	[passenger_miles] [numeric](9, 2) NULL,
	[CALENDAR_DATE] [datetime] NOT NULL,
	[ROUTE_DIRECTION_ID] [numeric](5, 0) NULL,
	[PATTERN_ID] [numeric](10, 0) NULL,
	[rte_dir] [varchar](10) NULL,
	[GEO_NODE_ID] [numeric](10, 0) NULL,
	[VEHICLE_ID] [numeric](5, 0) NULL,
	[TRIP_ID] [numeric](10, 0) NULL,
	[SCHED_DIST_FROM_LAST_GEO_NODE] [int] NULL,
	[MESSAGE_TIME] [int] NULL,
	[BOARD] [int] NOT NULL,
	[ALIGHT] [int] NOT NULL,
	[ODOMETER] [int] NULL,
	[ROUTE_ID] [int] NULL,
	[trip_stop_seq] [bigint] NULL,
	[stop_seq] [numeric](7, 0) NOT NULL,
	[stop_no] [varchar](8) NOT NULL,
	[stop_name] [varchar](75) NOT NULL,
	[pc_trip_end] [char](5) NULL,
	[pc_time] [char](5) NULL,
	[Mode] varchar(15) NULL
) ON [PRIMARY]


insert #tmpPC (
[REVENUE_ID]
,[Calendar_ID]
,[run_load]
,[DEPARTURE_LOAD]
,[passenger_miles]
,[CALENDAR_DATE]
,[ROUTE_DIRECTION_ID]
,[PATTERN_ID]
,[rte_dir]
,[GEO_NODE_ID]
,[VEHICLE_ID]
,[TRIP_ID]
,[SCHED_DIST_FROM_LAST_GEO_NODE]
,[MESSAGE_TIME]
,[BOARD]
,[ALIGHT]
,[ODOMETER]
,[ROUTE_ID]
,[trip_stop_seq]
,[stop_seq]
,[stop_no]
,[stop_name]
,[pc_trip_end]
,[pc_time]
,[Mode])
SELECT [REVENUE_ID]
	,pc.Calendar_ID
	,m.run_load -- ltd calculated field
	,pc.DEPARTURE_LOAD -- trapeze data
	,m.passenger_miles
	,sc.CALENDAR_DATE
	,pc.[ROUTE_DIRECTION_ID]
	,pc.[PATTERN_ID]
	,rte_dir = rte.route_abbr + '-' + left(rd.route_direction_abbr, 1)
	,pc.[GEO_NODE_ID]
	,pc.[VEHICLE_ID]
	,pc.[TRIP_ID]
	,pc.SCHED_DIST_FROM_LAST_GEO_NODE
	,[MESSAGE_TIME]
	,[BOARD]
	,[ALIGHT]
	,[ODOMETER]
	,pc.[ROUTE_ID]
	,[trip_stop_seq] = row_number() over(partition by pc.calendar_id, pc.block_id, pc.trip_id order by pc.calendar_id, pc.block_id, pc.block_stop_order) 
	,[stop_seq] = px.pattern_geo_node_seq
	,[stop_no] = gn.geo_node_abbr
	,[stop_name] = gn.geo_node_name
	,pc_trip_end = tm.convert_passing_time(trp.trip_end_time)
	,pc_time = tm.convert_passing_time(pc.message_time)
	,[Mode] = case when emx_block = 'y' then 'RB-DO' else 'MB-DO' end 
FROM #passc 
	pc WITH (NOLOCK)
INNER JOIN #sccal sc WITH (NOLOCK) ON sc.CALENDAR_ID = pc.CALENDAR_ID
inner join #block blk WITH (NOLOCK) on blk.block_id           = pc.block_id
inner join #rte rte WITH (NOLOCK) on rte.route_id           = pc.route_id
INNER JOIN #trip trp WITH (NOLOCK) ON trp.trip_id = pc.trip_id
INNER JOIN #gxref px WITH (NOLOCK) ON px.pattern_id = pc.pattern_id
	AND px.geo_node_id = pc.geo_node_id
INNER JOIN #gndet gn WITH (NOLOCK) ON gn.geo_node_id = px.geo_node_id
INNER JOIN [ltd-tmdata].tmmain.dbo.route_direction rd WITH (NOLOCK) ON pc.ROUTE_DIRECTION_ID = rd.ROUTE_DIRECTION_ID
LEFT JOIN #vehlist v ON pc.VEHICLE_ID = v.VEHICLE_ID 
LEFT JOIN #lmiles m ON m.passenger_count_id = PC.PASSENGER_COUNT_ID
where (isnumeric(rte.route_abbr) = 1 
)
or ISNUMERIC(rte.route_abbr) = 0

-- select * from #tmpPC order by calendar_id,trip_id,route_id,route_direction_id,stop_seq

CREATE NONCLUSTERED INDEX [IX_tmpPC]
ON #tmpPC ([pc_trip_end])
INCLUDE ([Calendar_ID],[run_load],[DEPARTURE_LOAD],[passenger_miles],[CALENDAR_DATE],[ROUTE_DIRECTION_ID],[rte_dir],[VEHICLE_ID],[TRIP_ID],[SCHED_DIST_FROM_LAST_GEO_NODE],[MESSAGE_TIME],[BOARD],[ALIGHT],[ODOMETER],[ROUTE_ID],[stop_seq],[stop_no],[stop_name],[pc_time])

DROP TABLE IF EXISTS #tmpPC2
SELECT y.*
INTO #tmpPC2
FROM (
	SELECT rnbr = row_number() OVER (
			PARTITION BY p.[calendar_id]
			,p.[rte_dir]
			,p.pc_trip_end ORDER BY [stop_seq]
			)
		,p.CALENDAR_ID
		,p.CALENDAR_DATE
		,p.run_load 
		,p.DEPARTURE_LOAD 
		,p.passenger_miles
		,p.MESSAGE_TIME
		,p.ODOMETER
		,p.pc_time
		,p.pc_trip_end
		,SCHED_DIST_FROM_LAST_GEO_NODE sched_FT
		,case when DEPARTURE_LOAD > 0 then p.SCHED_DIST_FROM_LAST_GEO_NODE /DEPARTURE_LOAD else 0 end pmtm
		,cast(p.SCHED_DIST_FROM_LAST_GEO_NODE as float) / 5280 as SCHED_DIST_FROM_LAST_GEO_NODE
		,p.stop_no
		,p.stop_name
		,p.stop_seq
		,p.[trip_stop_seq]
		,p.ROUTE_DIRECTION_ID
		,p.ROUTE_ID
		,p.rte_dir
		,p.TRIP_ID
		,p.VEHICLE_ID
		,Mode
		,sum(isnull(p.BOARD,0)) BOARD
		,sum(isnull(p.ALIGHT,0)) ALIGHT
	FROM -- select * from
	#tmpPC p
	INNER JOIN (
		SELECT DISTINCT trip_end
		FROM apc.apc_survey_trips
		) t ON t.trip_end = p.pc_trip_end
	GROUP BY p.CALENDAR_ID
		,p.CALENDAR_DATE
		,p.run_load 
		,p.DEPARTURE_LOAD
		,p.MESSAGE_TIME
		,p.ODOMETER
		,p.pc_time
		,p.pc_trip_end
		,p.SCHED_DIST_FROM_LAST_GEO_NODE
		,p.passenger_miles
		,p.stop_no
		,p.stop_name
		,p.stop_seq
		,p.[trip_stop_seq]
		,p.ROUTE_DIRECTION_ID
		,p.ROUTE_ID
		,p.rte_dir
		,p.TRIP_ID
		,p.VEHICLE_ID
		,Mode
	) y

DROP TABLE IF EXISTS #apcRow1
select rnbr
	  ,Calendar_ID
	  ,CALENDAR_DATE
	  ,run_load
	  ,DEPARTURE_LOAD
	  ,passenger_miles
	  ,MESSAGE_TIME
	  ,ODOMETER
	  ,pc_time
	  ,pc_trip_end
	  ,sched_FT
	  ,pmtm
	  ,SCHED_DIST_FROM_LAST_GEO_NODE
	  ,stop_no
	  ,stop_name
	  ,stop_seq
	  ,trip_stop_seq
	  ,ROUTE_DIRECTION_ID
	  ,ROUTE_ID
	  ,rte_dir
	  ,TRIP_ID
	  ,VEHICLE_ID
	  ,Mode
	  ,BOARD
	  ,ALIGHT
INTO -- select * from 
#apcRow1 from #tmpPC2 where rnbr = 1

update #tmpPC2 set board = 0, alight = 0 where rnbr = 1
-- select * from #tmpPC2
-- if the direction is an outbound and the route is not like '10%' (104, 103, 105 are EMx routes)
 -- then move initial count to mpc FROMT

DROP TABLE IF EXISTS #mpcprep
 SELECT  
 100000000 + convert(varchar(32),apct.[survey_date],112) as calendar_id
		,rnbr = row_number() OVER (PARTITION BY apc.survey_date, apct.[rte_dir],apct.[trip_end] order by [stop_seq])
			  , apc.inserted_datetime
			  ,apc.survey_date
			  ,apc.rte_dir
			  ,apc.trip_end
			  ,apc.stop_seq
			  ,apc.stop_no
			  ,apc.stop_nm
			  ,apc.ons_f
			  ,apc.offs_f
			  ,apc.notes_f
			  ,apc.ons_m
			  ,apc.offs_m
			  ,apc.notes_m
			  ,apc.ons_r
			  ,apc.offs_r
			  ,apc.notes_r
			  ,apc.time_f
			  ,apc.time_m
			  ,apc.time_r
			  ,apc.fileSource
			  ,apct.[bus]
			  ,veh.VEHICLE_ID
			  ,apct.[initial_count]
			  ,apct.[surveyor_badge_f]
			  ,apct.[surveyor_badge_m]
			  ,apct.[surveyor_badge_r]
			  ,rte.ROUTE_ID
			  ,rd.ROUTE_DIRECTION_ID
		  into #mpcprep 
		  FROM [apc].[apc_survey_data_a]  apc 
		  INNER JOIN [apc].[apc_survey_trips_a] apct 
		   ON RTRIM(LTRIM(apc.[fileSource])) = RTRIM(LTRIM(apct.fileSource))
		  INNER join [LTD-TMDATA].tmmain.dbo.time_table_version    ttv WITH (NOLOCK) ON CAST(apc.survey_date AS DATE) between CAST(ttv.activation_date AS DATE) and CAST(ttv.deactivation_date AS DATE)
		  INNER join [LTD-TMDATA].tmmain.dbo.[route]                 rte WITH (NOLOCK) 
						ON rte.time_table_version_id = ttv.time_table_version_id 
						and rte.route_abbr = left(apc.rte_dir, charindex('-', apc.rte_dir) -1)
		  INNER join [LTD-TMDATA].tmmain.dbo.route_direction       rd WITH (NOLOCK)  on left(rd.route_direction_abbr, 1) = right(apc.rte_dir, 1)
		  LEFT join  model.Vehicle_v veh WITH (NOLOCK) on veh.property_tag = apct.bus

	   	
DROP TABLE IF EXISTS #mpcRow1
select *
INTO #mpcRow1 
FROM #mpcprep where rnbr = 1

update #mpcprep set [ons_f]=0, [ons_r]=0, [ons_m]=0, [offs_f]=0, [offs_r]=0, [offs_m] = 0 where rnbr = 1

DROP TABLE IF EXISTS #mpc
select 
 manualcount_load =
case when rnbr = 1 then [initial_count]
	 when rnbr <> 1 
		and sum(([ons_f] + [ons_r] + [ons_m]) - ([offs_f] + [offs_r] + [offs_m])) OVER (PARTITION BY filesource  ORDER BY [stop_seq]) + [initial_count] < 0 then 0 
		else sum(([ons_f] + [ons_r] + [ons_m]) - ([offs_f] + [offs_r] + [offs_m])) OVER (PARTITION BY filesource  ORDER BY [stop_seq]) + [initial_count]
		end   
		,y.*
 into #mpc
	from #mpcprep y
	-- select * from #mpc   order by calendar_id, trip_end,[rte_dir],stop_seq 


DROP TABLE IF EXISTS #finalAPC
CREATE TABLE #finalAPC (
	[survey_date] date NULL,
	[fileSource] [varchar](255) NULL,
	[calendar_id] [numeric](10, 0) NULL,
	[pc_rte_dir] [varchar](10) NULL,
	[pc_trip_end] [char](5) NULL,
	[survey_trip] [varchar](26) NULL,
	[pc_bus] [varchar](50) NULL,
	[apc_surveyor_badge_f] [varchar](50) NULL,
	[apc_surveyor_name_f] [varchar](41) NULL,
	[apc_surveyor_f] [varchar](93) NULL,
	[apc_surveyor_badge_m] [varchar](50) NULL,
	[apc_surveyor_name_m] [varchar](41) NULL,
	[apc_surveyor_m] [varchar](93) NULL,
	[apc_surveyor_badge_r] [varchar](50) NULL,
	[apc_surveyor_name_r] [varchar](41) NULL,
	[apc_surveyor_r] [varchar](93) NULL,
	[apc_bus] [varchar](50) NULL,
	trip_stop_seq INT NULL,
	[stop_seq] [numeric](7, 0) NULL,
	[stop_no] [varchar](8) NULL,
	[stop_name] [varchar](75) NULL,
	[pc_time] [char](5) NULL,
	[pc_odometer] [int] NULL,
	[last_odometer] [int] NULL,
	[mpc_initial_count] [smallint] NULL,
	[MILES_TO_NEXT_GN] [decimal](6, 2) NULL,
	[MILES_FROM_LAST_GN] [decimal](6, 2) NULL,
	[mpc_load] [int] NULL,
	[mpc_pass_miles_to_next_stop] float NULL,
	[mpc_pass_miles_from_last_stop] float NULL,
	[DEPARTURE_LOAD] [int] NULL,
	[DepartureLoadContinuous] [int] NULL,
	[distanceforcalc] [float] NULL,
	[passenger_miles_by_tm] float NULL,
	[passenger_miles_by_tm_rt] float NULL,
	[new_pc_pass_miles] float NULL,
	[apc_ons] [int] NULL,
	[apc_offs] [int] NULL,
	[pc_ons] [int] NULL,
	[pc_offs] [int] NULL,
	[apc_time_f] [varchar](50) NULL,
	[apc_ons_f] [int] NULL,
	[apc_offs_f] [int] NULL,
	[apc_notes_f] [varchar](255) NULL,
	[apc_time_m] [varchar](50) NULL,
	[apc_ons_m] [int] NULL,
	[apc_offs_m] [int] NULL,
	[apc_notes_m] [varchar](255) NULL,
	[apc_time_r] [varchar](50) NULL,
	[apc_ons_r] [int] NULL,
	[apc_offs_r] [int] NULL,
	[apc_notes_r] [varchar](255) NULL,
	[Mode] varchar(15) NULL,
	[mpc_pass_miles_from_last_stop_route] float NULL,
	[mpc_miles_from_last_rt] float NULL,
	[apc_miles_rt] float NULL,
	[apc_new_miles_rt] float NULL,
	rnbr INT,
	autocountload float
) ON [PRIMARY]

	-- select * from #finalAPC
if @suppress = 1
  BEGIN
  insert #finalAPC
  (survey_date, fileSource, calendar_id, pc_rte_dir, pc_trip_end, survey_trip, pc_bus, apc_surveyor_badge_f, apc_surveyor_name_f, apc_surveyor_f, apc_surveyor_badge_m, apc_surveyor_name_m, apc_surveyor_m, apc_surveyor_badge_r, apc_surveyor_name_r, apc_surveyor_r, apc_bus, trip_stop_seq, stop_seq, stop_no, stop_name, pc_time, pc_odometer, last_odometer, mpc_initial_count, MILES_TO_NEXT_GN, MILES_FROM_LAST_GN, mpc_load, mpc_pass_miles_to_next_stop, mpc_pass_miles_from_last_stop, DEPARTURE_LOAD, DepartureLoadContinuous, distanceforcalc, passenger_miles_by_tm, passenger_miles_by_tm_rt, new_pc_pass_miles, apc_ons, apc_offs, pc_ons, pc_offs, apc_time_f, apc_ons_f, apc_offs_f, apc_notes_f, apc_time_m, apc_ons_m, apc_offs_m, apc_notes_m, apc_time_r, apc_ons_r, apc_offs_r, apc_notes_r, Mode, mpc_pass_miles_from_last_stop_route, mpc_miles_from_last_rt, apc_miles_rt, apc_new_miles_rt, rnbr, autocountload)
 select z.survey_date
	   ,z.fileSource
	   ,z.calendar_id
	   ,z.pc_rte_dir
	   ,z.pc_trip_end
	   ,z.survey_trip
	   ,z.pc_bus
	   ,z.apc_surveyor_badge_f
	   ,z.apc_surveyor_name_f
	   ,z.apc_surveyor_f
	   ,z.apc_surveyor_badge_m
	   ,z.apc_surveyor_name_m
	   ,z.apc_surveyor_m
	   ,z.apc_surveyor_badge_r
	   ,z.apc_surveyor_name_r
	   ,z.apc_surveyor_r
	   ,z.apc_bus
	   ,z.trip_stop_seq
	   ,z.stop_seq
	   ,z.stop_no
	   ,z.stop_name
	   ,z.pc_time
	   ,z.pc_odometer
	   ,z.last_odometer
	   ,z.mpc_initial_count
	   ,z.MILES_TO_NEXT_GN
	   ,z.MILES_FROM_LAST_GN
	   ,z.mpc_load
	   ,z.mpc_pass_miles_to_next_stop
	   ,z.mpc_pass_miles_from_last_stop
	   ,z.DEPARTURE_LOAD
	   ,z.DepartureLoadContinuous
	   ,z.distanceforcalc
	   ,z.passenger_miles_by_tm
	   ,z.passenger_miles_by_tm_rt
	   ,z.new_pc_pass_miles
	   ,z.apc_ons
	   ,z.apc_offs
	   ,z.pc_ons
	   ,z.pc_offs
	   ,z.apc_time_f
	   ,z.apc_ons_f
	   ,z.apc_offs_f
	   ,z.apc_notes_f
	   ,z.apc_time_m
	   ,z.apc_ons_m
	   ,z.apc_offs_m
	   ,z.apc_notes_m
	   ,z.apc_time_r
	   ,z.apc_ons_r
	   ,z.apc_offs_r
	   ,z.apc_notes_r
	   ,z.Mode
	   ,z.mpc_pass_miles_from_last_stop_route
	   ,z.mpc_miles_from_last_rt
	   ,z.apc_miles_rt
	   ,z.apc_new_miles_rt
	   ,z.rnbr ,
		autocount_load =
	case when rnbr = 1 then [mpc_initial_count]
		 when rnbr <> 1 
			and sum(pc_ons - pc_offs) OVER (PARTITION BY calendar_id,[pc_rte_dir],pc_trip_end  ORDER BY [stop_seq]) + [mpc_initial_count] < 0 then 0 
			else sum(pc_ons - pc_offs) OVER (PARTITION BY calendar_id,[pc_rte_dir],pc_trip_end  ORDER BY [stop_seq]) + [mpc_initial_count]
			end   
	from (
		select *,
		sum(mpc_pass_miles_from_last_stop) OVER (Partition by left(filesource,11) order by pc_rte_dir desc, stop_seq)  mpc_pass_miles_from_last_stop_route
		,sum(mpc_pass_miles_from_last_stop) OVER (Partition by filesource ORDER BY [stop_seq])  as mpc_miles_from_last_rt
		,sum(passenger_miles_by_tm) OVER (PARTITION BY filesource ORDER BY [stop_seq]) apc_miles_rt
		,sum(new_pc_pass_miles)  OVER (Partition by filesource ORDER BY [stop_seq]) apc_new_miles_rt
		,rnbr = row_number() OVER (PARTITION BY filesource ORDER BY [stop_seq])
		from (
		select 
			   [survey_date]          = q.survey_date
			  ,fileSource
			  ,[calendar_id]          = pc.calendar_id
			  ,[pc_rte_dir]           = pc.rte_dir
			  ,[pc_trip_end]          = pc_trip_end 
			  ,[survey_trip]          = convert(varchar(32),q.survey_date,101) + ', ' + q.rte_dir + ', ' + q.trip_end
			  ,[pc_bus]               = q.bus
			  ,[apc_surveyor_badge_f] = q.surveyor_badge_f
			  ,[apc_surveyor_name_f]  = q.surveyor_name_f
			  ,[apc_surveyor_f]       = q.surveyor_name_f + '(' + q.surveyor_badge_f + ')'
			  ,[apc_surveyor_badge_m] = q.surveyor_badge_m
			  ,[apc_surveyor_name_m]  = q.surveyor_name_m
			  ,[apc_surveyor_m]       = q.surveyor_name_m + '(' + q.surveyor_badge_m + ')'
			  ,[apc_surveyor_badge_r] = q.surveyor_badge_r
			  ,[apc_surveyor_name_r]  = q.surveyor_name_r
			  ,[apc_surveyor_r]       = q.surveyor_name_r + '(' + q.surveyor_badge_r + ')'
			  ,[apc_bus]              = q.bus
			  ,trip_stop_seq
			  ,[stop_seq]             = pc.stop_seq
			  ,[stop_no]              = pc.stop_no
			  ,[stop_name]            = pc.stop_name
			  ,[pc_time]              = pc_time
			  ,[pc_odometer]          = pc.odometer 
			  ,last_odometer = lag(pc.odometer ,1,0) OVER (partition by fileSource,pc.rte_dir order by pc.stop_seq) 
			  ,[mpc_initial_count]    = q.initial_count
			  ,lead(SCHED_DIST_FROM_LAST_GEO_NODE,1,0)  over (Partition by filesource order by pc.stop_seq) as MILES_TO_NEXT_GN
			  ,SCHED_DIST_FROM_LAST_GEO_NODE as MILES_FROM_LAST_GN
			  ,manualcount_load as mpc_load
			  ,mpc_pass_miles_to_next_stop = manualcount_load * SCHED_DIST_FROM_LAST_GEO_NODE
			  ,mpc_pass_miles_from_last_stop = manualcount_load * SCHED_DIST_FROM_LAST_GEO_NODE 
			  ,pc.DEPARTURE_LOAD as DEPARTURE_LOAD
			  ,pc.DEPARTURE_LOAD DepartureLoadContinuous
			  ,cast(SCHED_DIST_FROM_LAST_GEO_NODE as float) as distanceforcalc
			  ,passenger_miles_by_tm = passenger_miles
			  ,passenger_miles_by_tm_rt = sum(passenger_miles) over (Partition by filesource order by pc.stop_seq)
			  ,new_pc_pass_miles =  pc.DEPARTURE_LOAD * SCHED_DIST_FROM_LAST_GEO_NODE 
			  ,[apc_ons]              = isnull(q.ons_f, 0) + isnull(q.ons_m, 0) + isnull(q.ons_r, 0) 
			  ,[apc_offs]             = isnull(q.offs_f, 0) + isnull(q.offs_m, 0) + isnull(q.offs_r, 0) 
			  ,[pc_ons]               = pc.board
			  ,[pc_offs]              = pc.alight
			  ,[apc_time_f]           = q.time_f
			  ,[apc_ons_f]            = q.ons_f
			  ,[apc_offs_f]           = q.offs_f
			  ,[apc_notes_f]          = q.notes_f
			  ,[apc_time_m]           = q.time_m
			  ,[apc_ons_m]            = q.ons_m
			  ,[apc_offs_m]           = q.offs_m
			  ,[apc_notes_m]          = q.notes_m
			  ,[apc_time_r]           = q.time_r
			  ,[apc_ons_r]            = q.ons_r
			  ,[apc_offs_r]           = q.offs_r
			  ,[apc_notes_r]          = q.notes_r 
			  ,[Mode]
		  from #tmpPC2 pc
		 full outer join 
				(select a.*, 
			   [surveyor_name_f]  = ISNULL([dbo].[fn_GetFullName_FirstMLast](sf.first_name,sf.middle_name,sf.last_name), '*** no match ***')
			  ,[surveyor_name_m]  = ISNULL([dbo].[fn_GetFullName_FirstMLast](sm.first_name,sm.middle_name,sm.last_name), '*** no match ***')
			  ,[surveyor_name_r]  = ISNULL([dbo].[fn_GetFullName_FirstMLast](sr.first_name,sr.middle_name,sr.last_name), '*** no match ***')
				 from #mpc a 
				  left join -- select * from
					#badgenm sf WITH (NOLOCK) on ltrim(rtrim(sf.employee_id)) = rtrim(a.surveyor_badge_f) 
				  left join #badgenm sm WITH (NOLOCK) on ltrim(rtrim(sm.employee_id)) = rtrim(a.surveyor_badge_m) 
				  left join #badgenm sr WITH (NOLOCK) on ltrim(rtrim(sr.employee_id)) = rtrim(a.surveyor_badge_r) ) q
		 on q.calendar_id = pc.CALENDAR_ID
		 and q.ROUTE_DIRECTION_ID = pc.ROUTE_DIRECTION_ID
		 and q.ROUTE_ID = pc.ROUTE_ID
		 and q.stop_no = pc.stop_no 
		 and pc.pc_trip_end =q.trip_end
		 where filesource is not null --and pc.stop_no is not null
		 ) x
		 WHERE ISNUMERIC(left(x.stop_no,1)) = 1
		) z
order by calendar_id, [pc_rte_dir],stop_seq, pc_trip_end, pc_time 
  
 END


  if @suppress = 0
  BEGIN
  insert #finalAPC
  select * , autocount_load =
case when rnbr = 1 then [mpc_initial_count]
	 when rnbr <> 1 
		and sum(pc_ons - pc_offs) OVER (PARTITION BY calendar_id,[pc_rte_dir],pc_trip_end  ORDER BY [stop_seq]) + [mpc_initial_count] < 0 then 0 
		else sum(pc_ons - pc_offs) OVER (PARTITION BY calendar_id,[pc_rte_dir],pc_trip_end  ORDER BY [stop_seq]) + [mpc_initial_count]
		end  
from (
  -- > GETTING DUPLICATES OUT OF THIS PART?  Next step.  Check it out.
  select *,
  sum(mpc_pass_miles_from_last_stop) OVER (Partition by left(filesource,11) order by pc_rte_dir desc, stop_seq)  mpc_pass_miles_from_last_stop_route
  ,sum(mpc_pass_miles_from_last_stop) OVER (Partition by filesource ORDER BY [stop_seq])  as mpc_miles_from_last_rt
  ,sum(passenger_miles_by_tm) OVER (PARTITION BY filesource ORDER BY [stop_seq]) apc_miles_rt
  ,sum(new_pc_pass_miles)  OVER (Partition by filesource ORDER BY [stop_seq]) apc_new_miles_rt
  ,rnbr = row_number() OVER (PARTITION BY filesource ORDER BY [stop_seq])
 from (
 select DISTINCT 
	   [survey_date]          = q.survey_date
	  ,fileSource
      ,[calendar_id]          = pc.calendar_id
      ,[pc_rte_dir]           = pc.rte_dir
      ,[pc_trip_end]          = pc_trip_end 
      ,[survey_trip]          = convert(varchar(32),q.survey_date,101) + ', ' + q.rte_dir + ', ' + q.trip_end
      ,[pc_bus]               = q.bus
      ,[apc_surveyor_badge_f] = q.surveyor_badge_f
      ,[apc_surveyor_name_f]  = q.surveyor_name_f
      ,[apc_surveyor_f]       = q.surveyor_name_f + '(' + q.surveyor_badge_f + ')'
      ,[apc_surveyor_badge_m] = q.surveyor_badge_m
      ,[apc_surveyor_name_m]  = q.surveyor_name_m
      ,[apc_surveyor_m]       = q.surveyor_name_m + '(' + q.surveyor_badge_m + ')'
      ,[apc_surveyor_badge_r] = q.surveyor_badge_r
      ,[apc_surveyor_name_r]  = q.surveyor_name_r
      ,[apc_surveyor_r]       = q.surveyor_name_r + '(' + q.surveyor_badge_r + ')'
      ,[apc_bus]              = q.bus
	  ,trip_stop_seq
      ,[stop_seq]             = pc.stop_seq
      ,[stop_no]              = pc.stop_no
      ,[stop_name]            = pc.stop_name
      ,[pc_time]              = pc_time
      ,[pc_odometer]          = pc.odometer 
	  ,last_odometer = lag(pc.odometer ,1,0) OVER (partition by fileSource,pc.rte_dir order by pc.stop_seq) 
      ,[mpc_initial_count]    = q.initial_count
	  ,lead(SCHED_DIST_FROM_LAST_GEO_NODE,1,0)  over (Partition by filesource order by pc.stop_seq) as MILES_TO_NEXT_GN
	  ,SCHED_DIST_FROM_LAST_GEO_NODE as MILES_FROM_LAST_GN
	  ,manualcount_load as mpc_load
	  ,mpc_pass_miles_to_next_stop = manualcount_load * SCHED_DIST_FROM_LAST_GEO_NODE
	  ,mpc_pass_miles_from_last_stop = manualcount_load * SCHED_DIST_FROM_LAST_GEO_NODE 
	  ,pc.DEPARTURE_LOAD as DEPARTURE_LOAD
	  ,pc.DEPARTURE_LOAD DepartureLoadContinuous
	  ,cast(SCHED_DIST_FROM_LAST_GEO_NODE as float) as distanceforcalc
	  ,passenger_miles_by_tm = passenger_miles
	  ,passenger_miles_by_tm_rt = sum(isnull(passenger_miles,0)) over (Partition by filesource order by pc.stop_seq)
	  ,new_pc_pass_miles =  pc.DEPARTURE_LOAD * SCHED_DIST_FROM_LAST_GEO_NODE 
	  ,[apc_ons]              = isnull(q.ons_f, 0) + isnull(q.ons_m, 0) + isnull(q.ons_r, 0) 
      ,[apc_offs]             = isnull(q.offs_f, 0) + isnull(q.offs_m, 0) + isnull(q.offs_r, 0) 
      ,[pc_ons]               = pc.board
      ,[pc_offs]              = pc.alight
      ,[apc_time_f]           = q.time_f
      ,[apc_ons_f]            = q.ons_f
      ,[apc_offs_f]           = q.offs_f
      ,[apc_notes_f]          = q.notes_f
      ,[apc_time_m]           = q.time_m
      ,[apc_ons_m]            = q.ons_m
      ,[apc_offs_m]           = q.offs_m
      ,[apc_notes_m]          = q.notes_m
      ,[apc_time_r]           = q.time_r
      ,[apc_ons_r]            = q.ons_r
      ,[apc_offs_r]           = q.offs_r
      ,[apc_notes_r]          = q.notes_r 
	  ,[Mode] -- select * 
  from #tmpPC2 pc
 full outer join 
		(select a.*, 
	   [surveyor_name_f]  = ISNULL([dbo].[fn_GetFullName_FirstMLast](sf.first_name,sf.middle_name,sf.last_name), '*** no match ***')
      ,[surveyor_name_m]  = ISNULL([dbo].[fn_GetFullName_FirstMLast](sm.first_name,sm.middle_name,sm.last_name), '*** no match ***')
      ,[surveyor_name_r]  = ISNULL([dbo].[fn_GetFullName_FirstMLast](sr.first_name,sr.middle_name,sr.last_name), '*** no match ***')
			 from #mpc a 
		  left join -- select * from 
		  #badgenm sf WITH (NOLOCK) on ltrim(rtrim(sf.employee_id)) = rtrim(a.surveyor_badge_f) 
		  left join #badgenm sm WITH (NOLOCK) on ltrim(rtrim(sm.employee_id)) = rtrim(a.surveyor_badge_m) 
		  left join #badgenm sr WITH (NOLOCK) on ltrim(rtrim(sr.employee_id)) = rtrim(a.surveyor_badge_r) ) q
 on q.calendar_id = pc.CALENDAR_ID
 and q.ROUTE_DIRECTION_ID = pc.ROUTE_DIRECTION_ID
 and q.ROUTE_ID = pc.ROUTE_ID
 and q.stop_no = pc.stop_no 
 and pc.pc_trip_end =q.trip_end
 where filesource is not null --and pc.stop_no is not null
	) x
 ) z
 order by calendar_id, pc_trip_end,[pc_rte_dir],stop_seq, pc_time 
  
 
 END

 
--UPDATE #finalAPC SET [fileSource] = REPLACE(REPLACE([fileSource],'\\ltd-glnfas2\Workgroup\SP&M\APC_Survey\2023\Survey_Data_Entry_Sheets_TEST_07102023\',''),'.xlsx','')
--UPDATE #finalAPC SET [fileSource] = REPLACE(REPLACE([fileSource],'\\ltd-glnfas2\Workgroup\SP&M\APC_Survey\2023\SurveyData2023\',''),'.xlsx','')

--\\ltd-glnfas2\Workgroup\SP&M\APC_Survey\2023\SurveyData2023\20221209_11_I_0913
 select Q.*,
e.exclude,
isnull(e.exclude_notes,'') exclude_notes,
 sum(q.ltd_load_miles) over (partition by Q.filesource ORDER BY [stop_seq]) ltd_load_miles_rt
into #outputFinal
from (
 select f.survey_date	,
f.fileSource	,
f.calendar_id	,
pc_rte_dir	,
f.pc_trip_end	,
survey_trip	,
pc_bus	,
apc_surveyor_badge_f	,
apc_surveyor_name_f	,
apc_surveyor_f	,
apc_surveyor_badge_m	,
apc_surveyor_name_m	,
apc_surveyor_m	,
apc_surveyor_badge_r	,
apc_surveyor_name_r	,
apc_surveyor_r	,
apc_bus	,
f.[Mode] ,
f.trip_stop_seq,
f.stop_seq	,
f.stop_no	,
f.stop_name	,
f.pc_time	,
pc_odometer	,
last_odometer	,
mpc_initial_count	,
MILES_TO_NEXT_GN	,
MILES_FROM_LAST_GN	,
mpc_load	,
mpc_pass_miles_to_next_stop	,
mpc_pass_miles_from_last_stop	,
f.DEPARTURE_LOAD	,
autocountload  ,
DepartureLoadContinuous	
,
    SUM(isnull(pc_ons,0)) OVER (PARTITION BY f.filesource ORDER BY f.[stop_seq]) LTD_ON,
	SUM(isnull(pc_offs,0)) OVER (PARTITION BY f.filesource ORDER BY f.[stop_seq]) LTD_OFF,
	case when sum(isnull(pc_ons,0) - isnull(pc_offs,0)) over (partition by f.filesource ORDER BY f.[stop_seq]) < 0 then 0 else	
		sum(isnull(pc_ons,0) - isnull(pc_offs,0)) over (partition by f.filesource ORDER BY f.[stop_seq]) end  ltd_load_rt,
    case when sum(isnull(pc_ons,0) - isnull(pc_offs,0)) over (partition by f.filesource ORDER BY f.[stop_seq]) <0 then 0 else	
		sum(isnull(pc_ons,0) - isnull(pc_offs,0)) over (partition by f.filesource ORDER BY f.[stop_seq]) * distanceforcalc end ltd_load_miles,
case when f.rnbr = 1 then isnull(q.BOARD,0) else isnull(pc_ons,0) end pc_ons	,
case when f.rnbr = 1 then 0 else isnull(pc_offs,0) end pc_offs	,
distanceforcalc	,
passenger_miles_by_tm	,
passenger_miles_by_tm_rt	,
new_pc_pass_miles	,
case when f.rnbr = 1 then (mp.[ons_f] + mp.[ons_r] + mp.[ons_m])
					else apc_ons end apc_ons	,
case when f.rnbr = 1 then 0 
					else apc_offs end apc_offs	,
apc_time_f	,
case when f.rnbr = 1 then isnull(mp.ons_f,0) else isnull(apc_ons_f,0) end apc_ons_f  ,        --[ons_f] + [ons_r] + [ons_m]) - ([offs_f] + [offs_r] + [offs_m] 
case when f.rnbr = 1 then 0 else isnull(apc_offs_f,0) end apc_off_f	,
apc_notes_f	,
apc_time_m	,
case when f.rnbr = 1 then isnull(mp.ons_m,0) else isnull(apc_ons_m,0) end apc_ons_m  ,        --[ons_f] + [ons_r] + [ons_m]) - ([offs_f] + [offs_r] + [offs_m] 
case when f.rnbr = 1 then 0 else isnull(apc_offs_m,0) end apc_off_m	,
apc_notes_m	,
apc_time_r	,
case when f.rnbr = 1 then isnull(mp.ons_r,0) else isnull(apc_ons_r,0) end apc_ons_r  ,        --[ons_f] + [ons_r] + [ons_m]) - ([offs_f] + [offs_r] + [offs_m] 
case when f.rnbr = 1 then 0 else isnull(apc_offs_r,0) end apc_off_r	,
apc_notes_r	,
mpc_pass_miles_from_last_stop_route	,
mpc_miles_from_last_rt	,
apc_miles_rt	,
apc_new_miles_rt	,
q.rnbr 	-- select * 
  from #finalAPC f
left join -- select * from 
#apcRow1 q on 
  q.calendar_id = f.CALENDAR_ID
 and q.rte_dir = f.pc_rte_dir
 and q.stop_no = f.stop_no 
 and q.pc_trip_end = f.pc_trip_end
 --and q.trip_stop_seq = f.stop_seq
 and f.rnbr = 1
left join #mpcRow1 mp on  mp.calendar_id = f.CALENDAR_ID
 and mp.rte_dir = f.pc_rte_dir
 and mp.stop_no = f.stop_no 
 and mp.trip_end = f.pc_trip_end
 --and q.trip_stop_seq = f.stop_seq
 and f.rnbr = 1
  ) q
   left join [apc].[apc_survey_trips_a] e WITH (NOLOCK) on e.fileSource = q.fileSource
   -- NOTE: where q.fileSource = '20191023_40_I_1155.xlsx' in this case the trip had a detour (created by dispatch) and this disconnected the trip sequences - choose trips for survey that don't have a detour.

select survey_date
     , fileSource
     , calendar_id
     , pc_rte_dir
     , pc_trip_end
     , survey_trip
     , pc_bus
     , apc_surveyor_badge_f
     , apc_surveyor_name_f
     , apc_surveyor_f
     , apc_surveyor_badge_m
     , apc_surveyor_name_m
     , apc_surveyor_m
     , apc_surveyor_badge_r
     , apc_surveyor_name_r
     , apc_surveyor_r
     , apc_bus
     , Mode
     , trip_stop_seq
     , stop_seq
     , stop_no
     , stop_name
     , pc_time
     , pc_odometer
     , last_odometer
     , mpc_initial_count
     , MILES_TO_NEXT_GN
     , MILES_FROM_LAST_GN
     , mpc_load
     , mpc_pass_miles_to_next_stop
     , mpc_pass_miles_from_last_stop
     , DEPARTURE_LOAD
     , autocountload
     , DepartureLoadContinuous
     , LTD_ON
     , LTD_OFF
     , ltd_load_rt
     , ltd_load_miles
     , pc_ons
     , pc_offs
     , distanceforcalc
     , passenger_miles_by_tm
     , passenger_miles_by_tm_rt
     , new_pc_pass_miles
     , apc_ons
     , apc_offs
     , apc_time_f
     , apc_ons_f
     , apc_off_f
     , apc_notes_f
     , apc_time_m
     , apc_ons_m
     , apc_off_m
     , apc_notes_m
     , apc_time_r
     , apc_ons_r
     , apc_off_r
     , apc_notes_r
     , mpc_pass_miles_from_last_stop_route
     , mpc_miles_from_last_rt
     , apc_miles_rt
     , apc_new_miles_rt
     , rnbr
     , exclude
     , exclude_notes
     , ltd_load_miles_rt
from #outputFinal
   
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
             ,@recipients = 'barb.eichberger@ltd.org;servicedesk@ltd.org' 
             ,@subject = @sub
             ,@body = @errormsg;

       RAISERROR (
                    @errormsg
                    ,@errsev
                    ,1
                    )
END CATCH
GO
