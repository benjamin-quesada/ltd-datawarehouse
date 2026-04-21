SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [eam].[z get_work_task_category_time_v3]
AS
-- exec eam.get_work_task_category_time_v3

/*------------LTD_GLOSSARY-----------------

CREATED		20231125
AUTHOR		B EICHBERGER
PURPOSE		Prepares data and merges into [eam].[workOrderTaskCategoryTimeExtended]
			Provide source data specifically for eam_model; 
			This version created to add multiple columns and align with SSRS draw down figures
-----*/
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

												
DECLARE @sdt DATETIME2 = SYSDATETIME()
DECLARE @outputTbl TABLE (actionNm VARCHAR(32));

declare @stdt INT = (
SELECT MIN(c.calendar_id) minCal FROM tm.DW_CALENDAR c
LEFT JOIN eam.workOrderTaskCategoryTimeExtended e ON e.calendar_id = c.CALENDAR_ID
WHERE YEAR(c.CALENDAR_DATE) >= YEAR(GETDATE())-12
AND e.calendar_id IS NULL )


declare @process_date DATETIME = '2012-07-01'
--(SELECT TOP(1) DATEADD(year,-12,ml.MergeBeginDatetime) -- pull last 30 days before known process complete
--	FROM process.MergeLogs ml
--	WHERE MergeCode = 'WORK'
--	AND ml.ObjectDestination = 'ltd_dw.eam.workOrderTaskCategoryTimeExtended'
--	AND ml.ObjectSource = 'EAMM'
--	AND ml.ObjectProgram = 'ltd_dw.eam.work_task_category_time_extended'
--	AND (ISNULL(recInsert,0) > 0 OR ISNULL(recUpdate,0) > 0 OR ISNULL(recDelete,0) > 0)
--	ORDER BY ml.MergeBeginDatetime DESC)

DECLARE @Calendar_id INT = (SELECT  c.CALENDAR_ID  FROM tm.DW_CALENDAR c WHERE c.CALENDAR_DATE = CAST(@process_date AS DATE)) /* incremental runs*/

--DECLARE @Calendar_id INT = @stdt /* 1st time run to pull all historical data */


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
                from proto.emsdba.job_main jo WITH (NOLOCK)
                where work_order_yr >= 2010
                and (cast([X_datetime_insert] as date) <= cast(getdate() as date)
                or cast([X_datetime_update] as date) <= cast(getdate() as date))
                /* and (100000000 + cast(convert(varchar(32),(cast([X_datetime_insert] as date)),112) as INT) >= '''''+CAST(@stdt AS NVARCHAR(42))+'''''
                or 100000000+ cast(convert(varchar(32),(cast([X_datetime_update] as date)),112) as INT)  >= '''''+CAST(@stdt AS NVARCHAR(42))+''''') */
				 and (100000000 + cast(convert(varchar(32),(cast([X_datetime_insert] as date)),112) as INT) >= '''''+CAST(@Calendar_id AS NVARCHAR(42))+'''''
                or 100000000+ cast(convert(varchar(32),(cast([X_datetime_update] as date)),112) as INT)  >= '''''+CAST(@Calendar_id AS NVARCHAR(42))+''''')  
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
,row_id, group_row_id
into ##labmain9923 
from OPENQUERY( [LTD-EAM],''SELECT L.task_task_code ,sum(L.[hours]) [hours], L.EMP_empl_no
,L.labor_rate,L.work_order_no ,L.work_order_yr,L.lab_date,L.[unique_id], L.X_datetime_insert
,lab_start_datetime as lab_start_time, lab_end_datetime as lab_end_time, indirect_flag
,CLASS_class_maint,CLASS_class_stds, cost
--,fully_reversed,reversal_flag,
,ds.[description] AS task_type, r.[description] AS task_reason
, l.row_id, l.group_row_id
from proto.emsdba.lab_main L
LEFT JOIN proto.[emsdba].[RSN_MAIN] R ON L.[REAS_reas_for_repair] = R.[REAS_reas_for_repair]
LEFT JOIN proto.[emsdba].[DES_MAIN] DS ON DS.[TASK_task_code] = L.[TASK_task_code]
where fully_reversed = ''''N''''
                                                AND posting_complete = ''''Y''''
                                                AND RTRIM(LTRIM(EQ_equip_no)) <> ''''''''
                                                AND ISNUMERIC(CLASS_class_maint) = 1
   and lab_date <= cast(getdate() as date)
   and year(lab_date) >= 2010
   and 100000000+ cast(convert(varchar(32),(cast(L.[X_datetime_insert] as date)),112) as INT) >= '''''+CAST(@Calendar_id AS NVARCHAR(42))+'''''
group by L.task_task_code,ds.[description], r.[description], L.EMP_empl_no,labor_rate,cost, L.work_order_no , L.work_order_yr
                  , L.lab_date, L.[unique_id],CLASS_class_maint,CLASS_class_stds, indirect_flag,L.X_datetime_insert, l.row_id, l.group_row_id
,lab_start_datetime, lab_end_datetime, ds.[description], r.[description]'')'
--PRINT @sqlcmd
EXEC sp_executesql @sqlcmd

