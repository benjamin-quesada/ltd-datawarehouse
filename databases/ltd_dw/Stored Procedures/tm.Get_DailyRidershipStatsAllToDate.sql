SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE   PROCEDURE [tm].[Get_DailyRidershipStatsAllToDate]

AS
BEGIN

-- =============================================
-- Author:		B. Eichberger
-- Create date: 12/14/2018
-- Description:	Adapted from Crystal Report "Daily Ridership Recap.rdl" Query ntd_stats for use in summarized centralized and long term stored ntd stats.  Is a merge statement in the case there is a data anomaly, fixes are manually applied and or a recount is made of any sort in the system, we can get record of that having changed.
-- Use        : Use when there's time to review all the data or to load it from day 1st available in transactional system.
-- Exec Sample: exec tm.Get_DailyRidershipStatsAllToDate
-- to do: decode ltd_distance_between function and determine best future location 
-- to do: decode ntd_stats table source/load method, determine best future location
-- =============================================

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



declare @enddtKey INT = convert(varchar(32),getdate(), 112) + 100000000

if (select count(*) from sys.tables where name = 'ntd_daily_ridership_stats') = 0 
BEGIN
CREATE TABLE [tm].[ntd_daily_ridership_stats](
	ntd_daily_ridership_stat_ID INT identity(1,1) NOT NULL,
	[calendar_id] [int] NOT NULL,
	[service_type] [varchar](8) NULL,
	[boardings] [int] NULL,
	[passenger_miles] [int] NULL,
	[mobility_assisted_boardings] [int] NULL,
	[special_event_boardings] [int] NULL,
	[sched_rev_hours] [int] NULL,
	[actual_rev_hours] [int] NULL,
	[sched_rev_miles] [int] NULL,
	[sched_total_miles] [int] NULL,
	[actual_rev_miles] [int] NULL,
	[sched_in_service_hours] [int] NULL,
	[sched_total_hours] [int] NULL,
	[actual_in_service_hours] [int] NULL,
	[actual_total_hours] [int] NULL,
	[record_create_date] datetime default sysdatetime() ,
	[record_update_date] datetime
) ON [PRIMARY]
END

select n.calendar_id
	, c.service_type
	, boardings = sum(boardings)
	, passenger_miles = sum(passenger_miles)
	, mobility_assisted_boardings = mobility_boardings
	, special_event_boardings = special_event_boarding
	, sched_rev_hours = sum(sched_rev_hours)
	, actual_rev_hours = sum(actual_rev_hours) 
	, sched_rev_miles = sum(sched_rev_miles)
	, sched_total_miles = sum(sched_total_miles)
	, actual_rev_miles = sum(actual_rev_miles)
	, sched_in_service_hours = sum(sched_in_service_hours)
	, sched_total_hours = sum(sched_total_hours)
	, actual_in_service_hours = sum(actual_in_service_hours)
	, actual_total_hours = sum(actual_total_hours)
	into ##tmpDailyRides
	from [LTD-TMDATA].ltd_db.dbo.ntd_stats n
	JOIN [LTD-TMDATA].ltd_db.dbo.ltd_service_day_type_per_calendar_id_from_tmmain c on c.calendar_id = n.calendar_id
	JOIN (select sum(mc_qty_capped) mobility_assisted_boardings, Calendar_ID 
			 FROM [LTD-TMDATA].[ltd_db].[dbo].[manual_passenger_count_v] p 
			 WHERE p.mc_short_desc in ('ma', 'wc on') 
			 group by calendar_id ) m on m.calendar_id = n.calendar_id
	left outer join  
	  (select calendar_id, mobility_boardings = sum(mc_qty_capped)
	  FROM [LTD-TMDATA].[ltd_db].[dbo].[manual_passenger_count_v]
	  where mc_short_desc in ('ma', 'wc on')
			and calendar_id < @enddtKey
	  group by calendar_id ) wc on wc.calendar_id = n.calendar_id
	left outer join 
	  (  select  calendar_id
	  --,sp_place
	  , special_event_boarding = sum(board)
	  FROM [LTD-TMDATA].[ltd_db].[dbo].passenger_count_raw_v
	  where sp_place not in ('Garage')
			and calendar_id < @enddtKey
	  group by calendar_id --,sp_place 
	  ) sp on sp.calendar_id = n.calendar_id
	where n.calendar_id < @enddtKey
	group by n.calendar_id,c.service_type,mobility_boardings,special_event_boarding
	
	;
MERGE [tm].[ntd_daily_ridership_stats] as t
USING ##tmpDailyRides as s
ON t.calendar_id = s.calendar_id

