SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [nf].[Vehicle_Sched_vs_Actual_Miles_and_Minutes]  AS

/* 
  PURPOSE: maintains data populated in rpt.[transTrack_Sched_vs_Actual_Miles_Time] - Prepared data for transtrack.
   AUTHOR: beichberger
     DATE: 20210706

   exec [nf].[Vehicle_Sched_vs_Actual_Miles_and_Minutes] 

------------------LTD_GLOSSARY---------------
UPDATED BY:	Sopheap Suy
UPDATED DT:  10/31/2024
purpose	 :  Add object activities on who, what, when call this object
			write this data to aud.object_activity table everytime it's called */
SET FMTONLY OFF; 
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

declare @workstartdt datetime2 = sysdatetime()

declare @stdt datetime2 = (select isnull(min(stdt),'7/1/2020') stdt from (
							select CAST(RIGHT(MAX(calendar_id),8)  AS date) stdt from [ltd_dw].[nf].[Vehicle_Sched_vs_Actual_Miles_Time] WITH (NOLOCK)
							union 
							select CAST(RIGHT(MAX(calendar_id),8)  AS date)  from [ltd_dw].[nf].[Vehicle_Sched_vs_Actual_Miles_Time] WITH (NOLOCK)) o )
declare @stdtint int = (select convert(varchar(32), @stdt, 112) + 100000000)


declare @lastdt date 
 select @lastdt = (select DATEADD(DAY,-2,GETDATE()))

DECLARE @StartDate  date = @stdt ;

