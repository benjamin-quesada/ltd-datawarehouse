SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [tm].[z GET_PASSENGER_COUNT_AND_DOORS] as

/* -- CHANGE HISTORY ------------------------------------------

NAME				DATE INT	Ticket Order or Request Info
Barb Eichberger		20200810	RID-10255 - add column HHMMSS with greater granularity, with doors
Barb Eichberger		20200923	RID-10421 - on request of planning needs to have more flexibility and data access
											use view to begin populating additional data about passenger activity
											with the detail of this view. Possible future use as a fact table.
											Convert to stored procedure.
Barb Eichberger		20200930	RID-10421 - Change source to use doors first then plain _v no lock and limited to pc_happened = 'y'
											and passenger_count_id must match.

Barb Eichberger		20201020 			   - Typos fixed.
 
example: exec [tm].[GET_PASSENGER_COUNT_AND_DOORS]
*/----------------------------------------------------------


BEGIN TRY

SET FMTONLY OFF; 
SET NOCOUNT ON;




DECLARE @SPROC VARCHAR(100)
SET @SPROC = OBJECT_SCHEMA_NAME(@@PROCID) + '.' + OBJECT_NAME(@@PROCID)




declare @startdINT INT = (select convert(varchar(22),dateadd(day, -45,CONVERT(datetime,getdate())),112)+100000000 ) 			
declare @endINT INT = (select convert(varchar(22),getdate(),112)+100000000)



					  
declare @workstartdt datetime = sysdatetime() 
-- clean up merge log in case some previous processing did not complete
	update ltd_dw.[process].[MergeLogs]
	SET [recInsert] = 0
	,recDelete = 0
	,recUpdate = 0 
	,MergeEndDatetime = @workstartdt
	where [MergeBeginDatetime] is not null 
	and MergeEndDatetime is null 
	and MergeCode = 'PCOD'
	and [ObjectProgram] like 'ltd_dw.tm.GET_PASSENGER_COUNT_AND_DOORS%'
	and [ObjectDestination] = 'ltd_dw.rpt.PASSENGER_COUNT_V_OP_DOORS'




declare @startdate DATE = --'8/1/2020'
(select isnull(dateadd(day, -45,CONVERT(datetime,convert(char(8),calid ))),'7/1/2018') from 
							(select max(calendar_id)-100000000 calid from ltd_dw.[rpt].[PASSENGER_COUNT_V_OP_DOORS] WITH (NOLOCK) ) o )
declare @enddate DATE = (select cast(convert(varchar(22),getdate()-1) as date))


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
into #dtloops
FROM NUMS   NM ;

alter table #dtloops add out_int_fm as (cast(convert(varchar(22),out_date_fm, 112) as BIGINT)+100000000)
alter table #dtloops add out_int_to as (cast(convert(varchar(22),out_date_to, 112) as BIGINT)+100000000)

--select * from #dtloops order by out_date_FM

 --set up and loop