WHEN NOT MATCHED BY TARGET THEN
INSERT (
	   [calendar_id]
      ,[service_type]
      ,[boardings]
      ,[passenger_miles]
      ,[mobility_assisted_boardings]
	  ,[special_event_boardings]
      ,[sched_rev_hours]
      ,[actual_rev_hours]
      ,[sched_rev_miles]
      ,[sched_total_miles]
      ,[actual_rev_miles]
      ,[sched_in_service_hours]
      ,[sched_total_hours]
      ,[actual_in_service_hours]
      ,[actual_total_hours]
)
VALUES (
	   [calendar_id]
      ,[service_type]
      ,[boardings]
      ,[passenger_miles]
      ,[mobility_assisted_boardings]
	  ,[special_event_boardings]
      ,[sched_rev_hours]
      ,[actual_rev_hours]
      ,[sched_rev_miles]
      ,[sched_total_miles]
      ,[actual_rev_miles]
      ,[sched_in_service_hours]
      ,[sched_total_hours]
      ,[actual_in_service_hours]
      ,[actual_total_hours]
	 ) 
WHEN MATCHED AND
		 s.[service_type] <> t.[service_type]
      OR s.[boardings] <> t.[boardings]
      OR s.[passenger_miles] <> t.[passenger_miles]
      OR s.[mobility_assisted_boardings] <> t.[mobility_assisted_boardings]
      OR s.[special_event_boardings] <> t.[special_event_boardings]
      OR s.[sched_rev_hours] <> t.[sched_rev_hours]
      OR s.[actual_rev_hours] <> t.[actual_rev_hours]
      OR s.[sched_rev_miles] <> t.[sched_rev_miles]
      OR s.[sched_total_miles] <> t.[sched_total_miles]
      OR s.[actual_rev_miles] <> t.[actual_rev_miles]
      OR s.[sched_in_service_hours] <> t.[sched_in_service_hours]
      OR s.[sched_total_hours] <> t.[sched_total_hours]
      OR s.[actual_in_service_hours] <> t.[actual_in_service_hours]
      OR s.[actual_total_hours] <> t.[actual_total_hours]
	THEN UPDATE
	 SET t.[service_type] = s.[service_type]
      , t.[boardings] = s.[boardings]
      , t.[passenger_miles] = s.[passenger_miles]
      , t.[mobility_assisted_boardings] = s.[mobility_assisted_boardings]
      , t.[special_event_boardings] = s.[special_event_boardings]
      , t.[sched_rev_hours] = s.[sched_rev_hours]
      , t.[actual_rev_hours] = s.[actual_rev_hours]
      , t.[sched_rev_miles] = s.[sched_rev_miles]
      , t.[sched_total_miles] = s.[sched_total_miles]
      , t.[actual_rev_miles] = s.[actual_rev_miles]
      , t.[sched_in_service_hours] = s.[sched_in_service_hours]
      , t.[sched_total_hours] = s.[sched_total_hours]
      , t.[actual_in_service_hours] = s.[actual_in_service_hours]
      , t.[actual_total_hours] = s.[actual_total_hours]
	  , t.[record_update_date] = sysdatetime()
	;

if (select count(*) from sys.tables where name = 'ntd_passenger_boarding_rolling_avg') <> 0
BEGIN
DROP TABLE [tm].[ntd_passenger_boarding_rolling_avg]
END

--DROP TABLE [tm].[ntd_passenger_boarding_rolling_avg]
if (select count(*) from sys.tables where name = 'ntd_passenger_boarding_rolling_avg') = 0
BEGIN
CREATE TABLE [tm].[ntd_passenger_boarding_rolling_avg](
	YearMoOrder int not null,
	[MonthStart_ID] int not null,
	[boardings] [int] NULL,
	[rolling_avg_passenger_boarding6] [int] NULL,
	[rolling_avg_passenger_boarding12] [int] NULL
) ON [PRIMARY]
END

INSERT tm.ntd_passenger_boarding_rolling_avg	

select Q.rnbr, (cast(Q.year as varchar(12)) + right('00'+cast(Q.month as varchar(12)),2)+'01')+100000000 as MonthStart_ID
,Q.MonthBoardings
, [rolling_avg_passenger_boarding] = avg(MonthBoardings) OVER (Partition by 1 ORDER BY  Q.Year,Q.Month ROWS BETWEEN 7 PRECEDING AND 1 PRECEDING)
, [rolling_avg_passenger_boarding12] = avg(MonthBoardings) OVER (Partition by 1 ORDER BY  Q.Year,Q.Month ROWS BETWEEN 13 PRECEDING AND 1 PRECEDING)
from  (
select rnbr = ROW_NUMBER() over (Partition by 1 order by dc.Year, dc.Month),
dc.year,dc.Month, dc.YearMonth, sum(boardings) MonthBoardings
from [tm].[ntd_daily_ridership_stats] st
	join tm.DW_CALENDAR dc on dc.CALENDAR_ID = st.calendar_id
group by dc.year,dc.Month, dc.YearMonth ) Q	
--Where YearMonth < cast( year(getdate()) as varchar(32)) + right('00' + cast(datepart(month,getdate()) as varchar(3)),2)
--  and YearMonth > cast(year(getdate())-6 as varchar(32)) + '12'
  order by rnbr

	

if (select count(*) from tempdb.sys.tables where name like '%tmpDailyRides%') <> 0 
BEGIN
DROP TABLE ##tmpDailyRides
END


END
GO
