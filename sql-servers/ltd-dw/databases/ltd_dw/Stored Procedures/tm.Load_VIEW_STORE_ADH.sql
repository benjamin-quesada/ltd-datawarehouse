SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE procedure [tm].[Load_VIEW_STORE_ADH]
as
-- exec tm.[Load_VIEW_STORE_ADH]
set nocount on;

  DECLARE @SPROC VARCHAR(100)
  SET @SPROC = OBJECT_SCHEMA_NAME(@@PROCID) + '.' + OBJECT_NAME(@@PROCID)

--CREATE columnstore INDEX ix_ccs_view_store_adh_adherence_id ON tm.VIEW_STORE_ADH (adherence_id) on NewFlyer
--CREATE columnstore INDEX ix_ccs_view_store_pass_passenger_count_id ON tm.VIEW_STORE_PASS (passenger_count_id) on NewFlyer


BEGIN TRY


drop TABLE IF exists #ADHoutputtbl 
create TABLE #ADHoutputtbl (adherence_id BIGINT NOT null)


insert into [tm].VIEW_STORE_ADH
           ([adherence_id]
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
           ,[trip_end_sql]
           ,[sched]
           ,[sched_sql]
           ,[sched_spm]
           ,[actual_arrival_spm]
           ,[actual_departure_spm]
           ,[arrive]
           ,[arrive_sql]
           ,[depart]
           ,[depart_sql]
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
		   ,[actual_dwell]
		   ,actual_int_plus_dwell
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
           ,[valid_position])
OUTPUT inserted.adherence_id INTO #ADHoutputtbl(adherence_id)
select s.[adherence_id]
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
           ,[trip_end_sql]
           ,[sched]
           ,[sched_sql]
           ,[sched_spm]
           ,[actual_arrival_spm]
           ,[actual_departure_spm]
           ,[arrive]
           ,[arrive_sql]
           ,[depart]
           ,[depart_sql]
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
		   ,[actual_dwell]
		   ,actual_int_plus_dwell
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
from [ltd-tmdata].ltd_db.dbo.VIEW_STORE_ADH_Stage s
WHERE NOT EXISTS (SELECT 1 FROM tm.VIEW_STORE_ADH WHERE adherence_id = s.adherence_id)
OPTION (MAXDOP 2)


INSERT [ltd-tmdata].ltd_db.[Wrk].[ADH_dwadh] (adherence_id)
SELECT adherence_id FROM #ADHoutputtbl l
WHERE NOT EXISTS (SELECT adherence_id FROM [ltd-tmdata].ltd_db.[Wrk].[ADH_dwadh] d WITH (NOLOCK)
					WHERE l.adherence_id = d.adherence_id);


DELETE p 
FROM [ltd-tmdata].ltd_db.dbo.VIEW_STORE_ADH_Stage p
JOIN #ADHoutputtbl o ON o.adherence_id = p.adherence_id



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
             ,@recipients = 'barb.eichberger@ltd.org' 
             ,@subject = @sub
             ,@body = @errormsg;

       RAISERROR (
                    @errormsg
                    ,@errsev
                    ,1
                    )
END CATCH


GO