--select min(work_order_yr) minYr from ##labmain9923

-- delete from eam.[workOrderTaskCategoryTime] where fully_reversed = 'Y' and reversal_flag = 'Y'
DROP TABLE IF EXISTS #tskcat
select distinct l.task_task_code,category 
into #tskcat from ##labmain9923 l 
join [LTD-EAM].ltd_db.dbo.des_main_v d on d.task_task_code = l.task_task_code

DROP TABLE IF EXISTS #stageWorkOrder

select tm.*,
wo_task_inserted = tm.X_datetime_insert
                ,wo_task_calendar_id = 100000000 + cast(convert(VARCHAR(32), tm.X_datetime_insert, 112) AS INT)
                ,wo_task_yr_no = cast(tm.work_order_yr AS CHAR(4)) + '-' + cast(tm.work_order_no AS VARCHAR(7))
,case when e.name not like '%ý%' then replace(e.name,'-',',') 
                  when e.name  like '%ý%' then replace(replace(e.name,'ý',','),'-','') end  employee_name
, b.life_miles, b.ltd_bus_class, b.bio_diesel, b.atric, b.emx_bus, b.hybrid, b.electric, b.max_fuel, b.active, b.unit_is_active
,ltd_bus_class_adj = cast(CASE WHEN b.ltd_bus_class = 'unknown' THEN 999999
                               ELSE b.ltd_bus_class END AS INT),
upper(rtcc.repair_group) repair_group,
upper(rtcc.repair_group_code) repair_group_code,
upper(rtcc.category) repair_category,
case when tcc.category = 'Other' then rtcc.category end backupCategory
, tcc.category
--, tm.row_id, tm.group_row_id
into #stageWorkOrder
FROM  (
SELECT jobm9923.X_datetime_insert
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
      ,jobm9923.wcl_work_class -- = '4' = road call
      ,l.date_entered
      ,l.lab_date as labor_date
      ,l.TASK_task_code
	  ,l.unique_id
      ,l.CLASS_class_maint,l.CLASS_class_stds
	 ,l.lab_start_time,l.lab_end_time
     ,l.task_type
     ,l.task_reason
     ,l.EMP_empl_no emp_empl_no
     ,l.labor_rate
     ,labor_cost_job = jobm9923.labor_cost
     ,labor_cost_lab = l.lab_cost
     ,jobm9923.jobmain_labor_hours
     ,l.hours labmain_labor_hours
     ,jobm9923.comml_cost
     ,jobm9923.warranty
     ,jobm9923.acct_acct_code AS account_id
     ,cast(l.lab_date as smalldatetime) lab_date
     ,l.indirect_flag
FROM ##jobm9923 jobm9923 
INNER JOIN ##labmain9923 l on l.work_order_no = jobm9923.work_order_no and l.work_order_yr = jobm9923.work_order_yr --and l.TASK_task_code = jobm9923v.TASK_task_code
) tm 
left join #tskcat tcc on tcc.task_task_code = tm.TASK_task_code 
INNER JOIN [LTD-EAM].ltd_db.dbo.bus_classes b WITH (NOLOCK)
                ON b.eq_equip_no = tm.eq_equip_no   
LEFT JOIN ( SELECT task_task_code as rtcc_task, repair_group_code,repair_group,category,task_type,[description] from 
                [LTD-EAM].ltd_db.dbo.des_main_v WITH (NOLOCK) WHERE repair_group LIKE '%road%' ) rtcc 
                ON rtcc.rtcc_task = tm.TASK_task_code 
LEFT JOIN [LTD-EAM].ltd_db.dbo.employee_info e WITH (NOLOCK) on e.EMP_empl_no = tm.EMP_empl_no

