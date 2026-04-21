SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE   PROCEDURE [tm].[merge_schedule]
AS
/*-----------LTD_GLOSSARY---------------
 created by	:  B Eichberger
 created dt	:  2025-02-23
 purpose	:  merge tm.schedule from ltd-tmdata.ltd_db.dbo.model_schedule_v
 use		:  exec [tm].[merge_schedule]

 changed by	:  B Eichberger
 changed dt	:  2025-08-12
 purpose	:  add vehicle and trip id (trip id will match umo data going forward from this point.
			   current matching will stay in place for legacy data though. Will add vehicle  
			   property tag rather than adjusting the json et al from the api
 use		:  exec [tm].[merge_schedule]


 changed by	:  B Eichberger
 changed dt	:  2025-10-08
 purpose	:  convert the OnRoute side to a stored procedure instead of a sproc 
			   remove the where exists - the merge should take care of that

 changed by	:  Sopheap
 changed dt	:  2026-01-22
 purpose	:  changing from min to max on calendar_id for @setdt

 changed by	:  Sopheap
 changed dt	:  2026-01-27
 purpose	:  change merge on clause to include  t.calendar_id >= @buildDt

 */

set nocount ON

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

declare @sdt datetime2 = sysdatetime()
declare @outputTbl table (actionNm varchar(32));
declare @setdt date = (select isnull(convert(date,cast(max(isnull(CALENDAR_ID,120200101))-100000000 as varchar(32))),'1/1/2020') from  [tm].[model_schedule])


declare @buildDt int = (select [dbo].[F_DATE_TO_CALENDAR_ID](dateadd(day,-10, @setdt))) -- 120180701 --
declare @endBuildDt int = (select [dbo].[F_DATE_TO_CALENDAR_ID](dateadd(day,-1, getdate()))) -- 120260112 -- 

exec [ltd-tmdata].ltd_db.dbo.model_schedule_p @buildDt, @endBuildDt	

drop table if exists wrk.schedprep
select sched_spm_route_stop_key
     , v.CALENDAR_ID
     , v.OPERATOR_ID
	 , v.TRIP_ID
     , TRIP_END_TIME
	 , d.year as MODEL_PARTITION 
     , VEHICLE_ID = isnull(VEHICLE_ID,0)
	 , v.PROPERTY_TAG
     , SERVICE_ABBR
     , SERVICE_TYPE_TEXT
     , TIME_POINT_ID
     , IsTimepoint
     , REVENUE_ID
     , ROUTE_ABBR
     , ROUTE_NAME
     , ROUTE_DIRECTION
     , ROUTE_DIRECTION_NAME
     , GEO_NODE_ABBR
     , GEO_NODE_NAME
     , OPERATOR_NAME
into wrk.schedprep
from [LTD-TMDATA].ltd_db.[model].[schedule_stage] v
join tm.DW_CALENDAR d on d.CALENDAR_ID = v.CALENDAR_ID


CREATE INDEX ix_schedprep ON wrk.schedprep 
    (sched_spm_route_stop_key, VEHICLE_ID, OPERATOR_ID, ROUTE_DIRECTION, REVENUE_ID, SERVICE_ABBR, TRIP_END_TIME)

merge [tm].[model_schedule] as t
using wrk.schedprep as s
on ( s.sched_spm_route_stop_key = t.sched_spm_route_stop_key
	and s.calendar_id = t.CALENDAR_ID
	and s.TRIP_ID = t.TRIP_ID
	and s.VEHICLE_ID = t.VEHICLE_ID
	and s.OPERATOR_ID = t.OPERATOR_ID
    and s.ROUTE_ABBR = t.ROUTE_ABBR
	and s.ROUTE_DIRECTION = t.ROUTE_DIRECTION
	and s.REVENUE_ID = t.REVENUE_ID
	and s.SERVICE_ABBR = t.SERVICE_ABBR
    and s.GEO_NODE_ABBR = t.GEO_NODE_ABBR
    and s.trip_end_time = t.trip_end_time 
    AND t.calendar_id >= @buildDt
    )
