SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE   PROCEDURE [rpt].[actual_trip_times_tidy] 
@startDate date ,@endDate date 

as
/*
CREATED DT	: 20210715
AUTHOR		: B. Eichberger
PURPOSE		: A data source for a trip time analysis. Planning
USE			: exec rpt.actual_trip_times_tidy '1/1/2021','1/5/2021'

Permitted	: grant execute on [rpt].[actual_trip_times_tidy] to rpt_reader
			  grant execute on [rpt].[actual_trip_times_tidy] to "LTD\LTD_Data"

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

declare @calIdStart int
declare @calIdEnd int

select @calIdStart = (select 100000000 + cast(convert(varchar(32),@startDate,112) as INT))
select @calIdEnd = (select 100000000 + cast(convert(varchar(32),@endDate,112) as INT))


select *
,[trip_actual_len_mins]     = case when trip_complete = 0 then null else trip_actual_len_mins end
,[trip_len_actual_vs_sched] = case when trip_complete = 0 then null else trip_actual_len_mins - trip_sched_len_mins end
,[trip_len_pct_of_sched]    = case when trip_complete = 0 then null else trip_len_pct_of_sched end
,[trip_start_hhmmss]        = case when trip_complete = 0 then null else trip_start_hhmmss end
,[trip_end_hhmmss]          = case when trip_complete = 0 then null else trip_end_hhmmss end
,[trip_start_adhere_mins]   = case when trip_complete = 0 then null else trip_start_adhere_mins end
,[trip_end_adhere_mins]     = case when trip_complete = 0 then null else trip_end_adhere_mins end
,[trip_adherence_delta]     = case when trip_complete = 0 then null else trip_start_adhere_mins - trip_end_adhere_mins end
,[trip_actual_miles]        = case when trip_complete = 0 then null else isnull(trip_end_odometer, 0) - isnull(trip_start_odometer, 0) end
,[trip_actual_mph]          = case when trip_complete = 0 then null else cast(round((isnull(trip_end_odometer, 0) - isnull(trip_start_odometer, 0)) / (trip_actual_len_mins / 60.0), 1) as numeric(9, 1)) end 
from (
select calendar_id = a_ts.calendar_id
      ,the_date = sc.the_date
      ,bid = sc.bid
      ,ttv = sc.ttv
      ,srv_gen = sc.srv_gen
      ,[route] = rte.route_abbr
      ,rte_public = case when rte.route_abbr like '10[1-9]' then 'emx' else rte.route_abbr end
      ,dir = left(rd.route_direction_name, 1)
      ,rte_and_dir = rte.route_abbr + '-' + left(rd.route_direction_name, 1)
      ,rte_public_and_dir = case when rte.route_abbr in('101','102','103') then 'emx' else rte.route_abbr end + '-' + left(rd.route_direction_name, 1)
      ,rte_rural = case when rte.route_abbr is null or isnumeric(left(rte.route_abbr, 1)) = 0 then null else case when left(rte.route_abbr, 1) = '9' then 'rural' else 'non-rural' end end
      ,pattern = cast(p.pattern_abbr as int)
      ,tod_cat = case when t.trip_end_time <  7.5 * 3600 then '04:00-07:29'
                                       when t.trip_end_time <  9.5 * 3600 then '07:30-09:29'
                                       when t.trip_end_time < 11.5 * 3600 then '09:30-11:29'
                                       when t.trip_end_time < 14.5 * 3600 then '11:30-14:29'
                                       when t.trip_end_time < 17.5 * 3600 then '14:30-17:29'
                                       when t.trip_end_time < 20.5 * 3600 then '17:30-20:29'
                                       when t.trip_end_time < 24.0 * 3600 then '20:30-23:59'
                                       when t.trip_end_time < 27.5 * 3600 then '24:00-03:29'
                                       else '??' end
      ,trip_start_sched = tm.convert_passing_time(a_ts.scheduled_time)
      ,trip_end_sched = tm.convert_passing_time(t.trip_end_time)
      ,trip_sched_len_mins = cast((t.trip_end_time - a_ts.scheduled_time) / 60.0 as int)
      ,trip_start_tp = tp_ts.time_point_abbr
      ,trip_end_tp = tp_te.time_point_abbr
      ,trip_complete = case when (a_ts.actual_departure_time is null or a_te.actual_arrival_time is null) 
                                         or (a_ts.scheduled_time - a_ts.actual_departure_time > 10  * 60) 
                                         or (a_ts.scheduled_time - a_ts.actual_departure_time < -30 * 60) 
                                         or (a_te.scheduled_time - a_te.actual_arrival_time   > 10  * 60) 
                                         or (a_te.scheduled_time - a_te.actual_arrival_time   < -30 * 60) 
                                       then 0
                                       else 1 
                                  end
	  ,[trip_actual_len_mins]   = cast(round((a_te.actual_arrival_time - a_ts.actual_departure_time) / 60.0, 2) as numeric(9,2))
      ,[trip_len_pct_of_sched]  = cast(round(100.0 * (a_te.actual_arrival_time - a_ts.actual_departure_time) / (t.trip_end_time - a_ts.scheduled_time), 0) as int)
	  ,[trip_start_hhmmss]      = tm.convert_spm_to_hh_mm_ss(a_ts.actual_departure_time)
      ,[trip_end_hhmmss]        = tm.convert_spm_to_hh_mm_ss(a_te.actual_arrival_time)
	  ,[trip_start_adhere_mins] = cast(round((a_ts.scheduled_time - a_ts.actual_departure_time) / 60.0, 2) as numeric(9,2))
	  ,[trip_end_adhere_mins]   = cast(round((a_te.scheduled_time - a_te.actual_arrival_time)   / 60.0, 2) as numeric(9,2))
      ,[trip_start_odometer]    = cast(a_ts.odometer / 100.00 as numeric(9,2))
      ,[trip_end_odometer]      = cast(a_te.odometer / 100.00 as numeric(9,2))
      from      [ltd-tmdata].tmdatamart.dbo.adherence        a_ts 
 inner join     [ltd-tmdata].tmmain.dbo.time_table_version   ttv   on ttv.time_table_version_id = a_ts.time_table_version_id
 inner join		[ltd-tmdata].ltd_db.dbo.ltd_service_calendar_from_tmmain sc    on sc.calendar_id            = a_ts.calendar_id
 inner join     [ltd-tmdata].tmmain.dbo.[route]              rte   on rte.route_id              = a_ts.route_id
 inner join     [ltd-tmdata].tmmain.dbo.route_direction      rd    on rd.route_direction_id     = a_ts.route_direction_id
 inner join     [ltd-tmdata].tmmain.dbo.time_point           tp_ts on tp_ts.time_point_id       = a_ts.time_point_id
 inner join     [ltd-tmdata].tmmain.dbo.trip                 t     on t.trip_id                 = a_ts.trip_id
 inner join     [ltd-tmdata].tmmain.dbo.pattern              p     on p.pattern_id              = t.pattern_id
 inner join [ltd-tmdata].tmdatamart.dbo.adherence            a_te  on a_te.calendar_id          = a_ts.calendar_id and a_te.trip_id = a_ts.trip_id and a_te.scheduled_time = t.trip_end_time and a_te.overload_id = a_ts.overload_id
 inner join     [ltd-tmdata].tmmain.dbo.time_point           tp_te on tp_te.time_point_id       = a_te.time_point_id
 where isnumeric(left(rte.route_abbr, 1)) = 1
 and a_ts.calendar_id between @calidstart and @calIdEnd
   and t.trip_end_time is not null
   and a_ts.pattern_geo_node_seq = 1
   and a_ts.overload_id = 0
   and not (ttv.time_table_version_name = '1009b' and rte.route_abbr like '10[2-3]')
   ) o
   order by the_date,dir,trip_start_odometer


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