--SELECT * FROM #stageWorkOrder

DROP TABLE IF EXISTS wrk.NewWorkOrderDW

--IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[wrk].[NewWorkOrderDW]') AND type in (N'U'))
CREATE TABLE wrk.NewWorkOrderDW(
                work_order_yr int NULL,
                work_order_no INT NULL,
                calendar_id INT NOT NULL,
                estimate CHAR(1) NULL,
                job_type VARCHAR(15) NULL,
                comml_cost NUMERIC(12, 4) NULL,
                warranty VARCHAR(7) NULL,
                account_id VARCHAR(30) NULL,
                indirect_flag VARCHAR(1) NULL,
                wcl_work_class VARCHAR(3) NULL,
                labor_cost_job NUMERIC(12,4) NULL,
                labor_cost_lab NUMERIC(12,4) NULL,
                work_order_status VARCHAR(15) NULL,
                datetime_out_service DATETIME NULL,
                datetime_in_service DATETIME NULL,
                datetime_closed DATETIME NULL,
                datetime_unit_in DATETIME NULL,
                qty_est_hours NUMERIC(12, 2) NULL,
                meter_1_life_total INT NULL,
                meter_1_reading INT NULL,
                TASK_task_code VARCHAR(12) NULL,
                CLASS_class_maint VARCHAR(12) NULL,
                CLASS_class_stds VARCHAR(12) NULL,
                date_entered DATETIME NULL,
                lab_start_time DATETIME NULL,
                lab_end_time DATETIME NULL,
                task_type VARCHAR(90) NULL,
                task_reason VARCHAR(90) NULL,
                emp_empl_no VARCHAR(9) NULL,
                labor_rate NUMERIC(12, 2) NULL,
                labor_hours NUMERIC(12, 2) NULL,
                jobmain_labor_hours NUMERIC(12, 2) NULL,
                labmain_labor_hours NUMERIC(12, 2) NULL,
                labor_date DATE NULL,
                wo_task_inserted DATETIME NULL,
                wo_task_calendar_id INT NULL,
                wo_task_yr_no VARCHAR(12) NULL,
                employee_name VARCHAR(122) NULL,
                eq_equip_no VARCHAR(20) NULL,
                life_miles INT NULL,
                ltd_bus_class VARCHAR(12) NOT NULL,
                bio_diesel INT NOT NULL,
                atric INT NOT NULL,
                emx_bus INT NOT NULL,
                hybrid INT NOT NULL,
                electric INT NOT NULL,
                max_fuel INT NOT NULL,
                active VARCHAR(1) NOT NULL,
                unit_is_active CHAR(1) NULL,
                ltd_bus_class_adj INT NULL,
                repair_group VARCHAR(255) NULL,
                repair_group_code VARCHAR(12) NULL,
                repair_category VARCHAR(28) NULL,
                backupCategory VARCHAR(28) NULL,
                task_code VARCHAR(12) NULL,
                category VARCHAR(28) NULL,
				--[row_id] INT NOT NULL,
				--[group_row_id] INT NOT NULL,
				unique_id VARCHAR(25)
) ON [PRIMARY]


