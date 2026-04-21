SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE procedure [eam].[merge_work_order_details]
as
/*------------LTD_GLOSSARY-----------------

CREATED		20260303
AUTHOR		B Eichberger
PURPOSE		Prepares data and merges into [eam].[work_order_detail]
			Provide source data for eam_model and other reporting; 
USE         exec eam.merge_work_order_details

			
 */

set nocount on

declare @SPROC varchar(100)
set @SPROC = object_schema_name(@@procid) + '.' + object_name(@@procid)

insert into DBA.[aud].[Object_Activity]
	([server_name], [database_name] ,[host_name], [System_User], [object_name]
	,[client_net_address], [local_net_address], [auth_Scheme], [last_read], [last_write]
	,[most_recent_sql_handle], [Timestamp], object_type)
select distinct @@servername, db_name(),host_name(),system_user, @SPROC,
	client_net_address, local_net_address , auth_Scheme, last_read, last_write 
	,most_recent_sql_handle, current_timestamp as [Timestamp], 'PROC'
from sys.dm_exec_connections 
where session_id = @@spid ;

begin try

												
DECLARE @sdt DATETIME2 = SYSDATETIME()
DECLARE @outputTbl TABLE (actionNm VARCHAR(32));

declare @stdt int = (
select min(c.calendar_id) minCal from tm.DW_CALENDAR c
where year(c.CALENDAR_DATE) >= year(getdate())-2 )

declare @process_date datetime = ( select max(c.calendar_date) maxCal from tm.DW_CALENDAR c
                                   where (c.CALENDAR_DATE) >= dateadd(day,-1,getdate()) )


DECLARE @Calendar_id INT = (SELECT  c.CALENDAR_ID  FROM tm.DW_CALENDAR c WHERE c.CALENDAR_DATE = CAST(@process_date AS DATE)) /* incremental runs*/

--DECLARE @Calendar_id INT = @stdt /* 1st time run to pull all historical data */


DROP TABLE IF EXISTS ##jobm9923
SELECT * into ##jobm9923 FROM OPENQUERY([LTD-EAM],'select jo.[X_datetime_insert]
      ,jo.[work_order_yr]
      ,jo.[work_order_no]
      ,jo.[estimate]
      ,jo.[job_type]
      ,jo.[EQ_equip_no] 
      ,jo.[work_order_status]
      ,jo.[datetime_out_service]
      ,jo.[datetime_in_service]
      ,jo.[datetime_closed]
      ,jo.[datetime_unit_in]
      ,jo.[qty_est_hours]
                  ,jo.[meter_1_life_total]
                  ,jo.[meter_1_reading]
                  ,jo.[wcl_work_class] -- 4 = road call
                  ,jo.labor_cost
                  ,jo.labor_hours jobmain_labor_hours
                  ,jo.[comml_cost]
                  ,jo.[warranty]
                  ,jo.[acct_acct_code] as job_account_id
                ,[days_out_of_service] = datediff(d, jo.datetime_out_service, isnull([datetime_in_service],getdate()))
                from proto.emsdba.job_main jo WITH (NOLOCK)
                where work_order_yr >= year(getdate())-12
				and jo.work_order_status = ''CLOSED''
                and (cast([X_datetime_insert] as date) <= cast(getdate() as date)
                or cast([X_datetime_update] as date) <= cast(getdate() as date))
                /* and (100000000 + cast(convert(varchar(32),(cast([X_datetime_insert] as date)),112) as INT) >= ''120141225''
                or 100000000+ cast(convert(varchar(32),(cast([X_datetime_update] as date)),112) as INT)  >= ''120141225'') */
				 and (100000000 + cast(convert(varchar(32),(cast([X_datetime_insert] as date)),112) as INT) >= ''120120701''
                or 100000000+ cast(convert(varchar(32),(cast([X_datetime_update] as date)),112) as INT)  >= ''120120701'')  
                group by [X_datetime_insert]
                  ,jo.[work_order_yr]
      ,jo.[work_order_no]
      ,jo.[estimate]
      ,jo.[job_type]
      ,jo.[EQ_equip_no] 
      ,jo.[work_order_status]
      ,jo.[datetime_out_service]
      ,jo.[datetime_in_service]
      ,jo.[datetime_closed]
      ,jo.[datetime_unit_in]
      ,jo.[qty_est_hours]
                  ,jo.[meter_1_life_total]
                  ,jo.[meter_1_reading]
                  ,jo.[wcl_work_class] -- = B or 4 = road call
                  ,jo.labor_cost
                  ,jo.labor_hours
                  ,jo.[comml_cost]
                  ,jo.[warranty]
                  ,jo.[acct_acct_code]')

DROP TABLE IF EXISTS ##labmain9923

