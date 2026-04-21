SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   PROCEDURE [eam].[z upsert_workorder_details]
as
-- exec eam.[upsert_workorder_details]

/*---------------------------------------

CREATED		20230315
AUTHOR		B EICHBERGER
PURPOSE		Prepares data and merges into [eam].[workOrderTaskCategoryTimeExtended]
			Provide source data specifically for eam_model; 
			This version created to add multiple columns and align with SSRS draw down figures

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

			  
declare @workstartdt datetime = sysdatetime() 
-- clean up merge log in case some previous processing did not complete
update ltd_dw.[process].[MergeLogs] 
	set recInsert =  0 
	,[MergeEndDatetime] = sysdatetime()
		where mergecode = 'WORK'
			and [ObjectDestination] = 'ltd_dw.eam.workOrderTaskCategoryTimeExtended'
			AND [ObjectSource] = 'EAM'
			AND [ObjectProgram] = 'ltd_dw.eam.upsert_workorder_details'
			AND [MergeEndDatetime] is null
			AND (isnull(recInsert,0) = 0 or isnull(recUpdate,0) = 0 or isnull(recDelete,0) = 0)


declare @stdt INT = (
SELECT MIN(c.calendar_id) minCal FROM tm.DW_CALENDAR c
LEFT JOIN eam.[workOrderTaskCategoryTimeExtended] e ON e.calendar_id = c.CALENDAR_ID
WHERE YEAR(c.CALENDAR_DATE) >= YEAR(GETDATE())-11
AND e.calendar_id IS NULL )

DECLARE @delcmd NVARCHAR(MAX) = ''
SELECT @delcmd = @delcmd + 'delete from eam.[workOrderTaskCategoryTimeExtended] where calendar_id < ''' + CAST(CAST(CONVERT(VARCHAR(32),@stdt,112) AS INT) AS VARCHAR(32)) +''''
--PRINT @delcmd
EXEC sp_executesql @delcmd

DECLARE @styr INT = (SELECT RIGHT(LEFT(@stdt,5),4))
--SELECT @styr

DROP TABLE IF EXISTS ##jobm9923
DECLARE @sqlcmd1 NVARCHAR(MAX)
SELECT @sqlcmd1 = '
SELECT * into ##jobm9923 FROM OPENQUERY([LTD-EAM],''select jo.[X_datetime_insert]
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
	  ,jo.[acct_acct_code]
	,[days_out_of_service] = datediff(d, jo.datetime_out_service, isnull([datetime_in_service],getdate()))
	from [LTD-EAM].proto.emsdba.job_main jo WITH (NOLOCK)
	where work_order_yr >= '+ CAST(@styr AS VARCHAR(12)) + ' 
	and cast([X_datetime_insert] as date) <= cast(getdate() as date)
	or cast([X_datetime_update] as date) <= cast(getdate() as date)
	and (100000000 + cast(convert(varchar(32),(cast([X_datetime_insert] as date)),112) as INT) >= '''''+CAST(@stdt AS NVARCHAR(42))+'''''
	 or 100000000+ cast(convert(varchar(32),(cast([X_datetime_update] as date)),112) as INT)  >= '''''+CAST(@stdt AS NVARCHAR(42))+''''')
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
	  ,jo.[wcl_work_class] -- = 4 = road call
	  ,jo.labor_cost
	  ,jo.labor_hours
	  ,jo.[comml_cost]
	  ,jo.[warranty]
	  ,jo.[acct_acct_code]'')'
	--PRINT @sqlcmd1
EXEC sp_executeSQL @sqlcmd1

--select * from ##jobm9923	

DROP TABLE IF EXISTS -- select * from 
##labmain9923 
DECLARE @sqlcmd NVARCHAR(MAX) = '
select X_datetime_insert date_entered,task_task_code , [hours], EMP_empl_no
,labor_rate,work_order_no ,work_order_yr,lab_date,[unique_id], cost as lab_cost
,lab_start_time,lab_end_time,CLASS_class_maint,CLASS_class_stds
,task_type, task_reason, indirect_flag
into ##labmain9923 
from OPENQUERY( [LTD-EAM],''SELECT L.task_task_code ,sum(L.[hours]) [hours], L.EMP_empl_no
,L.labor_rate,L.work_order_no ,L.work_order_yr,L.lab_date,L.[unique_id], L.X_datetime_insert
,lab_start_datetime as lab_start_time, lab_end_datetime as lab_end_time, indirect_flag
,CLASS_class_maint,CLASS_class_stds, cost
--,fully_reversed,reversal_flag,
,ds.[description] AS task_type, r.[description] AS task_reason 
from proto.emsdba.lab_main L
LEFT JOIN proto.[emsdba].[RSN_MAIN] R ON L.[REAS_reas_for_repair] = R.[REAS_reas_for_repair]
LEFT JOIN proto.[emsdba].[DES_MAIN] DS ON DS.[TASK_task_code] = L.[TASK_task_code]
 where fully_reversed = ''''N''''
			AND posting_complete = ''''Y''''
			AND RTRIM(LTRIM(EQ_equip_no)) <> ''''''''
			AND ISNUMERIC(CLASS_class_maint) = 1
   and lab_date <= cast(getdate() as date)
   and year(lab_date) >= '+ CAST(@styr AS VARCHAR(12)) + '
   and 100000000+ cast(convert(varchar(32),(cast(L.[X_datetime_insert] as date)),112) as INT) >= '''''+CAST(@stdt AS NVARCHAR(42))+'''''
group by L.task_task_code,ds.[description], r.[description], L.EMP_empl_no,labor_rate,cost, L.work_order_no , L.work_order_yr
	  , L.lab_date, L.[unique_id],CLASS_class_maint,CLASS_class_stds, indirect_flag,L.X_datetime_insert
,lab_start_datetime, lab_end_datetime, ds.[description], r.[description]'')'
--PRINT @sqlcmd
EXEC sp_executesql @sqlcmd

--select min(work_order_yr) minYr from ##labmain9923

-- delete from eam.[workOrderTaskCategoryTime] where fully_reversed = 'Y' and reversal_flag = 'Y'
DROP TABLE IF EXISTS #tskcat
select distinct l.task_task_code,[category] 
into #tskcat from ##labmain9923 l 
join [LTD-EAM].ltd_db.[dbo].[des_main_v] d on d.task_task_code = l.task_task_code

DROP TABLE IF EXISTS #stageWorkOrder
select tm.*,
[wo_task_inserted] = tm.X_datetime_insert
	,wo_task_calendar_id = 100000000 + cast(convert(VARCHAR(32), tm.X_datetime_insert, 112) AS INT)
	,[wo_task_yr_no] = cast(tm.work_order_yr AS CHAR(4)) + '-' + cast(tm.work_order_no AS VARCHAR(7))
,case when e.[name] not like '%ý%' then replace(e.[name],'-',',') 
	  when e.[name]  like '%ý%' then replace(replace(e.[name],'ý',','),'-','') end  employee_name
, b.life_miles, b.ltd_bus_class, b.bio_diesel, b.atric, b.emx_bus, b.hybrid, b.electric, b.max_fuel, b.active, b.unit_is_active
,ltd_bus_class_adj = cast(CASE 
							WHEN b.ltd_bus_class = 'unknown'
								THEN 999999
							ELSE b.ltd_bus_class
							END AS INT),
upper(rtcc.repair_group) repair_group,
upper(rtcc.[repair_group_code]) [repair_group_code],
upper(rtcc.[category]) repair_category,
case when tcc.category = 'Other' then rtcc.category end backupCategory
, tcc.category
into #stageWorkOrder
FROM  (SELECT jobm9923.[X_datetime_insert]
       ,jobm9923.[work_order_yr]
      ,jobm9923.[work_order_no]
      ,jobm9923.[estimate]
      ,jobm9923.[job_type]
      ,jobm9923.eq_equip_no
      ,jobm9923.[work_order_status]
      ,jobm9923.[datetime_out_service]
      ,jobm9923.[datetime_in_service]
      ,jobm9923.[datetime_closed]
      ,jobm9923.[datetime_unit_in]
      ,jobm9923.[qty_est_hours]
	  ,jobm9923.[meter_1_life_total]
	  ,jobm9923.[meter_1_reading]
	  ,jobm9923.[wcl_work_class] -- = '4' = road call
	  ,l.date_entered
	  ,l.lab_date as labor_date
	  ,l.TASK_task_code
	  ,l.CLASS_class_maint,l.CLASS_class_stds
,l.lab_start_time,l.lab_end_time
	  ,l.task_type
	  ,l.task_reason
	  ,l.EMP_empl_no emp_empl_no
	  ,l.labor_rate
	  ,labor_cost_job = jobm9923.labor_cost
	  ,labor_cost_lab = l.lab_cost
	  ,jobm9923.jobmain_labor_hours
	  ,l.[hours] labmain_labor_hours
	  ,jobm9923.[comml_cost]
	  ,jobm9923.[warranty]
	  ,jobm9923.[acct_acct_code] AS [account_id]
	  ,cast(l.lab_date as smalldatetime) lab_date
	  ,l.indirect_flag
 FROM ##jobm9923 jobm9923 
INNER JOIN ##labmain9923 l on l.work_order_no = jobm9923.work_order_no and l.work_order_yr = jobm9923.work_order_yr --and l.TASK_task_code = jobm9923v.TASK_task_code
) tm 
left join #tskcat tcc on tcc.task_task_code = tm.TASK_task_code 
INNER JOIN [LTD-EAM].ltd_db.[dbo].[bus_classes] b WITH (NOLOCK)
	ON b.eq_equip_no = tm.eq_equip_no	
LEFT JOIN ( select task_task_code as rtcc_task, repair_group_code,repair_group,category,task_type,[description] from 
	[LTD-EAM].ltd_db.[dbo].[des_main_v] WITH (NOLOCK) ) rtcc 
	ON rtcc.rtcc_task = tm.TASK_task_code 
LEFT JOIN [LTD-EAM].ltd_db.[dbo].[employee_info] e WITH (NOLOCK) on e.EMP_empl_no = tm.EMP_empl_no



DROP TABLE IF EXISTS [wrk].[NEWworkOrderDW]

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[wrk].[NEWworkOrderDW]') AND type in (N'U'))
CREATE TABLE [wrk].[NEWworkOrderDW](
	[work_order_yr] [int] NULL,
	[work_order_no] [int] NULL,
	[estimate] [char](1) NULL,
	[job_type] [varchar](15) NULL,
	[comml_cost] [numeric](12, 4) NULL,
	[warranty] [varchar](7) NULL,
	[account_id] [varchar](30) NULL,
	[indirect_flag] [varchar](1) NULL,
	[wcl_work_class] [varchar](3) NULL,
	labor_cost_job NUMERIC(12,4) NULL,
	labor_cost_lab NUMERIC(12,4) NULL,
	[work_order_status] [varchar](15) NULL,
	[datetime_out_service] [datetime] NULL,
	[datetime_in_service] [datetime] NULL,
	[datetime_closed] [datetime] NULL,
	[datetime_unit_in] [datetime] NULL,
	[qty_est_hours] [numeric](12, 2) NULL,
	[meter_1_life_total] [int] NULL,
	[meter_1_reading] [int] NULL,
	[TASK_task_code] [varchar](12) NULL,
	CLASS_class_maint [varchar](12) NULL,
	CLASS_class_stds [varchar](12) NULL,
	date_entered DATETIME NULL,
	lab_start_time [datetime] NULL,
	lab_end_time [datetime] NULL,
	[task_type] [varchar](90) NULL,
	[task_reason] [varchar](90) NULL,
	[emp_empl_no] [varchar](9) NULL,
	[labor_rate] [numeric](12, 2) NULL,
	[labor_hours] [numeric](12, 2) NULL,
	[jobmain_labor_hours] [numeric](12, 2) NULL,
	[labmain_labor_hours] [numeric](12, 2) NULL,
	[labor_date] [date] NULL,
	[wo_task_inserted] [datetime] NULL,
	[wo_task_calendar_id] [int] NULL,
	[wo_task_yr_no] [varchar](12) NULL,
	[employee_name] [varchar](122) NULL,
	[eq_equip_no] [varchar](20) NULL,
	[life_miles] [int] NULL,
	[ltd_bus_class] [varchar](12) NOT NULL,
	[bio_diesel] [int] NOT NULL,
	[atric] [int] NOT NULL,
	[emx_bus] [int] NOT NULL,
	[hybrid] [int] NOT NULL,
	[electric] [int] NOT NULL,
	[max_fuel] [int] NOT NULL,
	[active] [varchar](1) NOT NULL,
	[unit_is_active] [char](1) NULL,
	[ltd_bus_class_adj] [int] NULL,
	[repair_group] [varchar](255) NULL,
	[repair_group_code] [varchar](12) NULL,
	[repair_category] [varchar](28) NULL,
	[backupCategory] [varchar](28) NULL,
	[task_code] [varchar](12) NULL,
	[category] [varchar](28) NULL,
) ON [PRIMARY]
 

insert [wrk].[NEWworkOrderDW] (
	   [work_order_yr]
      ,[work_order_no]
      ,[estimate]
      ,[job_type]
	  ,[comml_cost] 
	  ,[warranty] 
	  ,[account_id] 
	  ,indirect_flag
	  ,[wcl_work_class]
	  ,labor_cost_job
	  ,labor_cost_lab
      ,[work_order_status]
      ,[datetime_out_service]
      ,[datetime_in_service]
      ,[datetime_closed]
      ,[datetime_unit_in]
      ,[qty_est_hours]
      ,[meter_1_life_total]
      ,[meter_1_reading]
      ,[TASK_task_code]
	  ,CLASS_class_maint
	  ,CLASS_class_stds
	  ,date_entered
	  ,lab_start_time
	  ,lab_end_time
	  ,[task_type]
	  ,[task_reason]
      ,[emp_empl_no]
      ,[labor_rate]
      ,[labor_hours]
	  ,jobmain_labor_hours
	  ,labmain_labor_hours
	  ,[labor_date]
      ,[wo_task_inserted]
      ,[wo_task_calendar_id]
      ,[wo_task_yr_no]
      ,[employee_name]
      ,[eq_equip_no]
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
      ,[repair_group]
      ,[repair_group_code]
      ,[repair_category]
      ,[backupCategory]
      ,[category]
)
select [work_order_yr]
      ,[work_order_no]
      ,[estimate]
      ,[job_type]
	  ,[comml_cost] 
	  ,[warranty] 
	  ,[account_id]
	  ,indirect_flag
	  ,[wcl_work_class]
	  ,labor_cost_job
	  ,SUM(labor_cost_lab) labor_cost_lab
      ,[work_order_status]
      ,[datetime_out_service]
      ,[datetime_in_service]
      ,[datetime_closed]
      ,[datetime_unit_in]
      ,[qty_est_hours]
      ,[meter_1_life_total]
      ,[meter_1_reading]
      ,[TASK_task_code]
	  ,CLASS_class_maint
	  ,CLASS_class_stds
	  ,date_entered
	  ,lab_start_time
	  ,lab_end_time
      ,[task_type]
	  ,[task_reason]
      ,[emp_empl_no]
      ,[labor_rate]
	  ,labor_hours = sum([labmain_labor_hours])
      ,sum([jobmain_labor_hours]) jobmain_labor_hours
      ,sum([labmain_labor_hours]) labmain_labor_hours
	  ,cast([lab_date] as date) labor_date
      ,[wo_task_inserted]
      ,[wo_task_calendar_id]
      ,[wo_task_yr_no]
      ,[employee_name]
      ,[eq_equip_no]
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
      ,[repair_group]
      ,[repair_group_code]
      ,[repair_category]
      ,[backupCategory]
      ,[category] -- select * 
  FROM #stageWorkOrder
  group by
   [work_order_yr]
      ,[work_order_no]
      ,[estimate]
      ,[job_type]
	  ,[comml_cost] 
	  ,[warranty] 
	  ,[account_id]
	  ,indirect_flag
	  ,[wcl_work_class]
	  ,labor_cost_job
      ,[work_order_status]
      ,[datetime_out_service]
      ,[datetime_in_service]
      ,[datetime_closed]
      ,[datetime_unit_in]
      ,[qty_est_hours]
      ,[meter_1_life_total]
      ,[meter_1_reading]
      ,[TASK_task_code]
	  ,CLASS_class_maint
	  ,CLASS_class_stds
	  ,date_entered
	  ,cast([lab_date] as date) 
	  ,lab_start_time
	  ,lab_end_time
      ,[task_type]
	  ,[task_reason]
      ,[emp_empl_no]
      ,[labor_rate]
      ,[wo_task_inserted]
      ,[wo_task_calendar_id]
      ,[wo_task_yr_no]
      ,[employee_name]
      ,[eq_equip_no]
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
      ,[repair_group]
      ,[repair_group_code]
      ,[repair_category]
      ,[backupCategory]
      ,[category] -- select *

--declare @OutputTbl9959u table (ActionName varchar(32))
--declare @OutputTbl9959i table (ActionName varchar(32))
--declare @OutputTbl9959d table (ActionName varchar(32))

INSERT -- select * from -- truncate table 
eam.[workOrderTaskCategoryTimeExtended] (
       [work_order_yr]
      ,[work_order_no]
      ,[estimate]
      ,[job_type]
	  ,[comml_cost] 
	  ,[warranty] 
	  ,[account_id]
	  ,indirect_flag
	  ,[wcl_work_class]
	  ,labor_cost_job
	  ,labor_cost_lab
      ,[work_order_status]
      ,[datetime_out_service]
      ,[datetime_in_service]
      ,[datetime_closed]
      ,[datetime_unit_in]
      ,[qty_est_hours]
      ,[meter_1_life_total]
      ,[meter_1_reading]
      ,[TASK_task_code]
	  ,CLASS_class_maint
	  ,CLASS_class_stds
	  ,date_entered
	  ,lab_start_time
	  ,lab_end_time
      ,[task_type]
	  ,[task_reason]
      ,[emp_empl_no]
      ,[labor_rate]
      ,[labor_hours]
	  ,[labor_date]
      ,[wo_task_inserted]
      ,[wo_task_calendar_id]
      ,[wo_task_yr_no]
      ,[employee_name]
      ,[eq_equip_no]
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
      ,[repair_group]
      ,[repair_group_code]
      ,[repair_category]
      ,[backupCategory]
      ,[category] )
--OUTPUT 'INSERT' into @OutputTbl9959i
select s.[work_order_yr]
      ,s.[work_order_no]
      ,s.[estimate]
      ,isnull(s.[job_type],'Other')
	  ,s.[comml_cost] 
	  ,s.[warranty] 
	  ,s.[account_id]
	  ,s.indirect_flag
	  ,s.[wcl_work_class]
	  ,s.labor_cost_job
	  ,s.labor_cost_lab
      ,s.[work_order_status]
      ,s.[datetime_out_service]
      ,s.[datetime_in_service]
      ,s.[datetime_closed]
      ,s.[datetime_unit_in]
      ,s.[qty_est_hours]
      ,s.[meter_1_life_total]
      ,s.[meter_1_reading]
      ,isnull(s.[TASK_task_code],'Other')
	  ,s.CLASS_class_maint
	  ,s.CLASS_class_stds
	  ,s.date_entered
	  ,s.lab_start_time
	  ,s.lab_end_time
      ,s.[task_type]
	  ,s.[task_reason]
      ,isnull(s.[emp_empl_no],'Not Known') 
      ,isnull(s.[labor_rate],0)
      ,isnull(s.[labor_hours],0)
	  ,s.labor_date
      ,s.[wo_task_inserted]
      ,s.[wo_task_calendar_id]
      ,s.[wo_task_yr_no]
      ,isnull(s.[employee_name],'Not Known') 
      ,s.[eq_equip_no]
      ,s.[life_miles]
      ,s.[ltd_bus_class]
      ,s.[bio_diesel]
      ,s.[atric]
      ,s.[emx_bus]
      ,s.[hybrid]
      ,s.[electric]
      ,s.[max_fuel]
      ,s.[active]
      ,s.[unit_is_active]
      ,s.[ltd_bus_class_adj]
      ,s.[repair_group]
      ,s.[repair_group_code]
      ,isnull(s.[repair_category],'Other')
      ,s.[backupCategory]
      ,isnull(s.[category],'Other')
from [wrk].[NEWworkOrderDW] s
where not exists (select 1 from eam.[workOrderTaskCategoryTime] t where
 t.[work_order_yr] = s.[work_order_yr]
and t.[work_order_no] = s.[work_order_no]
and t.[eq_equip_no] = s.[eq_equip_no]
and t.[emp_empl_no] = isnull(s.[emp_empl_no],'Not Known')
and t.labor_date = s.labor_date
and t.labor_rate = s.labor_rate
AND t.job_type = isnull(s.job_type,'Other')
and t.task_task_code = s.task_task_code)


UPDATE t 
SET t.[wo_task_calendar_id] = s.[wo_task_calendar_id]
, t.[comml_cost] = s.[comml_cost] 
, t.[warranty] = s.[warranty] 
, t.account_id = s.[account_id]
, t.indirect_flag = s.indirect_flag
, t.[estimate] = isnull(s.[estimate],'0')
, t.[wcl_work_class] = s.[wcl_work_class] 
, t.labor_cost_job = s.labor_cost_job
, t.labor_cost_lab = s.labor_cost_lab
, t.[task_type] = s.[task_type]
, t.[task_reason] = s.[task_reason] 
, t.[work_order_status] = isnull(s.[work_order_status],'')
, t.CLASS_class_maint = s.CLASS_class_maint
, t.CLASS_class_stds = s.CLASS_class_stds
, t.date_entered = s.date_entered
, t.lab_start_time = s.lab_start_time
, t.lab_end_time = s.lab_end_time
, t.[datetime_out_service] = isnull(s.[datetime_out_service],'1990-01-01')
, t.[datetime_in_service] = isnull(s.[datetime_in_service],'1990-01-01')
, t.[datetime_closed] = isnull(s.[datetime_closed],'1990-01-01')
, t.[datetime_unit_in] = isnull(s.[datetime_unit_in],'1990-01-01')
, t.[qty_est_hours] = isnull(s.[qty_est_hours],0)
, t.[meter_1_life_total] = isnull(s.[meter_1_life_total],0)
, t.[meter_1_reading] = isnull(s.[meter_1_reading],0)
, t.[labor_hours] = isnull(s.[labor_hours],0)
, t.[wo_task_yr_no] = isnull(s.[wo_task_yr_no],'')
, t.[employee_name] = isnull(s.[employee_name],'')
, t.[life_miles] = isnull(s.[life_miles],0)
, t.[ltd_bus_class] = isnull(s.[ltd_bus_class],'')
, t.[bio_diesel] = isnull(s.[bio_diesel],0)
, t.[atric] = isnull(s.[atric],0)
, t.[emx_bus] = isnull(s.[emx_bus],0)
, t.[hybrid] = isnull(s.[hybrid],0)
, t.[electric] = isnull(s.[electric],0)
, t.[max_fuel] = isnull(s.[max_fuel],0)
, t.[active] = isnull(s.[active],'')
, t.[unit_is_active] = isnull(s.[unit_is_active],'')
, t.[ltd_bus_class_adj] = isnull(s.[ltd_bus_class_adj],'')
, t.[repair_group] = isnull(s.[repair_group],'')
, t.[repair_group_code] = isnull(s.[repair_group_code],'')
, t.[backupCategory] = isnull(s.[backupCategory],'')
, t.[Category] = isnull(s.[Category],'')
--OUTPUT 'UPDATE' into @OutputTbl9959u
from
eam.[workOrderTaskCategoryTimeExtended] t 
join [wrk].[NEWworkOrderDW] s
on  t.[work_order_yr] = s.[work_order_yr]
and t.[work_order_no] = s.[work_order_no]
and t.[eq_equip_no] = s.[eq_equip_no]
and t.[emp_empl_no] = isnull(s.[emp_empl_no],'Not Known')
and t.labor_date = s.labor_date
and t.labor_rate = s.labor_rate
AND t.job_type = isnull(s.job_type,'Other')
and isnull(t.task_task_code,'Other') = isnull(s.task_task_code,'Other')
and t.[wo_task_calendar_id] = s.[wo_task_calendar_id]
where
(  isnull(t.[estimate],'0') <> isnull(s.[estimate],'0')
OR ISNULL(t.[wcl_work_class],'') <> ISNULL(s.[wcl_work_class],'')
OR ISNULL(t.labor_cost_job,0) = ISNULL(s.labor_cost_job,0)
OR ISNULL(t.labor_cost_lab,0) = ISNULL(s.labor_cost_lab,0)
OR ISNULL(t.[comml_cost],0.00) <> ISNULL(s.[comml_cost] ,0.00)
OR ISNULL(t.[warranty],'') <> ISNULL(s.[warranty],'') 
OR ISNULL(t.[account_id],'') <> ISNULL(s.[account_id],'')
OR ISNULL(t.indirect_flag,'') <> ISNULL(s.indirect_flag,'')
OR ISNULL(t.[task_type],'') <> ISNULL(s.[task_type],'')
OR ISNULL(t.[task_reason],'') <> ISNULL(s.[task_reason],'')
OR isnull(t.[work_order_status],'') <> isnull(s.[work_order_status],'')
OR isnull(t.CLASS_class_maint,'') <> ISNULL(s.CLASS_class_maint,'')
OR isnull(t.CLASS_class_stds,'') <> ISNULL(s.CLASS_class_stds,'')
OR ISNULL(t.date_entered,'1990-01-01') <> ISNULL(s.date_entered,'1990-01-01')
OR isnull(t.lab_start_time,'1990-01-01') <> ISNULL(s.lab_start_time,'1990-01-01')
OR isnull(t.lab_end_time,'1990-01-01') <> ISNULL(s.lab_end_time,'1990-01-01')
OR isnull(t.[datetime_out_service],'1990-01-01') <> isnull(s.[datetime_out_service],'1990-01-01')
OR isnull(t.[datetime_in_service],'1990-01-01') <> isnull(s.[datetime_in_service],'1990-01-01')
OR isnull(t.[datetime_closed],'1990-01-01') <> isnull(s.[datetime_closed],'1990-01-01')
OR isnull(t.[datetime_unit_in],'1990-01-01') <> isnull(s.[datetime_unit_in],'1990-01-01')
OR isnull(t.[qty_est_hours],0) <> isnull(s.[qty_est_hours],0)
OR isnull(t.[meter_1_life_total],0) <> isnull(s.[meter_1_life_total],0)
OR isnull(t.[meter_1_reading],0) <> isnull(s.[meter_1_reading],0)
OR isnull(t.[labor_hours],0) <> isnull(s.[labor_hours],0)
OR isnull(t.[wo_task_yr_no],'') <> isnull(s.[wo_task_yr_no],'')
OR isnull(t.[employee_name],'') <> isnull(s.[employee_name],'')
OR isnull(t.[life_miles],0) <> isnull(s.[life_miles],0)
OR isnull(t.[ltd_bus_class],'') <> isnull(s.[ltd_bus_class],'')
OR isnull(t.[bio_diesel],0) <> isnull(s.[bio_diesel],0)
OR isnull(t.[atric],0) <> isnull(s.[atric],0)
OR isnull(t.[emx_bus],0) <> isnull(s.[emx_bus],0)
OR isnull(t.[hybrid],0) <> isnull(s.[hybrid],0)
OR isnull(t.[electric],0) <> isnull(s.[electric],0)
OR isnull(t.[max_fuel],0) <> isnull(s.[max_fuel],0)
OR isnull(t.[active],'') <> isnull(s.[active],'')
OR isnull(t.[unit_is_active],'') <> isnull(s.[unit_is_active],'')
OR isnull(t.[ltd_bus_class_adj],'') <> isnull(s.[ltd_bus_class_adj],'')
OR isnull(t.[repair_group],'') <> isnull(s.[repair_group],'')
OR isnull(t.[repair_group_code],'') <> isnull(s.[repair_group_code],'')
OR isnull(t.[backupCategory],'') <> isnull(s.[backupCategory],'')
OR isnull(t.[Category],'') <> isnull(s.[Category],'')
)


declare @n int = (select isnull(count(*),0) from eam.[workOrderTaskCategoryTimeExtended] where record_created_date >= CONVERT (datetime,convert(char(8),@stdt-100000000)))
declare @u int = (select isnull(count(*),0) from eam.[workOrderTaskCategoryTimeExtended] where record_updated_date >= CONVERT (datetime,convert(char(8),@stdt-100000000)))
--declare @d int = (select isnull(count(*),0) from @OutputTbl9959 where ActionName = 'Delete' group by ActionName )


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
		  'WORK', 'ltd_dw.eam.workOrderTaskCategoryTimeExtended','EAMM','ltd_dw.eam.upsert_workorder_details',  isnull( @n,0),isnull(@u,0), 0, @workstartdt, sysdatetime())

IF (SELECT COUNT(*) FROM tempdb.sys.tables WHERE name LIKE '%labmain9923%') <> 0
BEGIN
DROP TABLE ##labmain9923
END

IF (SELECT COUNT(*) FROM tempdb.sys.tables WHERE name LIKE '%jobm9923%') <> 0
BEGIN
DROP TABLE ##jobm9923
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