INSERT wrk.NewWorkOrderDW (
	work_order_yr
	,work_order_no
	,calendar_id
	,estimate
	,job_type
	,comml_cost 
	,warranty 
	,account_id 
	,indirect_flag
	,wcl_work_class
	,labor_cost_job
	,labor_cost_lab
	,work_order_status
	,datetime_out_service
	,datetime_in_service
	,datetime_closed
	,datetime_unit_in
	,qty_est_hours
	,meter_1_life_total
	,meter_1_reading
	,TASK_task_code
	,CLASS_class_maint
	,CLASS_class_stds
	,date_entered
	,lab_start_time
	,lab_end_time
	,task_type
	,task_reason
	,emp_empl_no
	,labor_rate
	,labor_hours
	,jobmain_labor_hours
	,labmain_labor_hours
	,labor_date
	,wo_task_inserted
	,wo_task_calendar_id
	,wo_task_yr_no
	,employee_name
	,eq_equip_no
	,life_miles
	,ltd_bus_class
	,bio_diesel
	,atric
	,emx_bus
	,hybrid
	,electric
	,max_fuel
	,active
	,unit_is_active
	,ltd_bus_class_adj
	,repair_group
	,repair_group_code
	,repair_category
	,backupCategory
	,category
	--,row_id
	--,group_row_id
	,unique_id
)
SELECT work_order_yr
	,work_order_no
	,calendar_id
	,estimate
	,job_type
	,comml_cost 
	,warranty 
	,account_id
	,indirect_flag
	,wcl_work_class
	,labor_cost_job
	,SUM(labor_cost_lab) labor_cost_lab
	,work_order_status
	,datetime_out_service
	,datetime_in_service
	,datetime_closed
	,datetime_unit_in
	,qty_est_hours
	,meter_1_life_total
	,meter_1_reading
	,TASK_task_code
	,CLASS_class_maint
	,CLASS_class_stds
	,date_entered
	,lab_start_time
	,lab_end_time
	,task_type
	,task_reason
	,emp_empl_no
	,labor_rate
	,labor_hours = SUM(labmain_labor_hours)
	,SUM(jobmain_labor_hours) jobmain_labor_hours
	,SUM(labmain_labor_hours) labmain_labor_hours
	,CAST(lab_date AS DATE) labor_date
	,wo_task_inserted
	,wo_task_calendar_id
	,wo_task_yr_no
	,employee_name
	,eq_equip_no
	,life_miles
	,ltd_bus_class
	,bio_diesel
	,atric
	,emx_bus
	,hybrid
	,electric
	,max_fuel
	,active
	,unit_is_active
	,ltd_bus_class_adj
	,repair_group
	,repair_group_code
	,repair_category
	,backupCategory
	,category 
	--,row_id
	--,group_row_id
	,unique_id
	-- select top 10 * 
FROM #stageWorkOrder
GROUP BY
	work_order_yr
	,work_order_no
	,calendar_id
	,estimate
	,job_type
	,comml_cost 
	,warranty 
	,account_id
	,indirect_flag
	,wcl_work_class
	,labor_cost_job
	,work_order_status
	,datetime_out_service
	,datetime_in_service
	,datetime_closed
	,datetime_unit_in
	,qty_est_hours
	,meter_1_life_total
	,meter_1_reading
	,TASK_task_code
	,CLASS_class_maint
	,CLASS_class_stds
	,date_entered
	,CAST(lab_date AS DATE) 
	,lab_start_time
	,lab_end_time
	,task_type
	,task_reason
	,emp_empl_no
	,labor_rate
	,wo_task_inserted
	,wo_task_calendar_id
	,wo_task_yr_no
	,employee_name
	,eq_equip_no
	,life_miles
	,ltd_bus_class
	,bio_diesel
	,atric
	,emx_bus
	,hybrid
	,electric
	,max_fuel
	,active
	,unit_is_active
	,ltd_bus_class_adj
	,repair_group
	,repair_group_code
	,repair_category
	,backupCategory
	,category
	--,row_id
	--,group_row_id
	,unique_id
	-- select *


--SELECT * FROM eam.workOrderTaskCategoryTimeExtended

MERGE eam.workOrderTaskCategoryTimev3 AS t
USING wrk.NewWorkOrderDW  AS s
ON ( t.calendar_id = s.wo_task_calendar_id
	AND t.work_order_yr = s.work_order_yr
	and t.work_order_no = s.work_order_no
	and t.eq_equip_no = s.eq_equip_no
	and t.emp_empl_no = s.emp_empl_no
	and t.labor_date = s.labor_date
	and t.task_task_code = s.task_task_code
	AND t.wo_task_yr_no = s.wo_task_yr_no
	AND t.unique_id = s.unique_id )
