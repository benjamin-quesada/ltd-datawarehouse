SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [eam].[get_road_calls]
as

/*
CREATED BY  : B. Eichberger
CREATED ON  : 20260210
PURPOSE     : Populate a table for a reporting and for use in the tabular model (EAM_MODEL)
USE         : exec [eam].[get_road_calls]

*/

set nocount on;

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

DECLARE @sdt DATETIME2 = SYSDATETIME()
DECLARE @outputTbl TABLE (actionNm VARCHAR(62));

drop table if exists #road_call_setup

select distinct q.work_order_yr, q.work_order_no 
into #road_call_setup 
from (
    select work_order_yr, work_order_no 
    from [ltd-eam].proto.emsdba.SRV_MAIN 
        where ((TASK_task_code like '45-%' or TASK_task_code = '45')
            or (TASK_task_code is null and WCL_work_class in ('B','4')))
        and work_order_no is not null and work_order_no <> 0
        and work_order_yr >= year(getdate()) - 12 
    union
    select a.work_order_yr, a.work_order_no 
    from [ltd-eam].proto.emsdba.JOB_MAIN a
    left join [LTD-EAM].proto.emsdba.LAB_MAIN b on a.work_order_no = b.work_order_no and a.work_order_yr = b.work_order_yr
        where b.TASK_task_code is null
        and a.work_order_no is not null and a.work_order_no <> 0
        and a.comment_area like '%road%call%' 
        and a.comment_area not like '%repair from road%'
        and a.work_order_yr >= year(getdate()) - 12 
    union
    select work_order_yr, work_order_no 
    from [ltd-eam].proto.emsdba.SRV_MAIN 
        where ((TASK_task_code like '45-%' or TASK_task_code = '45')
            or (TASK_task_code is null and WCL_work_class in ('B','4')))
        and work_order_no is not null and work_order_no <> 0
        and work_order_yr >= year(getdate()) - 12 
) q -- 8466 --> ok -- select distinct * from #road_call_setup
--where q.work_order_yr = 2026 and q.work_order_no = 1265
;

truncate table eam.road_calls
insert eam.road_calls (
  work_order_yr
, work_order_no
, work_order_yr_no
, eq_equip_no
, MilesAtLastRC
, milesBetweenRC
)
output inserted.work_order_yr_no into @outputTbl
select i.work_order_yr
, i.work_order_no
, i.wo_task_yr_no as work_order_yr_no
, i.eq_equip_no
, i.MilesAtLastRC
, i.milesBetweenRC
from
(
    select y.work_order_yr
    , y.work_order_no
    , y.wo_task_yr_no
    , y.eq_equip_no
    , isnull(y.LastCategoryService, 0) MilesAtLastRC
    , milesBetweenRC = case when y.MilesFromLastCategory = 0 then lag(y.MilesFromLastCategory, 1) over (partition by y.eq_equip_no, y.category order by y.work_order_yr, y.miles_at_service)
            else y.MilesFromLastCategory end
    from
    (
    select t.work_order_yr
    , t.work_order_no
    , t.life_miles
    , t.miles_at_service
    , t.wo_task_calendar_id
    , t.wo_task_yr_no
    , t.eq_equip_no
    , t.job_account_id
    , t.labor_account_id
    , t.warranty
    , t.ltd_bus_class
    , t.repair_group
    , t.repair_group_code
    , t.repair_category
    , t.category
    , isnull(lag(t.life_miles, 1) over (partition by t.eq_equip_no, t.category order by t.wo_task_calendar_id), 0) LastCategoryService
    , case when isnull( t.life_miles - lag(t.life_miles, 1) over (partition by t.eq_equip_no, t.category order by t.wo_task_calendar_id)
            , t.life_miles) <= 0 then 0
           else isnull(t.life_miles - lag(t.life_miles, 1) over (partition by t.eq_equip_no, t.category order by t.wo_task_calendar_id)
            , t.life_miles)
    end MilesFromLastCategory
    from -- select * from 
        (
        select w.work_order_yr
        , w.work_order_no
        , w.meter_1_life_total life_miles
        , w.meter_1_reading    miles_at_service
        , w.wo_task_calendar_id
        , w.wo_task_yr_no
        , w.eq_equip_no
        , w.job_account_id
        , w.labor_account_id
        , w.warranty
        , w.ltd_bus_class
        , w.repair_group
        , w.repair_group_code
        , w.repair_category
        , w.category
        from ltd_dw.eam.work_order_detail w
        join #road_call_setup s on s.work_order_yr = w.work_order_yr and s.work_order_no = w.work_order_no
        where w.work_order_status = 'CLOSED'
        --and w.work_order_yr = 2026 and w.work_order_no = 962
        and w.work_order_yr >= year(getdate()) - 12
        --and w.repair_group is not null 
        group by w.work_order_yr
        , w.work_order_no
        , w.meter_1_life_total
        , w.meter_1_reading
        , w.wo_task_calendar_id
        , w.wo_task_yr_no
        , w.eq_equip_no
        , w.job_account_id
        , w.labor_account_id
        , w.warranty
        , w.ltd_bus_class
        , w.repair_group
        , w.repair_group_code
        , w.repair_category
        , w.category
        ) t
    where t.work_order_yr >= year(getdate()) - 12
    ) y
) i
where i.MilesAtLastRC <> i.milesBetweenRC
order by i.work_order_yr desc, i.work_order_no desc

drop table if exists #road_call_setup

DECLARE @ins INT = (SELECT COUNT(*) FROM @outputTbl)
DECLARE @prg varchar(90) = @@SERVERNAME + '.ltd_dw.eam.get_road_calls'

insert process.mergeLogs
(		[MergeCode]
           ,[ObjectDestination]
           ,[ObjectSource]
           ,[ObjectProgram]
           ,[recInsert]
           ,[recUpdate]
           ,[recDelete]
           ,[MergeBeginDatetime]
           ,[MergeEndDatetime])
select 'EAMR',
'ltd_dw.eam.road_calls',
'EAM',
@prg,
isnull(@ins,0) ,0,0,
@sdt,
sysdatetime()



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