when matched and
(
   isnull (t.MODEL_PARTITION,0) <> isnull(s.MODEL_PARTITION,0)
or isnull (t.PROPERTY_TAG,'0') <> isnull(s.PROPERTY_TAG,'0')
or isnull (t.SERVICE_TYPE_TEXT,'0') <> isnull(s.SERVICE_TYPE_TEXT,'0')
or isnull (t.TIME_POINT_ID,0) <> isnull(s.TIME_POINT_ID,0)
or isnull (t.IsTimepoint,'0') <> isnull(s.IsTimepoint,'0')
or isnull (t.ROUTE_DIRECTION_NAME,'0') <> isnull(s.ROUTE_DIRECTION_NAME,'0')
or isnull (t.GEO_NODE_NAME,'0') <> isnull(s.GEO_NODE_NAME,'0')
or isnull (t.OPERATOR_NAME,'0') <> isnull(s.OPERATOR_NAME,'0')  )
then update set 
t.MODEL_PARTITION = s.MODEL_PARTITION 
,t.TRIP_END_TIME = s.TRIP_END_TIME
,t.SERVICE_TYPE_TEXT = s.SERVICE_TYPE_TEXT
,t.PROPERTY_TAG = s.PROPERTY_TAG
,t.TIME_POINT_ID = s.TIME_POINT_ID
,t.IsTimepoint = s.IsTimepoint
,t.ROUTE_DIRECTION_NAME = s.ROUTE_DIRECTION_NAME
,t.GEO_NODE_ABBR = s.GEO_NODE_ABBR
,t.GEO_NODE_NAME = s.GEO_NODE_NAME
,t.OPERATOR_NAME = s.OPERATOR_NAME
,t.record_updated_date = sysdatetime()
when not matched by target then insert (
	sched_spm_route_stop_key
     , CALENDAR_ID
     , OPERATOR_ID
	 , TRIP_ID
     , TRIP_END_TIME
	 , MODEL_PARTITION 
     , VEHICLE_ID
	 , PROPERTY_TAG
     , SERVICE_ABBR
     , SERVICE_TYPE_TEXT
     , TIME_POINT_ID
     , IsTimepoint
     , REVENUE_ID
     , ROUTE_ABBR
     , ROUTE_NAME
     , ROUTE_DIRECTION
     , ROUTE_DIRECTION_NAME
     , GEO_NODE_ABBR
     , GEO_NODE_NAME
     , OPERATOR_NAME
)
values
(sched_spm_route_stop_key
,s.CALENDAR_ID
,s.OPERATOR_ID
,s.TRIP_ID
,s.TRIP_END_TIME
,s.MODEL_PARTITION 
,s.VEHICLE_ID
,s.PROPERTY_TAG
,s.SERVICE_ABBR
,s.SERVICE_TYPE_TEXT
,s.TIME_POINT_ID
,s.IsTimepoint
,s.REVENUE_ID
,s.ROUTE_ABBR
,s.ROUTE_NAME
,s.ROUTE_DIRECTION
,s.ROUTE_DIRECTION_NAME
,s.GEO_NODE_ABBR
,s.GEO_NODE_NAME
,s.OPERATOR_NAME
)
when not matched by source and calendar_id >= @buildDt then delete
output $action into @outputTbl;


DECLARE @ins INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'INSERT')
DECLARE @upd INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'UPDATE')
DECLARE @del INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'DELETE')
DECLARE @prg VARCHAR(90) = @@SERVERNAME + '.ltd_dw.tm.merge_schedule'

INSERT process.mergeLogs
(		[MergeCode]
           ,[ObjectDestination]
           ,[ObjectSource]
           ,[ObjectProgram]
           ,[recInsert]
           ,[recUpdate]
           ,[recDelete]
           ,[MergeBeginDatetime]
           ,[MergeEndDatetime])
SELECT 'UMOSCH',
'ltd_dw.tm.model_schedule',
'UMOAPI',
@prg,
ISNULL(@ins,0) ,ISNULL(@upd,0),ISNULL(@del,0),
@sdt,
SYSDATETIME()

DROP TABLE IF EXISTS 
--SELECT * FROM 
        wrk.schedprep

END TRY	  

BEGIN CATCH

       DECLARE @profile VARCHAR(255) = (
                    SELECT [NAME]
                    FROM msdb.dbo.sysmail_profile
                    )
       DECLARE @errormsg VARCHAR(MAX)
             ,@error INT
             ,@message VARCHAR(MAX)
             ,@xstate INT
             ,@errsev INT
             ,@sub VARCHAR(255);

       SELECT @error = ERROR_NUMBER()
             ,@errsev = ERROR_SEVERITY()
             ,@message = ERROR_MESSAGE()
             ,@xstate = XACT_STATE();

       SELECT @errormsg = 'Error in ' + ISNULL(@SPROC, '') + ': ' + CAST(ISNULL(@error, '') AS NVARCHAR(32)) + '|' + COALESCE(@message, '') + '|' + CAST(ISNULL(@xstate, '') AS NVARCHAR(32)) + '|' +CAST(ISNULL(@errsev, '') AS NVARCHAR(32))

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