WHEN MATCHED AND (
   ISNULL(t.estimate, '') <> ISNULL(s.estimate, '')
OR ISNULL(t.job_type, '') <> ISNULL(s.job_type, '')
OR ISNULL(t.comml_cost, '') <> ISNULL(s.comml_cost, '')
OR ISNULL(t.warranty, '') <> ISNULL(s.warranty, '')
OR ISNULL(t.account_id, '') <> ISNULL(s.account_id, '')
OR ISNULL(t.indirect_flag, '') <> ISNULL(s.indirect_flag, '')
OR ISNULL(t.wcl_work_class, '') <> ISNULL(s.wcl_work_class, '')
OR ISNULL(t.labor_cost_job, '') <> ISNULL(s.labor_cost_job, '')
OR ISNULL(t.labor_cost_lab, '') <> ISNULL(s.labor_cost_lab, '')
OR ISNULL(t.work_order_status, '') <> ISNULL(s.work_order_status, '')
OR ISNULL(t.datetime_out_service, '') <> ISNULL(s.datetime_out_service, '')
OR ISNULL(t.datetime_in_service, '') <> ISNULL(s.datetime_in_service, '')
OR ISNULL(t.datetime_closed, '') <> ISNULL(s.datetime_closed, '')
OR ISNULL(t.datetime_unit_in, '') <> ISNULL(s.datetime_unit_in, '')
OR ISNULL(t.qty_est_hours, '') <> ISNULL(s.qty_est_hours, '')
OR ISNULL(t.meter_1_life_total, '') <> ISNULL(s.meter_1_life_total, '')
OR ISNULL(t.meter_1_reading, '') <> ISNULL(s.meter_1_reading, '')
OR ISNULL(t.CLASS_class_maint, '') <> ISNULL(s.CLASS_class_maint, '')
OR ISNULL(t.CLASS_class_stds, '') <> ISNULL(s.CLASS_class_stds, '')
OR ISNULL(t.date_entered, '') <> ISNULL(s.date_entered, '')
OR ISNULL(t.lab_start_time, '') <> ISNULL(s.lab_start_time, '')
OR ISNULL(t.lab_end_time, '') <> ISNULL(s.lab_end_time, '')
OR ISNULL(t.task_type, '') <> ISNULL(s.task_type, '')
OR ISNULL(t.task_reason, '') <> ISNULL(s.task_reason, '')
OR ISNULL(t.labor_rate, '') <> ISNULL(s.labor_rate, '')
OR ISNULL(t.labor_hours, '') <> ISNULL(s.labor_hours, '')
OR ISNULL(t.jobmain_labor_hours, '') <> ISNULL(s.jobmain_labor_hours, '')
OR ISNULL(t.labmain_labor_hours, '') <> ISNULL(s.labmain_labor_hours, '')
OR ISNULL(t.wo_task_inserted, '') <> ISNULL(s.wo_task_inserted, '')
OR ISNULL(t.wo_task_calendar_id, '') <> ISNULL(s.wo_task_calendar_id, '')
OR ISNULL(t.life_miles, '') <> ISNULL(s.life_miles, '')
OR ISNULL(t.ltd_bus_class, '') <> ISNULL(s.ltd_bus_class, '')
OR ISNULL(t.bio_diesel, '') <> ISNULL(s.bio_diesel, '')
OR ISNULL(t.atric, '') <> ISNULL(s.atric, '')
OR ISNULL(t.emx_bus, '') <> ISNULL(s.emx_bus, '')
OR ISNULL(t.hybrid, '') <> ISNULL(s.hybrid, '')
OR ISNULL(t.electric, '') <> ISNULL(s.electric, '')
OR ISNULL(t.max_fuel, '') <> ISNULL(s.max_fuel, '')
OR ISNULL(t.active, '') <> ISNULL(s.active, '')
OR ISNULL(t.unit_is_active, '') <> ISNULL(s.unit_is_active, '')
OR ISNULL(t.ltd_bus_class_adj, '') <> ISNULL(s.ltd_bus_class_adj, '')
OR ISNULL(t.repair_group, '') <> ISNULL(s.repair_group, '')
OR ISNULL(t.repair_group_code, '') <> ISNULL(s.repair_group_code, '')
OR ISNULL(t.repair_category, '') <> ISNULL(s.repair_category, '')
OR ISNULL(t.backupCategory, '') <> ISNULL(s.backupCategory, '')
OR ISNULL(t.task_code, '') <> ISNULL(s.task_code, '')
OR ISNULL(t.category, '') <> ISNULL(s.category, '')
)
THEN UPDATE SET t.estimate = s.estimate
	,t.job_type = s.job_type
	,t.comml_cost = s.comml_cost
	,t.warranty = s.warranty
	,t.account_id = s.account_id
	,t.indirect_flag = s.indirect_flag
	,t.wcl_work_class = s.wcl_work_class
	,t.labor_cost_job = s.labor_cost_job
	,t.labor_cost_lab = s.labor_cost_lab
	,t.work_order_status = s.work_order_status
	,t.datetime_out_service = s.datetime_out_service
	,t.datetime_in_service = s.datetime_in_service
	,t.datetime_closed = s.datetime_closed
	,t.datetime_unit_in = s.datetime_unit_in
	,t.qty_est_hours = s.qty_est_hours
	,t.meter_1_life_total = s.meter_1_life_total
	,t.meter_1_reading = s.meter_1_reading
	,t.CLASS_class_maint = s.CLASS_class_maint
	,t.CLASS_class_stds = s.CLASS_class_stds
	,t.date_entered = s.date_entered
	,t.lab_start_time = s.lab_start_time
	,t.lab_end_time = s.lab_end_time
	,t.task_type = s.task_type
	,t.task_reason = s.task_reason
	,t.emp_empl_no = s.emp_empl_no
	,t.labor_rate = s.labor_rate
	,t.labor_hours = s.labor_hours
	,t.jobmain_labor_hours = s.jobmain_labor_hours
	,t.labmain_labor_hours = s.labmain_labor_hours
	,t.wo_task_inserted = s.wo_task_inserted
	,t.wo_task_calendar_id = s.wo_task_calendar_id
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
	,t.repair_group = s.repair_group
	,t.repair_group_code = s.repair_group_code
	,t.repair_category = s.repair_category
	,t.backupCategory = s.backupCategory
	,t.task_code = s.task_code
	,t.category = s.category
	,t.record_updated_date = SYSDATETIME()