declare @i BIGINT = 0
declare @r BIGINT = (select max(rnbr) from #dtloops)
declare @loopNbr INT

declare @loopStart INT
declare @loopEnd INT



if (select count(*) from #dtloops) > 0
BEGIN

WHILE @i <= @r

BEGIN


select @loopStart = (select out_int_fm from #dtloops where rnbr = @i) 
select @loopEnd = (select out_int_to from #dtloops where rnbr = @i) 


if (select count(*) from tempdb.sys.tables where name like '%OutPCTbl9942%') > 0
BEGIN
drop table #OutPCTbl9942
END

if (select count(*) from tempdb.sys.tables where name like '%OutPCTbl9842%') > 0
BEGIN
drop table #OutPCTbl9842
END

if (select count(*) from tempdb.sys.tables where name like '%OutPCTbl9742%') > 0
BEGIN
drop table #OutPCTbl9742
END


if (select count(*) from tempdb.sys.tables where name like '%tmpHaveIDs%') > 0
BEGIN
drop table #tmpHaveIDs
END

create table #OutPCTbl9942 (passcount BIGINT)
create table #OutPCTbl9842 (passcount BIGINT)
create table #OutPCTbl9742 (passcount BIGINT)


select * into #tmpHaveIDs from (
	select 0 as passenger_count_id,0 as calendar_id
	union
	select passenger_count_id,calendar_id from [ltd-tmdata].ltd_db.dbo.passenger_count_v_nolock
		where calendar_id between @loopStart and @loopEnd
	) o


--insert ltd_dw.[process].[MergeLogs] (
--		   [MergeCode]
--		  ,[ObjectDestination]
--		  ,[ObjectSource]
--		  ,[ObjectProgram]
--		  ,[recInsert]
--		  ,[recUpdate]
--		  ,[recDelete]
--		  ,[MergeBeginDatetime]
--		  ,[MergeEndDateTime])
--		  Values(
--		  'PCDD', 'ltd_dw.rpt.PASSENGER_COUNT_V_OP_DOORS'
--				,'TM'
--				,'ltd_dw.tm.GET_PASSENGER_COUNT_AND_DOORS_'+cast(@loopStart as varchar(14))
--				,0, 0, isnull(@del,0), @workstartdt,sysdatetime())

	INSERT INTO [rpt].[PASSENGER_COUNT_V_OP_DOORS]
			   ([calendar_id]
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
			   ,[record_create_date])
	OUTPUT INSERTED.passenger_count_id into #OutPCTbl9942 (passcount)	 	
	SELECT d.[calendar_id]
		  ,d.[block]
		  ,d.[block_numeric]
		  ,d.[msg_time]
		  ,d.[msg_time_spm]
		  ,d.[msg_time_sql]
		  ,d.[route]
		  ,d.[dir]
		  ,d.[rte_and_dir]
		  ,d.[rte_public]
		  ,d.[rte_rural]
		  ,d.[emx_block]
		  ,d.[rev_rte]
		  ,d.[pattern_id]
		  ,d.[pattern]
		  ,d.[geo_node_id]
		  ,d.[stop]
		  ,d.[stop_name]
		  ,d.[college]
		  ,d.[brt_asso_stop]
		  ,d.[brt_segment]
		  ,d.[brt_seg_offs]
		  ,d.[pc_latitude]
		  ,d.[pc_longitude]
		  ,d.[gn_latitude]
		  ,d.[gn_longitude]
		  ,d.[distance_delta_pc_and_gn]
		  ,d.[operator_id]
		  ,d.[badge]
		  ,d.[operator_first]
		  ,d.[operator_last]
		  ,d.[operator]
		  ,d.[operators_supervisor]
		  ,d.[run]
		  ,d.[the_bus]
		  ,d.[veh]
		  ,d.[bus_class]
		  ,d.[artic]
		  ,d.[electric]
		  ,d.[emx_bus]
		  ,d.[veh_text]
		  ,d.[ttv_id]
		  ,d.[ttv]
		  ,d.[bid]
		  ,d.[service_type_text]
		  ,d.[service_type_general]
		  ,d.[trip_id]
		  ,d.[trip_sn]
		  ,d.[trip_seq]
		  ,d.[blk_trp_seq]
		  ,d.[trip_end]
		  ,d.[block_stop_order]
		  ,d.[board]
		  ,d.[alight]
		  ,d.[run_load]
		  ,d.[passenger_miles]
		  ,d.[departure_load]
		  ,d.[odometer]
		  ,d.[overload_id]
		  ,d.[revenue_id]
		  ,d.[passenger_count_id]
		  ,d.[pc_happened]
		  ,d.[confidence]
		  ,d.[confidence_between_100_and_1000_meters]
		  ,d.[confidence_off_route]
		  ,d.[confidence_out_of_sequence]
		  ,d.[confidence_prior_tp_missed]
		  ,d.[confidence_used_mobile_msgs_stop_offset]
		  ,d.[time_point_id]
		  ,d.[FIRST_DOOR_OPEN_TIME]
		  ,d.[LAST_DOOR_CLOSED_TIME]
		  ,sysdatetime()
	  FROM [ltd-TMDATA].ltd_db.[dbo].[passenger_count_v_nolock_doors] d
	  --JOIN [ltd-TMDATA].ltd_db.[dbo].[passenger_count_v] v on v.passenger_count_id = d.passenger_count_id
	  LEFT JOIN #tmpHaveIDs o on o.passenger_count_id = d.passenger_count_id
							 --and o.calendar_id = d.calendar_id
	  WHERE d.calendar_id >= @loopStart and d.calendar_id <= @loopEnd
	  and o.passenger_count_id is null 

	  
if (select count(*) from tempdb.sys.tables where name like '%tmpHaveID2%') > 0
BEGIN
drop table #tmpHaveID2
END

select * into #tmpHaveID2 from (
select  0 as passenger_count_id,0 as calendar_id
union
select passenger_count_id,calendar_id from [rpt].[PASSENGER_COUNT_V_OP_DOORS]
where calendar_id between @loopStart and @loopEnd) m


	  INSERT INTO [rpt].[PASSENGER_COUNT_V_OP_DOORS]
			   ([calendar_id]
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
			   ,[record_create_date])
	OUTPUT INSERTED.passenger_count_id into #OutPCTbl9842 (passcount)	 	
	SELECT d.[calendar_id]
		  ,d.[block]
		  ,d.[block_numeric]
		  ,d.[msg_time]
		  ,d.[msg_time_spm]
		  ,d.[msg_time_sql]
		  ,d.[route]
		  ,d.[dir]
		  ,d.[rte_and_dir]
		  ,d.[rte_public]
		  ,d.[rte_rural]
		  ,d.[emx_block]
		  ,d.[rev_rte]
		  ,d.[pattern_id]
		  ,d.[pattern]
		  ,d.[geo_node_id]
		  ,d.[stop]
		  ,d.[stop_name]
		  ,d.[college]
		  ,d.[brt_asso_stop]
		  ,d.[brt_segment]
		  ,d.[brt_seg_offs]
		  ,d.[pc_latitude]
		  ,d.[pc_longitude]
		  ,d.[gn_latitude]
		  ,d.[gn_longitude]
		  ,d.[distance_delta_pc_and_gn]
		  ,d.[operator_id]
		  ,d.[badge]
		  ,d.[operator_first]
		  ,d.[operator_last]
		  ,d.[operator]
		  ,d.[operators_supervisor]
		  ,d.[run]
		  ,d.[the_bus]
		  ,d.[veh]
		  ,d.[bus_class]
		  ,d.[artic]
		  ,d.[electric]
		  ,d.[emx_bus]
		  ,d.[veh_text]
		  ,d.[ttv_id]
		  ,d.[ttv]
		  ,d.[bid]
		  ,d.[service_type_text]
		  ,d.[service_type_general]
		  ,d.[trip_id]
		  ,d.[trip_sn]
		  ,d.[trip_seq]
		  ,d.[blk_trp_seq]
		  ,d.[trip_end]
		  ,d.[block_stop_order]
		  ,d.[board]
		  ,d.[alight]
		  ,d.[run_load]
		  ,d.[passenger_miles]
		  ,d.[departure_load]
		  ,d.[odometer]
		  ,d.[overload_id]
		  ,d.[revenue_id]
		  ,d.[passenger_count_id]
		  ,d.[pc_happened]
		  ,d.[confidence]
		  ,d.[confidence_between_100_and_1000_meters]
		  ,d.[confidence_off_route]
		  ,d.[confidence_out_of_sequence]
		  ,d.[confidence_prior_tp_missed]
		  ,d.[confidence_used_mobile_msgs_stop_offset]
		  ,d.[time_point_id]
		  ,sysdatetime()
	  FROM [ltd-TMDATA].ltd_db.[dbo].[passenger_count_v_nolock] d
	  --JOIN [ltd-TMDATA].ltd_db.[dbo].[passenger_count_v] v on v.passenger_count_id = d.passenger_count_id
	  LEFT JOIN #tmpHaveID2 o on o.passenger_count_id = d.passenger_count_id
							 --and o.calendar_id = d.calendar_id
	  WHERE d.calendar_id >= @loopStart and d.calendar_id <= @loopEnd
	  and o.passenger_count_id is null 

if ((select count(*) from tempdb.sys.tables where name like '%OutPCTbl9942%') + (select count(*) from tempdb.sys.tables where name like '%OutPCTbl9842%')) > 0
BEGIN


if (select count(*) from tempdb.sys.tables where name like '%goodPassIDs%') > 0
BEGIN
drop table #goodPassIDs
END

select * into #goodPassIDs from (
	select 0 as passenger_count_id,0 as calendar_id
	union
	select passenger_count_id,calendar_id from [ltd-tmdata].ltd_db.dbo.passenger_count_v_nolock
		where calendar_id between @loopStart and @loopEnd
	) o

DELETE from [rpt].[PASSENGER_COUNT_V_OP_DOORS]
OUTPUT deleted.passenger_count_id into #OutPCTbl9742
     WHERE calendar_id between @loopStart and @loopEnd
	   and passenger_count_id NOT IN (select passenger_count_id from #goodPassIDs)


declare @del INT = (select isnull(count(*),0) from #OutPCTbl9742)

declare @n int = (select isnull(count(*),0) from 
						(select * from #OutPCTbl9942 WITH (NOLOCK)
						union all
						 select * from #OutPCTbl9842 WITH (NOLOCK)  ) u)

	insert ltd_dw.[process].[MergeLogs] (
		   [MergeCode]
		  ,[ObjectDestination]
		  ,[ObjectSource]
		  ,[ObjectProgram]
		  ,[recInsert]
		  ,[recUpdate]
		  ,[recDelete]
		  ,[MergeBeginDatetime]
		  ,[MergeEndDateTime])
		  Values(
		  'PCOD', 'ltd_dw.rpt.PASSENGER_COUNT_V_OP_DOORS'
				,'TM'
				,'ltd_dw.tm.GET_PASSENGER_COUNT_AND_DOORS_'+cast(@loopStart as varchar(14))
				,isnull( @n, 0 ), 0, isnull(@del,0), @workstartdt,sysdatetime())



END

 
	select @i = @i + 1

	If @i > @r
		BREAK
		ELSE CONTINUE
	END

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