select X_datetime_insert date_entered,task_task_code , [hours], EMP_empl_no
,labor_rate,work_order_no ,work_order_yr,lab_date,[unique_id], cost as lab_cost
,lab_start_time,lab_end_time,CLASS_class_maint,CLASS_class_stds
,task_type, task_reason, indirect_flag, labor_account_id --,fully_reversed,reversal_flag
,row_id, group_row_id,reas_reas_for_repair, time_time_code
into ##labmain9923 
from OPENQUERY( [LTD-EAM],'SELECT L.task_task_code ,sum(L.[hours]) [hours], L.EMP_empl_no
,L.labor_rate,L.work_order_no ,L.work_order_yr,L.lab_date,L.[unique_id], L.X_datetime_insert
,lab_start_datetime as lab_start_time, lab_end_datetime as lab_end_time, indirect_flag
,CLASS_class_maint,CLASS_class_stds, cost, time_time_code
--,fully_reversed,reversal_flag
,ds.[description] AS task_type, r.[description] AS task_reason, l.REAS_reas_for_repair
, l.row_id, l.group_row_id,l.ACCT_acct_code as labor_account_id
from proto.emsdba.lab_main L
LEFT JOIN proto.[emsdba].[RSN_MAIN] R ON L.[REAS_reas_for_repair] = R.[REAS_reas_for_repair]
LEFT JOIN proto.[emsdba].[DES_MAIN] DS ON DS.[TASK_task_code] = L.[TASK_task_code]
where fully_reversed = ''N''
        AND posting_complete = ''Y''
        AND RTRIM(LTRIM(EQ_equip_no)) <> ''''
        --AND ISNUMERIC(CLASS_class_maint) = 1
   and lab_date <= cast(getdate() as date)
   and year(lab_date) >= 2010
   and 100000000+ cast(convert(varchar(32),(cast(L.[X_datetime_insert] as date)),112) as INT) >= year(getdate())-12
group by L.task_task_code,ds.[description], r.[description], L.EMP_empl_no,labor_rate,cost, L.work_order_no , L.work_order_yr
                  --,fully_reversed,reversal_flag
				  , L.lab_date, L.[unique_id],CLASS_class_maint,CLASS_class_stds, time_time_code
				  , indirect_flag,L.X_datetime_insert, l.row_id, l.group_row_id,l.ACCT_acct_code
,L.[REAS_reas_for_repair],lab_start_datetime, lab_end_datetime, ds.[description], r.[description]')

--SELECT * FROM ##labmain9923

DROP TABLE IF EXISTS #tskcat
select distinct l.task_task_code,category , warranty, warranty_short = left(warranty,1)
into #tskcat 
from [LTD-EAM].proto.emsdba.tsk_main  l 
join [LTD-EAM].ltd_db.dbo.des_main_v d on d.task_task_code = l.task_task_code

drop table if exists #rtcc
select distinct task_task_code as rtcc_task, dbo.fn_ProperCase(repair_group_code) repair_group_code
				, dbo.fn_ProperCase(repair_group) repair_group, dbo.fn_ProperCase(category) category
				, dbo.fn_ProperCase(replace(task_type, ' Task', ''))collate SQL_Latin1_General_CP1_CI_AS task_type
				, dbo.fn_ProperCase([description])collate SQL_Latin1_General_CP1_CI_AS task_type_description 
				into #rtcc 
				from	[LTD-EAM].ltd_db.[dbo].[des_main_v]

drop table if exists #rsn
select distinct REAS_reas_for_repair, [description], breakdown_flag
				, [rsn_category] = cast(case when reas_reas_for_repair in ( 'a', 'b', 'f', 'i', 'p', 'v' ) then 'Non-Mech' else 'Mech' end as varchar(12))
				into -- select * from 
				#rsn -- select *  
				from	[ltd-eam].proto.[emsdba].[RSN_MAIN]
				--where	reason_repair_invalidated = 'N'


DROP TABLE IF EXISTS #stageWorkOrder

select 
tm.X_datetime_insert
,tm.calendar_id
,tm.work_order_yr
,tm.work_order_no
,tm.estimate
,tm.job_type
,tm.eq_equip_no
,tm.work_order_status
,tm.datetime_out_service
,tm.datetime_in_service
,tm.datetime_closed
,tm.datetime_unit_in
,tm.qty_est_hours
,tm.meter_1_life_total
,tm.meter_1_reading
,tm.wcl_work_class
,tm.date_entered
,tm.labor_date
,isnull(tm.TASK_task_code,'-1') TASK_task_code
,tm.REAS_reas_for_repair
,tm.CLASS_class_maint
,tm.CLASS_class_stds
,tm.lab_start_time
,tm.lab_end_time
,tm.task_type
,tm.task_reason
,tm.emp_empl_no
,tm.labor_rate
,tm.labor_cost_job
,tm.labor_cost_lab
,tm.calc_cost
,tm.jobmain_labor_hours
,tm.labmain_labor_hours
,tm.comml_cost
,tm.warranty
,tm.lab_date
,tm.indirect_flag
,tm.TIME_time_code
,tm.row_id
,tm.group_row_id
,tm.job_account_id
,tm.labor_account_id
,wo_task_inserted = tm.X_datetime_insert
                ,wo_task_calendar_id = 100000000 + cast(convert(VARCHAR(32), CAST(tm.X_datetime_insert AS DATETIME), 112) AS INT)
                ,wo_task_yr_no = CAST(isnull(tm.work_order_yr,-1) as varchar(12)) + '-' + CAST(ISNULL(tm.work_order_no, -1) AS VARCHAR(12))+'-'+isnull(tm.TASK_task_code ,'-1')
, dbo.fn_ProperCase(case when e.[name] not like '%ý%' then replace(e.[name],'-',',') 
                  when e.[name]  like '%ý%' then replace(replace(e.[name],'ý',','),'-','') end)  employee_name
, b.life_miles, b.ltd_bus_class, b.bio_diesel, b.atric, b.emx_bus, b.hybrid, b.electric, b.max_fuel, b.active, b.unit_is_active
,ltd_bus_class_adj = (CASE WHEN b.ltd_bus_class = 'unknown' THEN '999999'
                               ELSE b.ltd_bus_class END ),
--UPPER(t.repair_group) repair_group,
upper(t.repair_group_code) repair_group_code,
--upper(t.category) repair_category,
case when tcc.category = 'Other' then t.category end backupCategory
, tcc.category as repair_category
--, tm.row_id, tm.group_row_id
--,t.rtcc_task
     --,t.repair_group_code
     ,t.repair_group as repair_group
     ,t.category as category
     --,dbo.fn_ProperCase(t.task_type_description) task_type_description
	 --,rn.[description] as reason_for_repair_new
	 ,rn.breakdown_flag
	 ,isnull(rn.[rsn_category],'other') rsn_category
      ,tcc.warranty as task_warranty
      ,tcc.warranty_short as task_warranty_short
into #stageWorkOrder
-- SELECT * 
FROM  (select jobm9923.X_datetime_insert -- 564351 -- 585768
	  ,calendar_id = (100000000)+CONVERT(INT,CONVERT(VARCHAR(32),CONVERT(DATE, jobm9923.X_datetime_insert),(112)))
       ,jobm9923.work_order_yr
      ,jobm9923.work_order_no
      ,jobm9923.estimate
      ,jobm9923.job_type
      ,jobm9923.eq_equip_no
      ,jobm9923.work_order_status
      ,jobm9923.datetime_out_service
      ,jobm9923.datetime_in_service
      ,jobm9923.datetime_closed
      ,jobm9923.datetime_unit_in
      ,jobm9923.qty_est_hours
      ,jobm9923.meter_1_life_total
      ,jobm9923.meter_1_reading
      ,jobm9923.wcl_work_class -- = 'B' (legacy) and '4' = road call
      ,l.date_entered
      ,l.lab_date as labor_date
      ,l.TASK_task_code
	  ,l.REAS_reas_for_repair
      ,l.CLASS_class_maint,l.CLASS_class_stds
	 ,l.lab_start_time,l.lab_end_time
     ,task_type = replace(replace(replace(replace(replace(dbo.fn_ProperCase(l.task_type),'ý',''),'Hvac','HVAC'),'Pm','PM'),'Nrv','NRV'),'PMi','PMI') -- 6ý000 MILE INSPECTION
     ,replace(replace(dbo.fn_ProperCase(task_reason),'Hvac','HVAC'),'Pm','PM') task_reason
     ,l.EMP_empl_no emp_empl_no
     ,l.labor_rate
     ,labor_cost_job = jobm9923.labor_cost
     ,labor_cost_lab = l.lab_cost
	 ,calc_cost = l.labor_rate * l.[hours]
     ,jobm9923.jobmain_labor_hours
     ,l.[hours] labmain_labor_hours
     ,jobm9923.comml_cost
     ,jobm9923.warranty
     ,jobm9923.job_account_id
     ,l.labor_account_id
     ,cast(l.lab_date as smalldatetime) lab_date
     ,l.indirect_flag
     ,l.time_time_code
	 ,row_id
	 ,group_row_id	
FROM ##jobm9923 jobm9923 
LEFT JOIN ##labmain9923 l on l.work_order_no = jobm9923.work_order_no and l.work_order_yr = jobm9923.work_order_yr --and l.TASK_task_code = jobm9923.TASK_task_code
) tm 
left join #tskcat tcc on tcc.task_task_code = tm.TASK_task_code 
LEFT JOIN [LTD-EAM].ltd_db.dbo.bus_classes b WITH (NOLOCK)
                ON b.eq_equip_no = tm.eq_equip_no   
LEFT JOIN [LTD-EAM].ltd_db.dbo.employee_info e WITH (NOLOCK) on e.EMP_empl_no = tm.EMP_empl_no
LEFT JOIN #rtcc t on tm.TASK_task_code = t.rtcc_task
LEFT JOIN #rsn rn on rn.REAS_reas_for_repair = tm.REAS_reas_for_repair

--select top(100) * from #stageWorkOrder order by work_order_yr desc, work_order_no desc

--DROP TABLE eam.work_order_detail_stage
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[eam].[work_order_detail_stage]') AND type in (N'U'))
CREATE TABLE eam.work_order_detail_stage(
    [calendar_id] [int] null,
	[work_order_yr] [int] not null,
	[work_order_no] [int] not null,
	[estimate] [char](1) null,
	[job_type] [varchar](15) null,
	[eq_equip_no] [varchar](20) null,
	[work_order_status] [varchar](15) null,
	[datetime_out_service] [datetime] null,
	[datetime_in_service] [datetime] null,
	[datetime_closed] [datetime] null,
	[datetime_unit_in] [datetime] null,
	[qty_est_hours] [numeric](13, 2) null,
	[meter_1_life_total] [int] null,
	[meter_1_reading] [int] null,
	[wcl_work_class] [char](1) null,
	[date_entered] [datetime] null,
	[labor_date] [date] null,
	[lab_date] [smalldatetime] null,
	[TASK_task_code] [varchar](12) null,
	[REAS_reas_for_repair] [varchar](4) null,
	[CLASS_class_maint] [varchar](30) null,
	[CLASS_class_stds] [varchar](30) null,
	[lab_start_time] [datetime] null,
	[lab_end_time] [datetime] null,
	[task_type] [varchar](90) null,
	[task_reason] [varchar](90) null,
	[emp_empl_no] [varchar](9) null,
	[labor_rate] [numeric](12, 2) null,
	[labor_cost_job] [numeric](12, 2) null,
	[labor_cost_lab] [numeric](12, 2) null,
	[calc_cost] [numeric](38, 4) null,
	[jobmain_labor_hours] [numeric](13, 2) null,
	[labmain_labor_hours] [numeric](38, 2) null,
	[comml_cost] [numeric](12, 2) null,
	[warranty] [varchar](7) null,
	[indirect_flag] [char](1) null,
    [time_time_code] [varchar](15) null,
	[row_id] [int] null,
	[group_row_id] [int] null,
	[wo_task_inserted] [datetime] null,
	[wo_task_calendar_id] [int] null,
	[wo_task_yr_no] [varchar](16) null,
	[employee_name] [varchar](90) null,
	[life_miles] [int] null,
	[ltd_bus_class] [varchar](11) null,
	[bio_diesel] [int] null,
	[atric] [int] null,
	[emx_bus] [int] null,
	[hybrid] [int] null,
	[electric] [int] null,
	[max_fuel] [int] null,
	[active] [varchar](1) null,
	[unit_is_active] [char](1) null,
	[ltd_bus_class_adj] [varchar](11) null,
	[repair_group_code] [varchar](90) null,
	[backupCategory] [varchar](90) null,
	[repair_category] [varchar](28) null,
	[repair_group] [varchar](90) null,
	[category] [varchar](90) null,
	[breakdown_flag] [char](1) null,
	[rsn_category] [varchar](12) null,
	[repair_category_check] [varchar](28) null,
	[is_road_call] [bit] default 0 not null,
    [MilesAtLastRC] [int] null,
    [milesBetweenRC] [int] null,
    [job_account_id] [varchar](42) null,
    [labor_account_id] [varchar](42) null,
    [task_warranty] varchar(12) NULL,
    [task_warranty_short] varchar(4) NULL
) ON [PRIMARY]

truncate TABLE -- select rsn_category from 
eam.work_order_detail_stage

INSERT eam.work_order_detail_stage (
	   [calendar_id]
      ,[work_order_yr]
      ,[work_order_no]
      ,[estimate]
      ,[job_type]
      ,[eq_equip_no]
      ,[work_order_status]
      ,[datetime_out_service]
      ,[datetime_in_service]
      ,[datetime_closed]
      ,[datetime_unit_in]
      ,[qty_est_hours]
      ,[meter_1_life_total]
      ,[meter_1_reading]
      ,[wcl_work_class]
      ,[date_entered]
      ,[labor_date]
      ,lab_date
      ,[TASK_task_code]
      ,[REAS_reas_for_repair]
      ,[CLASS_class_maint]
      ,[CLASS_class_stds]
      ,[lab_start_time]
      ,[lab_end_time]
      ,[task_type]
      ,[task_reason]
      ,[emp_empl_no]
      ,[labor_rate]
      ,[labor_cost_job]
      ,[labor_cost_lab]
      ,[calc_cost]
      ,[jobmain_labor_hours]
      ,[labmain_labor_hours]
      ,[comml_cost]
      ,[warranty]
      ,[indirect_flag]
      ,[time_time_code]
      ,[row_id]
      ,[group_row_id]
      ,[wo_task_inserted]
      ,[wo_task_calendar_id]
      ,[wo_task_yr_no]
      ,[employee_name]
      ,[life_miles]
      ,[ltd_bus_class]
      ,[bio_diesel]
      ,[atric]
      ,[emx_bus]
      ,[hybrid]
      ,[electric]
      ,[max_fuel]
      ,[active]
      ,[unit_is_active]
      ,[ltd_bus_class_adj]
      ,[repair_group_code]
      ,[backupCategory]
      ,[repair_category]
      ,[repair_group]
      ,[category]
      ,[breakdown_flag]
      ,[rsn_category]
	  ,[repair_category_check] 
	  ,[is_road_call] 
      ,[MilesAtLastRC]
      ,[milesBetweenRC]
      ,[job_account_id]
      ,[labor_account_id]
      ,[task_warranty] 
      ,[task_warranty_short] 
)
select
d.[calendar_id]
      ,d.[work_order_yr]
      ,d.[work_order_no]
      ,d.[estimate]
      ,d.[job_type]
      ,d.[eq_equip_no]
      ,d.[work_order_status]
      ,d.[datetime_out_service]
      ,d.[datetime_in_service]
      ,d.[datetime_closed]
      ,d.[datetime_unit_in]
      ,d.[qty_est_hours]
      ,d.[meter_1_life_total]
      ,d.[meter_1_reading]
      ,d.[wcl_work_class]
      ,d.[date_entered]
      ,CAST(d.lab_date AS DATE) labor_date
      ,d.lab_date
      ,isnull(d.[TASK_task_code],'-1') [TASK_task_code]
      ,d.[REAS_reas_for_repair]
      ,d.[CLASS_class_maint]
      ,d.[CLASS_class_stds]
      ,d.[lab_start_time]
      ,d.[lab_end_time]
      ,d.[task_type]
      ,d.[task_reason]
      ,d.[emp_empl_no]
      ,d.[labor_rate]
      ,d.[labor_cost_job]
	  ,SUM(isnull(labor_cost_lab,0)) labor_cost_lab
      ,d.[calc_cost]
      ,SUM(isnull(d.jobmain_labor_hours,0)) jobmain_labor_hours
      ,SUM(isnull(d.labmain_labor_hours,0)) [labmain_labor_hours]
      ,d.[comml_cost]
      ,d.[warranty]
      ,d.[indirect_flag]
      ,d.[time_time_code]
      ,d.[row_id]
      ,d.[group_row_id]
      ,d.[wo_task_inserted]
      ,d.[wo_task_calendar_id]
      ,d.[wo_task_yr_no]
      ,d.[employee_name]
      ,d.[life_miles]
      ,d.[ltd_bus_class]
      ,d.[bio_diesel]
      ,d.[atric]
      ,d.[emx_bus]
      ,d.[hybrid]
      ,d.[electric]
      ,d.[max_fuel]
      ,d.[active]
      ,d.[unit_is_active]
      ,d.[ltd_bus_class_adj]
      ,d.[repair_group_code]
      ,d.[backupCategory]
      ,d.[repair_category]
      ,d.[repair_group]
      ,d.[category]
      ,d.[breakdown_flag]
      ,d.[rsn_category] 
	  ,case when c.work_order_yr_no is not null and d.repair_category is null then 'ROADCALL' else d.repair_category end repair_category_check
	  ,case when c.work_order_yr_no is not null then 1 else 0 end as is_road_call
      ,c.MilesAtLastRC
      ,c.milesBetweenRC
      ,d.job_account_id
      ,d.labor_account_id
      ,d.[task_warranty] 
      ,d.[task_warranty_short] 
FROM #stageWorkOrder d
left join eam.road_calls c on c.work_order_yr = d.work_order_yr and c.work_order_no = d.work_order_no
WHERE NOT (d.work_order_no = 2 AND d.work_order_yr = 2013)
GROUP BY
	d.[calendar_id]
      ,d.[work_order_yr]
      ,d.[work_order_no]
      ,d.[estimate]
      ,d.[job_type]
      ,d.[eq_equip_no]
      ,d.[work_order_status]
      ,d.[datetime_out_service]
      ,d.[datetime_in_service]
      ,d.[datetime_closed]
      ,d.[datetime_unit_in]
      ,d.[qty_est_hours]
      ,d.[meter_1_life_total]
      ,d.[meter_1_reading]
      ,d.[wcl_work_class]
      ,d.[date_entered]
      ,CAST(d.lab_date AS DATE)
      ,d.lab_date
      ,d.[TASK_task_code]
      ,d.[REAS_reas_for_repair]
      ,d.[CLASS_class_maint]
      ,d.[CLASS_class_stds]
      ,d.[lab_start_time]
      ,d.[lab_end_time]
      ,d.[task_type]
      ,d.[task_reason]
      ,d.[emp_empl_no]
      ,d.[labor_rate]
      ,d.[labor_cost_job]
      ,d.[calc_cost]
      ,d.[comml_cost]
      ,d.[warranty]
      ,d.[indirect_flag]
      ,d.[time_time_code]
      ,d.[row_id]
      ,d.[group_row_id]
      ,d.[wo_task_inserted]
      ,d.[wo_task_calendar_id]
      ,d.[wo_task_yr_no]
      ,d.[employee_name]
      ,d.[life_miles]
      ,d.[ltd_bus_class]
      ,d.[bio_diesel]
      ,d.[atric]
      ,d.[emx_bus]
      ,d.[hybrid]
      ,d.[electric]
      ,d.[max_fuel]
      ,d.[active]
      ,d.[unit_is_active]
      ,d.[ltd_bus_class_adj]
      ,d.[repair_group_code]
      ,d.[backupCategory]
      ,d.[repair_category]
      ,d.[repair_group]
      ,d.[category]
      ,d.[breakdown_flag]
      ,d.[rsn_category]
	  ,case when c.work_order_yr_no is not null and d.repair_category is null then 'ROADCALL' else d.repair_category end 
	  ,case when c.work_order_yr_no is not null then 1 else 0 end 
	  ,c.MilesAtLastRC
      ,c.milesBetweenRC
      ,d.job_account_id
      ,d.labor_account_id
      ,d.[task_warranty] 
      ,d.[task_warranty_short] 


merge -- truncate table -- select top(100) rsn_category from 
	eam.work_order_detail 
    --order by work_order_yr desc, work_order_no desc 
    as t
USING eam.work_order_detail_stage AS s
ON (  t.work_order_yr = s.work_order_yr
	and t.work_order_no = s.work_order_no
	and t.task_task_code = s.task_task_code
	and t.eq_equip_no = s.eq_equip_no
	and t.emp_empl_no = s.emp_empl_no
	and t.lab_date = s.lab_date
	AND t.[row_id] = s.[row_id]
	AND t.[group_row_id] = s.[group_row_id]
	)
WHEN MATCHED AND (
      ISNULL(t.estimate,'') <> ISNULL(s.estimate,'') 
   or ISNULL(t.job_type,'') <> ISNULL(s.job_type,'') 
   or ISNULL(t.work_order_status,'') <> ISNULL(s.work_order_status,'') 
   or ISNULL(t.datetime_out_service,'') <> ISNULL(s.datetime_out_service,'') 
   or ISNULL(t.datetime_in_service,'') <> ISNULL(s.datetime_in_service,'') 
   or ISNULL(t.datetime_closed,'') <> ISNULL(s.datetime_closed,'') 
   or ISNULL(t.datetime_unit_in,'') <> ISNULL(s.datetime_unit_in,'') 
   or ISNULL(t.qty_est_hours,'') <> ISNULL(s.qty_est_hours,'') 
   or ISNULL(t.meter_1_life_total,'') <> ISNULL(s.meter_1_life_total,'') 
   or ISNULL(t.meter_1_reading,'') <> ISNULL(s.meter_1_reading,'') 
   or ISNULL(t.wcl_work_class,'') <> ISNULL(s.wcl_work_class,'') 
   or ISNULL(t.date_entered,'') <> ISNULL(s.date_entered,'') 
   or ISNULL(t.REAS_reas_for_repair,'') <> ISNULL(s.REAS_reas_for_repair,'') 
   or ISNULL(t.CLASS_class_maint,'') <> ISNULL(s.CLASS_class_maint,'') 
   or ISNULL(t.CLASS_class_stds,'') <> ISNULL(s.CLASS_class_stds,'') 
   or ISNULL(t.lab_start_time,'') <> ISNULL(s.lab_start_time,'') 
   or ISNULL(t.lab_end_time,'') <> ISNULL(s.lab_end_time,'') 
   or ISNULL(t.task_type,'') <> ISNULL(s.task_type,'') 
   or ISNULL(t.task_reason,'') <> ISNULL(s.task_reason,'') 
   or ISNULL(t.labor_rate,'') <> ISNULL(s.labor_rate,'') 
   or ISNULL(t.labor_cost_job,'') <> ISNULL(s.labor_cost_job,'') 
   or ISNULL(t.labor_cost_lab,'') <> ISNULL(s.labor_cost_lab,'') 
   or ISNULL(t.calc_cost,'') <> ISNULL(s.calc_cost,'') 
   or ISNULL(t.jobmain_labor_hours,'') <> ISNULL(s.jobmain_labor_hours,'') 
   or ISNULL(t.labmain_labor_hours,'') <> ISNULL(s.labmain_labor_hours,'') 
   or ISNULL(t.comml_cost,'') <> ISNULL(s.comml_cost,'') 
   or ISNULL(t.warranty,'') <> ISNULL(s.warranty,'') 
   or ISNULL(t.lab_date,'') <> ISNULL(s.lab_date,'') 
   or ISNULL(t.indirect_flag,'') <> ISNULL(s.indirect_flag,'') 
   or ISNULL(t.time_time_code,'') <> ISNULL(s.time_time_code,'') 
   or ISNULL(t.wo_task_inserted,'') <> ISNULL(s.wo_task_inserted,'') 
   or ISNULL(t.wo_task_calendar_id,'') <> ISNULL(s.wo_task_calendar_id,'') 
   or ISNULL(t.wo_task_yr_no,'') <> ISNULL(s.wo_task_yr_no,'') 
   or ISNULL(t.employee_name,'') <> ISNULL(s.employee_name,'') 
   or ISNULL(t.life_miles,'') <> ISNULL(s.life_miles,'') 
   or ISNULL(t.ltd_bus_class,'') <> ISNULL(s.ltd_bus_class,'') 
   or ISNULL(t.bio_diesel,'') <> ISNULL(s.bio_diesel,'') 
   or ISNULL(t.atric,'') <> ISNULL(s.atric,'') 
   or ISNULL(t.emx_bus,'') <> ISNULL(s.emx_bus,'') 
   or ISNULL(t.hybrid,'') <> ISNULL(s.hybrid,'') 
   or ISNULL(t.electric,'') <> ISNULL(s.electric,'') 
   or ISNULL(t.max_fuel,'') <> ISNULL(s.max_fuel,'') 
   or ISNULL(t.active,'') <> ISNULL(s.active,'') 
   or ISNULL(t.unit_is_active,'') <> ISNULL(s.unit_is_active,'') 
   or ISNULL(t.ltd_bus_class_adj,'') <> ISNULL(s.ltd_bus_class_adj,'') 
   or ISNULL(t.repair_group_code,'') <> ISNULL(s.repair_group_code,'') 
   or ISNULL(t.backupCategory,'') <> ISNULL(s.backupCategory,'') 
   or ISNULL(t.repair_category,'') <> ISNULL(s.repair_category,'') 
   or ISNULL(t.repair_group,'') <> ISNULL(s.repair_group,'') 
   or ISNULL(t.category,'') <> ISNULL(s.category,'') 
   or ISNULL(t.breakdown_flag,'') <> ISNULL(s.breakdown_flag,'') 
   or ISNULL(t.rsn_category,'') <> ISNULL(s.rsn_category,'') 
   or ISNULL(t.repair_category_check,'') <> ISNULL(s.repair_category_check,'') 
   or ISNULL(t.is_road_call,'') <> ISNULL(s.is_road_call,'') 
   or ISNULL(t.MilesAtLastRC,0) <> ISNULL(s.MilesAtLastRC,0)
   or ISNULL(t.milesBetweenRC,0) <> ISNULL(s.milesBetweenRC,0)
   or isnull(t.job_account_id,'') <> isnull(s.job_account_id,'')
   or isnull(t.labor_account_id,'') <> isnull(s.labor_account_id,'')
   or isnull(t.[task_warranty],'') <> isnull(s.[task_warranty] ,'')
   or isnull(t.[task_warranty_short],'') <> isnull(s.[task_warranty_short],'')
)
THEN UPDATE SET t.estimate = s.estimate
,t.job_type = s.job_type
,t.work_order_status = s.work_order_status
,t.datetime_out_service = s.datetime_out_service
,t.datetime_in_service = s.datetime_in_service
,t.datetime_closed = s.datetime_closed
,t.datetime_unit_in = s.datetime_unit_in
,t.qty_est_hours = s.qty_est_hours
,t.meter_1_life_total = s.meter_1_life_total
,t.meter_1_reading = s.meter_1_reading
,t.wcl_work_class = s.wcl_work_class
,t.date_entered = s.date_entered
,t.TASK_task_code = s.TASK_task_code
,t.REAS_reas_for_repair = s.REAS_reas_for_repair
,t.CLASS_class_maint = s.CLASS_class_maint
,t.CLASS_class_stds = s.CLASS_class_stds
,t.lab_start_time = s.lab_start_time
,t.lab_end_time = s.lab_end_time
,t.task_type = s.task_type
,t.task_reason = s.task_reason
,t.labor_rate = s.labor_rate
,t.labor_cost_job = s.labor_cost_job
,t.labor_cost_lab = s.labor_cost_lab
,t.calc_cost = s.calc_cost
,t.jobmain_labor_hours = s.jobmain_labor_hours
,t.labmain_labor_hours = s.labmain_labor_hours
,t.comml_cost = s.comml_cost
,t.warranty = s.warranty
,t.lab_date = s.lab_date
,t.indirect_flag = s.indirect_flag
,t.time_time_code = s.time_time_code
,t.wo_task_inserted = s.wo_task_inserted
,t.wo_task_calendar_id = s.wo_task_calendar_id
,t.wo_task_yr_no = s.wo_task_yr_no
,t.employee_name = s.employee_name
,t.life_miles = s.life_miles
,t.ltd_bus_class = s.ltd_bus_class
,t.bio_diesel = s.bio_diesel
,t.atric = s.atric
,t.emx_bus = s.emx_bus
,t.hybrid = s.hybrid
,t.electric = s.electric
,t.max_fuel = s.max_fuel
,t.active = s.active
,t.unit_is_active = s.unit_is_active
,t.ltd_bus_class_adj = s.ltd_bus_class_adj
,t.repair_group_code = s.repair_group_code
,t.backupCategory = s.backupCategory
,t.repair_category = s.repair_category
,t.repair_group = s.repair_group
,t.category = s.category
,t.breakdown_flag = s.breakdown_flag
,t.rsn_category = s.rsn_category
,t.repair_category_check = s.repair_category_check
,t.is_road_call = s.is_road_call
,t.MilesAtLastRC = s.MilesAtLastRC
,t.milesBetweenRC = s.milesBetweenRC
,t.job_account_id = s.job_account_id
,t.labor_account_id = s.labor_account_id
,t.[task_warranty] = s.[task_warranty]
,t.[task_warranty_short] = s.[task_warranty_short]
,t.record_updated_date  =  SYSDATETIME()
WHEN NOT MATCHED BY TARGET
THEN INSERT
(calendar_id,work_order_yr,work_order_no,estimate,job_type,eq_equip_no,work_order_status
,datetime_out_service,datetime_in_service,datetime_closed,datetime_unit_in,qty_est_hours
,meter_1_life_total,meter_1_reading,wcl_work_class,date_entered,labor_date,TASK_task_code
,REAS_reas_for_repair,CLASS_class_maint,CLASS_class_stds,lab_start_time,lab_end_time,task_type
,task_reason,emp_empl_no,labor_rate,labor_cost_job,labor_cost_lab,calc_cost,jobmain_labor_hours
,labmain_labor_hours,comml_cost,warranty,lab_date,indirect_flag,time_time_code,row_id
,group_row_id,wo_task_inserted,wo_task_calendar_id,wo_task_yr_no,employee_name,life_miles
,ltd_bus_class,bio_diesel,atric,emx_bus,hybrid,electric,max_fuel,active,unit_is_active
,ltd_bus_class_adj,repair_group_code,backupCategory,repair_category,repair_group,category
,breakdown_flag,rsn_category,repair_category_check,is_road_call,MilesAtLastRC,milesBetweenRC
,job_account_id,labor_account_id, [task_warranty],[task_warranty_short]
)
VALUES
(calendar_id,s.work_order_yr,s.work_order_no,s.estimate,s.job_type,s.eq_equip_no,s.work_order_status
,s.datetime_out_service,s.datetime_in_service,s.datetime_closed,s.datetime_unit_in,s.qty_est_hours
,s.meter_1_life_total,s.meter_1_reading,s.wcl_work_class,s.date_entered,s.labor_date,s.TASK_task_code
,s.REAS_reas_for_repair,s.CLASS_class_maint,s.CLASS_class_stds,s.lab_start_time,s.lab_end_time,s.task_type
,s.task_reason,s.emp_empl_no,s.labor_rate,s.labor_cost_job,s.labor_cost_lab,s.calc_cost,s.jobmain_labor_hours
,s.labmain_labor_hours,s.comml_cost,s.warranty,s.lab_date,s.indirect_flag,s.time_time_code,s.row_id,s.group_row_id
,s.wo_task_inserted,s.wo_task_calendar_id,s.wo_task_yr_no,s.employee_name,s.life_miles,s.ltd_bus_class
,s.bio_diesel,s.atric,s.emx_bus,s.hybrid,s.electric,s.max_fuel,s.active,s.unit_is_active,s.ltd_bus_class_adj
,s.repair_group_code,s.backupCategory,s.repair_category,s.repair_group,s.category,s.breakdown_flag
,s.rsn_category,s.repair_category_check,s.is_road_call,s.MilesAtLastRC,s.milesBetweenRC
,s.job_account_id,s.labor_account_id,s.task_warranty,s.task_warranty_short
)
 when not matched by source then DELETE
OUTPUT $action INTO @outputTbl;


DECLARE @ins INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'INSERT')
DECLARE @upd INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'UPDATE')
DECLARE @del INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'DELETE')
DECLARE @prg varchar(90) = @@SERVERNAME + '.ltd_dw.eam.merge_work_order_details'

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
SELECT 'WRKOR',
'ltd_dw.eam.work_order_detail',
'EAM',
@prg,
ISNULL(@ins,0) ,ISNULL(@upd,0),ISNULL(@del,0),
@sdt,
SYSDATETIME()

drop table if exists ##jobm9923
drop table if exists ##labmain9923
drop table if exists #tskcat
drop table if exists #rsn
drop table if exists #rtcc



END TRY	  


BEGIN CATCH

       DECLARE @profile VARCHAR(255) = (
                    SELECT NAME
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