WHEN NOT MATCHED BY TARGET
THEN INSERT
(	calendar_id
	,work_order_yr
	,work_order_no
	,estimate
	,job_type
	,comml_cost
	,warranty
	,account_id
	,indirect_flag
	,wcl_work_class
	,labor_cost_job
	,labor_cost_lab
	,work_order_status
	,datetime_out_service
	,datetime_in_service
	,datetime_closed
	,datetime_unit_in
	,qty_est_hours
	,meter_1_life_total
	,meter_1_reading
	,TASK_task_code
	,CLASS_class_maint
	,CLASS_class_stds
	,date_entered
	,lab_start_time
	,lab_end_time
	,task_type
	,task_reason
	,emp_empl_no
	,labor_rate
	,labor_hours
	,jobmain_labor_hours
	,labmain_labor_hours
	,labor_date
	,wo_task_inserted
	,wo_task_calendar_id
	,wo_task_yr_no
	,employee_name
	,eq_equip_no
	,life_miles
	,ltd_bus_class
	,bio_diesel
	,atric
	,emx_bus
	,hybrid
	,electric
	,max_fuel
	,active
	,unit_is_active
	,ltd_bus_class_adj
	,repair_group
	,repair_group_code
	,repair_category
	,backupCategory
	,task_code
	,category
	,unique_id
)
VALUES
(s.calendar_id, s.work_order_yr, s.work_order_no, s.estimate, s.job_type, s.comml_cost, s.warranty, s.account_id, s.indirect_flag, s.wcl_work_class, s.labor_cost_job, s.labor_cost_lab, s.work_order_status, s.datetime_out_service, s.datetime_in_service, s.datetime_closed, s.datetime_unit_in, s.qty_est_hours, s.meter_1_life_total, s.meter_1_reading, s.TASK_task_code, s.CLASS_class_maint, s.CLASS_class_stds, s.date_entered, s.lab_start_time, s.lab_end_time, s.task_type, s.task_reason, s.emp_empl_no, s.labor_rate, s.labor_hours, s.jobmain_labor_hours, s.labmain_labor_hours, s.labor_date, s.wo_task_inserted, s.wo_task_calendar_id, s.wo_task_yr_no, s.employee_name, s.eq_equip_no, s.life_miles, s.ltd_bus_class, s.bio_diesel, s.atric, s.emx_bus, s.hybrid, s.electric, s.max_fuel, s.active, s.unit_is_active, s.ltd_bus_class_adj, s.repair_group, s.repair_group_code, s.repair_category, s.backupCategory, s.task_code, s.category, s.unique_id)
WHEN NOT MATCHED BY SOURCE THEN delete
OUTPUT $action INTO @outputTbl;


DECLARE @ins INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'INSERT')
DECLARE @upd INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'UPDATE')
DECLARE @del INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'DELETE')
DECLARE @prg varchar(90) = @@SERVERNAME + '.ltd_dw.eam.get_work_task_category_time_v3' 

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
'ltd_dw.eam.workOrderTaskCategoryTimev3',
'EAM',
@prg,
ISNULL(@ins,0) ,ISNULL(@upd,0),ISNULL(@del,0),
@sdt,
SYSDATETIME()


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