DECLARE @CutoffDate date = @lastdt

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
SELECT rn = row_number() over (order by thedate),* 
into #dttable
FROM src
  ORDER BY TheDate
  OPTION (MAXRECURSION 0);

  -- select * from #dttable

  declare @i int 
  declare @r int
  declare @currdtInt INT
  select @i = 1
  select @r = (select max(rn) from #dttable)

while @i <= @r
BEGIN
select @currdtInt = (select calendar_id from #dttable where rn = @i)


IF (SELECT COUNT(*) FROM tempdb.sys.tables WHERE name LIKE '%sch9100%') <> 0
BEGIN
DROP TABLE #sch9100
END

IF (SELECT COUNT(*) FROM tempdb.sys.tables WHERE name LIKE '%actu9100%') <> 0
BEGIN
DROP TABLE #actu9100
END

IF (SELECT COUNT(*) FROM tempdb.sys.tables WHERE name LIKE '%prepdate9100%') <> 0
BEGIN
DROP TABLE #prepdate9100
END

IF (SELECT COUNT(*) FROM tempdb.sys.tables WHERE name LIKE '%OutputTbl9977%') <> 0
BEGIN
DROP TABLE #OutputTbl9977
END

SELECT @workstartdt = sysdatetime();

select [calendar_id]
	  ,s.TIME_TABLE_VERSION_ID
      ,s.ROUTE_ID
	  ,s.ROUTE_DIRECTION_ID
      ,s.REVENUE_ID
      ,st.service_type_id
	  ,s.IS_LAYOVER
	  ,s.pattern_id
      ,s.block_id
	  ,t.trip_id
	  ,t.TRIP_END_TIME
	  ,s.VEHICLE_ID
	  ,[sched_time] = tm.convert_passing_time(s.SCHEDULED_TIME) 
      ,s.SCHEDULE_ADJUSTMENT
      ,s.CANCELLED
	  ,s.OPERATOR_ID
	  ,svc = case when st.SERVICE_TYPE_TEXT like '%w%' then 'Wkd' else left(st.SERVICE_TYPE_TEXT, 3) end
       INTO -- select * from 
	   #prepdate9100
	   FROM          [ltd-tmdata].tmdatamart.dbo.schedule				   s WITH (NOLOCK)
		   left join [ltd-tmdata].tmmain.dbo.trip				           t WITH (NOLOCK)  on t.trip_id             = s.trip_id AND t.TIME_TABLE_VERSION_ID = s.TIME_TABLE_VERSION_ID
		   left join [ltd-tmdata].tmdatamart.dbo.service_type             st WITH (NOLOCK)  on st.service_type_id    = s.service_type_id 
   where calendar_id =  @currdtInt -- 120200701 --
		and s.REVENUE_ID in ('r','d')
		AND s.TIME_TABLE_VERSION_ID IS NOT NULL
        AND s.TRIP_ID IS NOT null

select 
	q.calendar_id
,	q.time_table_version_id
,	q.ROUTE_ID
,   q.route_direction_id
,	q.REVENUE_ID
,	q.SERVICE_TYPE_ID
,	q.IS_LAYOVER
,	q.pattern_id
,	q.BLOCK_ID
,	q.TRIP_ID
,	q.TRIP_END_TIME
,	q.vehicle_id
,	q.sched_time
,	q.OPERATOR_ID
,	q.SCHEDULE_ADJUSTMENT 
,	q.cancelled
,	q.svc
,	[sched_rev_miles] = SUM(CAST(case when gni.USE_MAP = 1 then gni.DISTANCE_BETWEEN_MAP else gni.DISTANCE_BETWEEN_MEASURED END AS decimal(12,3))) / 5280.00  
INTO -- select * from 
#sch9100
FROM #prepdate9100 q
   INNER join [ltd-tmdata].tmmain.dbo.pattern_geo_interval_xref   pgix WITH (NOLOCK) on pgix.pattern_id = q.pattern_id and pgix.Time_Table_Version_ID = q.TIME_TABLE_VERSION_ID
   INNER join [ltd-tmdata].tmmain.dbo.geo_node_interval           gni WITH (NOLOCK) on gni.INTERVAL_ID = pgix.Geo_Node_Interval_ID
group by 
	q.calendar_id
,	q.time_table_version_id
,	q.ROUTE_ID
,   q.route_direction_id
,	q.REVENUE_ID
,	q.SERVICE_TYPE_ID
,	q.IS_LAYOVER
,	q.pattern_id
,	q.BLOCK_ID
,	q.TRIP_ID
,	q.TRIP_END_TIME
,	q.vehicle_id
,	q.sched_time
,	q.OPERATOR_ID
,	q.SCHEDULE_ADJUSTMENT
,	q.cancelled
,	q.svc


select [calendar_id] 
	  ,v.time_table_version_id
	  ,vehicle_id
      ,route_id
	  ,route_direction_id
      ,v.pattern_id  
	  ,v.trip_id
	  ,t.TRIP_END_TIME
	  ,v.block_id   
      ,[trip_mins]   = cast(round((max(actual_arrival_time) - min(actual_departure_time)) / 60.0, 2) as numeric(9, 2))
      ,[trip_miles]  = max(odometer) - min(odometer)
	  ,operator_id
  into -- select * from 
  #actu9100 -- select *  
  from [ltd-tmdata].tmdatamart.dbo.adherence v
  LEFT join [ltd-tmdata].tmmain.dbo.trip t WITH (NOLOCK) on t.trip_id = v.trip_id AND v.TIME_TABLE_VERSION_ID = t.TIME_TABLE_VERSION_ID AND t.Pattern_ID = v.PATTERN_ID	   
  where calendar_id =@currdtInt -- 120200701 --  
   and adherence is not null
   and v.trip_id is not null
   and v.REVENUE_ID = 'R'
   AND v.TIME_TABLE_VERSION_ID IS NOT NULL	
 group by [calendar_id] ,v.time_table_version_id
	  ,vehicle_id
      ,route_id
	  ,route_direction_id
      ,v.pattern_id  
	  ,v.trip_id
	  ,t.TRIP_END_TIME
	  ,v.block_id   
      ,v.operator_id

 
create table #OutputTbl9977 (ActionName varchar(32))

insert [nf].[Vehicle_Sched_vs_Actual_Miles_Time] (
	   [calendar_id]
	  ,[time_table_version_id]
      ,[vehicle_id]
      ,[route_id]
      ,[route_direction_id]
      ,[pattern_id]
      ,[trip_id]
	  ,TRIP_END_TIME
      ,[block_id]
      ,[trip_mins]
      ,[trip_miles]
      ,[trip_operator_id]
      ,[svc]
      ,[sched_rev_miles])
OUTPUT 'INSERTED' into #OutputTbl9977
select a.[calendar_id]
	  ,a.[time_table_version_id]
      ,a.[vehicle_id]
      ,a.[route_id]
      ,a.[route_direction_id]
      ,a.[pattern_id]
      ,a.[trip_id]
	  ,a.TRIP_END_TIME
      ,a.[block_id]
      ,a.[trip_mins]
      ,a.[trip_miles]
      ,a.[operator_id]
      ,s.[svc]
      ,s.[sched_rev_miles]
from -- select * from 
#actu9100 a 
join #sch9100 s on s.BLOCK_ID = a.block_id
		and s.[pattern_id] = a.[pattern_id]
		and s.route_id = a.route_id
		AND s.route_direction_id = a.ROUTE_DIRECTION_ID
		and s.TRIP_ID = a.trip_id
		AND s.vehicle_id = a.VEHICLE_ID
		AND s.time_table_version_id = a.time_table_version_id
WHERE s.TIME_TABLE_VERSION_ID IS NOT NULL 
AND a.TIME_TABLE_VERSION_ID IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM [nf].[Vehicle_Sched_vs_Actual_Miles_Time] x
				WHERE a.BLOCK_ID = x.block_id
				AND a.CALENDAR_ID = x.CALENDAR_ID
				and a.[pattern_id] = x.[pattern_id]
				and a.route_id = x.route_id
				AND a.route_direction_id = x.ROUTE_DIRECTION_ID
				and a.TRIP_ID = x.trip_id
				AND a.TRIP_END_TIME = x.trip_end_time
				AND a.vehicle_id = x.VEHICLE_ID
				AND a.time_table_version_id = x.time_table_version_id)


declare @n int = (select isnull(count(*),0) from #OutputTbl9977 WITH (NOLOCK) where ActionName = 'INSERTED' group by ActionName )


-- clean up merge log in case some previous processing did not complete
update ltd_dw.[process].[MergeLogs]
SET [recInsert] = 0
,recDelete = 0
,recUpdate = 0 
,MergeEndDatetime = @workstartdt
where [MergeBeginDatetime] is not null 
and MergeEndDatetime is null 
and MergeCode = 'TTMI'
and [ObjectDestination] = 'ltd_dw.rpt.transTrack_Sched_vs_Actual_Miles_Time'


 insert ltd_dw.[process].[MergeLogs] (
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
	  'TTMI', 'ltd_dw.rpt.transTrack_Sched_vs_Actual_Miles_Time','TM','ltd_dw.rpt.transTrack_Sched_vs_Actual_Miles_and_Minutes',isnull(@n,0), 0, 0, @workstartdt, sysdatetime())




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

       EXEC msdb.dbo.sp_send_dbmail @profile_name = @profile
             ,@recipients = 'barb.eichberger@ltd.org' --;servicedesk@ltd.org
             ,@subject = @sub
             ,@body = @errormsg;

       RAISERROR (
                    @errormsg
                    ,@errsev
                    ,1
                    )
END CATCH
GO
