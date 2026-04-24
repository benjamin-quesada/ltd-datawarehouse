SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE procedure [tm].[Load_VIEW_STORE_PASS]
as
-- exec tm.Load_VIEW_STORE_PASS
set nocount on;

  DECLARE @SPROC VARCHAR(100)
  SET @SPROC = OBJECT_SCHEMA_NAME(@@PROCID) + '.' + OBJECT_NAME(@@PROCID)


BEGIN TRY


drop TABLE IF exists #outputtbl 
create TABLE #outputtbl (passenger_count_id BIGINT NOT null)

 
insert into [tm].VIEW_STORE_PASS
      ([calendar_id]
      ,[calendar_date]
      ,[block]
      ,[block_numeric]
      ,[msg_time]
      ,[msg_time_spm]
      ,[msg_time_sql]
      ,[route]
      ,[dir]
      ,[rte_and_dir]
      ,[rte_public]
      ,[rte_rural]
      ,[emx_block]
      ,[rev_rte]
      ,[pattern_id]
      ,[pattern]
      ,[geo_node_id]
      ,[stop]
      ,[stop_name]
      ,[college]
      ,[brt_asso_stop]
      ,[brt_segment]
      ,[brt_seg_offs]
      ,[pc_latitude]
      ,[pc_longitude]
      ,[gn_latitude]
      ,[gn_longitude]
      ,[distance_delta_pc_and_gn]
      ,[operator_id]
      ,[badge]
      ,[operator_first]
      ,[operator_last]
      ,[operator]
      ,[operators_supervisor]
      ,[run]
      ,[the_bus]
      ,[veh]
      ,[bus_class]
      ,[artic]
      ,[electric]
      ,[emx_bus]
      ,[veh_text]
      ,[ttv_id]
      ,[ttv]
      ,[bid]
      ,[service_type_text]
      ,[service_type_general]
      ,[trip_id]
      ,[trip_sn]
      ,[trip_seq]
      ,[blk_trp_seq]
      ,[trip_end]
      ,[block_stop_order]
      ,[board]
      ,[alight]
      ,[run_load]
      ,[passenger_miles]
      ,[departure_load]
      ,[odometer]
      ,[overload_id]
      ,[revenue_id]
      ,[passenger_count_id]
      ,[pc_happened]
      ,[confidence]
      ,[confidence_between_100_and_1000_meters]
      ,[confidence_off_route]
      ,[confidence_out_of_sequence]
      ,[confidence_prior_tp_missed]
      ,[confidence_used_mobile_msgs_stop_offset]
      ,[time_point_id]
      ,[FIRST_DOOR_OPEN_TIME]
      ,[LAST_DOOR_CLOSED_TIME]
      ,[work_piece_id]
      ,[isOverload])
OUTPUT inserted.passenger_count_id INTO #outputtbl(passenger_count_id)
select 
[calendar_id]
      ,[calendar_date]
      ,[block]
      ,[block_numeric]
      ,[msg_time]
      ,[msg_time_spm]
      ,[msg_time_sql]
      ,[route]
      ,[dir]
      ,[rte_and_dir]
      ,[rte_public]
      ,[rte_rural]
      ,[emx_block]
      ,[rev_rte]
      ,[pattern_id]
      ,[pattern]
      ,[geo_node_id]
      ,[stop]
      ,[stop_name]
      ,[college]
      ,[brt_asso_stop]
      ,[brt_segment]
      ,[brt_seg_offs]
      ,[pc_latitude]
      ,[pc_longitude]
      ,[gn_latitude]
      ,[gn_longitude]
      ,[distance_delta_pc_and_gn]
      ,[operator_id]
      ,[badge]
      ,[operator_first]
      ,[operator_last]
      ,[operator]
      ,[operators_supervisor]
      ,[run]
      ,[the_bus]
      ,[veh]
      ,[bus_class]
      ,[artic]
      ,[electric]
      ,[emx_bus]
      ,[veh_text]
      ,[ttv_id]
      ,[ttv]
      ,[bid]
      ,[service_type_text]
      ,[service_type_general]
      ,[trip_id]
      ,[trip_sn]
      ,[trip_seq]
      ,[blk_trp_seq]
      ,[trip_end]
      ,[block_stop_order]
      ,[board]
      ,[alight]
      ,[run_load]
      ,[passenger_miles]
      ,[departure_load]
      ,[odometer]
      ,[overload_id]
      ,[revenue_id]
      ,s.[passenger_count_id]
      ,[pc_happened]
      ,[confidence]
      ,[confidence_between_100_and_1000_meters]
      ,[confidence_off_route]
      ,[confidence_out_of_sequence]
      ,[confidence_prior_tp_missed]
      ,[confidence_used_mobile_msgs_stop_offset]
      ,[time_point_id]
      ,[FIRST_DOOR_OPEN_TIME]
      ,[LAST_DOOR_CLOSED_TIME]
      ,[work_piece_id]
      ,[isOverload] -- select * 
from [ltd-tmdata].ltd_db.dbo.VIEW_STORE_PASS_Stage s
--WHERE NOT EXISTS (SELECT 1 FROM tm.VIEW_STORE_PASS WHERE passenger_count_id = s.passenger_count_id)
OPTION (MAXDOP 2)


INSERT [ltd-tmdata].ltd_db.[Wrk].[PASS_dwpass] (passenger_count_id)
SELECT passenger_count_id FROM #outputtbl l
WHERE NOT EXISTS (SELECT passenger_count_id FROM [ltd-tmdata].ltd_db.[Wrk].[PASS_dwpass] d WITH (NOLOCK)
					WHERE l.passenger_count_id = d.passenger_count_id)


DELETE p 
FROM [ltd-tmdata].ltd_db.dbo.VIEW_STORE_PASS_Stage p
JOIN #outputtbl o ON o.passenger_count_id = p.passenger_count_id



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
