SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   PROCEDURE [eam].[get_work_task_category_time]
as
-- exec eam.get_work_task_category_time

/*---------------------------------------
Standardized Business Vehicle List and Data

CREATED		20210608
AUTHOR		B EICHBERGER
PURPOSE		Prepares data and merges into [eam].[workOrderTaskCategoryTime]
			This created initially to provide data for eam_model; will eventually be cleaner fact table

-- GRANT SELECT on [eam].[workOrderTaskCategoryTime] to rpt_reader

-- waiting to hear about 'reversal' jobs/labs/tasks - possible delete batch required.

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

--declare @startdINT INT = (select convert(varchar(22),dateadd(day, -45,CONVERT(datetime,getdate())),112)+100000000 ) 			
--declare @endINT INT = (select convert(varchar(22),getdate(),112)+100000000)
				  
declare @workstartdt datetime = sysdatetime() 
-- clean up merge log in case some previous processing did not complete
update ltd_dw.[process].[MergeLogs] 
	set recInsert =  0 
	,[MergeEndDatetime] = sysdatetime()
		where mergecode = 'WORK'
			and [ObjectDestination] = 'ltd_dw.eam.workOrderTaskCategoryTime'
			AND [ObjectSource] = 'EAM'
			AND [ObjectProgram] = 'ltd_dw.eam.work_task_category_time'
			AND [MergeEndDatetime] is null
			AND (isnull(recInsert,0) = 0 or isnull(recUpdate,0) = 0 or isnull(recDelete,0) = 0)

declare @stdt int
select @stdt = (select isnull(min(sdt),120000101) from (
		(select 100000000+ cast(convert(varchar(32),max(record_created_date),112) as INT) sdt from eam.[workOrderTaskCategoryTime])
		UNION
		select 100000000+ cast(convert(varchar(32),max([record_updated_date]),112) as INT) sd from eam.[workOrderTaskCategoryTime]) o )

DECLARE @sqlcmd1 NVARCHAR(MAX)
SELECT @sqlcmd1 = '
SELECT * into ##jobm9921 FROM OPENQUERY([LTD-EAM],''select work_order_yr,work_order_no,
[datetime_out_service] = jobm9921.datetime_out_service
	,[days_out_of_service] = datediff(d, jobm9921.datetime_out_service, isnull([datetime_in_service],getdate()))
	from proto.emsdba.job_main jobm9921 WITH (NOLOCK)
	where work_order_yr > 2000
	and cast([X_datetime_insert] as date) <= cast(getdate() as date)
	or cast([X_datetime_update] as date) <= cast(getdate() as date)
	and (100000000 + cast(convert(varchar(32),(cast([X_datetime_insert] as date)),112) as INT) >= '''''+CAST(@stdt AS NVARCHAR(42))+'''''
	 or 100000000+ cast(convert(varchar(32),(cast([X_datetime_update] as date)),112) as INT)  >= '''''+CAST(@stdt AS NVARCHAR(42))+''''')
	group by work_order_yr,work_order_no,jobm9921.datetime_out_service
	,datediff(d, jobm9921.datetime_out_service, isnull([datetime_in_service],getdate()))'')'
EXEC sp_executeSQL @sqlcmd1
	
DECLARE @sqlcmd NVARCHAR(MAX) = '
select task_task_code , [hours], EMP_empl_no,labor_rate,work_order_no ,work_order_yr,lab_date,[unique_id]
--,fully_reversed,reversal_flag,
,task_type, task_reason
into ##labmain9921 
from OPENQUERY( [LTD-EAM],''SELECT L.task_task_code ,sum(L.[hours]) [hours], L.EMP_empl_no
,L.labor_rate,L.work_order_no ,L.work_order_yr,L.lab_date,L.[unique_id]--,fully_reversed,reversal_flag,
,ds.[description] AS task_type, r.[description] AS task_reason from proto.emsdba.lab_main L
INNER JOIN proto.[emsdba].[RSN_MAIN] R ON L.[REAS_reas_for_repair] = R.[REAS_reas_for_repair]
LEFT JOIN proto.[emsdba].[DES_MAIN] DS ON DS.[TASK_task_code] = L.[TASK_task_code]
 where indirect_flag = ''''N''''
   and lab_date <= cast(getdate() as date)
   and 100000000+ cast(convert(varchar(32),(cast(L.[X_datetime_insert] as date)),112) as INT) >= '''''+CAST(@stdt AS NVARCHAR(42))+'''''
group by L.task_task_code ,  L.EMP_empl_no,labor_rate, L.work_order_no , L.work_order_yr, L.lab_date, L.[unique_id],  ds.[description] , r.[description]'')'
EXEC sp_executesql @sqlcmd


-- delete from eam.[workOrderTaskCategoryTime] where fully_reversed = 'Y' and reversal_flag = 'Y'

select distinct l.task_task_code,[category] 
into #tskcat from ##labmain9921 l 
join [LTD-EAM].ltd_db.[dbo].[des_main_v] d on d.task_task_code = l.task_task_code


select tm.*,
[wo_task_inserted] = tm.X_datetime_insert
	,wo_task_calendar_id = 100000000 + cast(convert(VARCHAR(32), tm.X_datetime_insert, 112) AS INT)
	,[wo_task_yr_no] = cast(tm.work_order_yr AS CHAR(4)) + '-' + cast(tm.work_order_no AS VARCHAR(7))
,case when e.[name] not like '%ý%' then replace(e.[name],'-',',') 
	  when e.[name]  like '%ý%' then replace(replace(e.[name],'ý',','),'-','') end  employee_name
,b.*
,ltd_bus_class_adj = cast(CASE 
			WHEN ISNUMERIC(b.ltd_bus_class) = 0
			-- changed as a workaround test for eam now having additional types in the bus class column
			-- B. Eichberger 20241101 - RID 31930 Fw: ERROR: eam.get_work_task_category_time
				THEN 999999
			ELSE b.ltd_bus_class
			END AS INT),
upper(rtcc.repair_group) repair_group,
upper(rtcc.[repair_group_code]) [repair_group_code],
upper(rtcc.[category]) repair_category,
case when tcc.category = 'Other' then rtcc.category end backupCategory
, tcc.category
into #stageWorkOrder
FROM  (SELECT  j.[X_datetime_insert]
       ,j.[work_order_yr]
      ,j.[work_order_no]
      ,j.[estimate]
      ,j.[job_type]
      ,j.[EQ_equip_no] eq_equip_no_jobm9921ain
      ,j.[work_order_status]
      ,j.[datetime_out_service]
      ,j.[datetime_in_service]
      ,j.[datetime_closed]
      ,j.[datetime_unit_in]
      ,j.[qty_est_hours]
	  ,j.[meter_1_life_total]
	  ,j.[meter_1_reading]
	  ,j.[wcl_work_class] -- = '4' = road call
	  ,l.TASK_task_code
	  ,l.task_type
	  ,l.task_reason
	  ,l.EMP_empl_no emp_empl_no
	  ,l.labor_rate
	  ,l.[hours] as labor_hours
	  ,cast(l.lab_date as smalldatetime) lab_date
 FROM ##jobm9921 jobm9921 
 inner join [LTD-EAM].[proto].[emsdba].[JOB_MAIN] j WITH (NOLOCK)
 ON jobm9921.work_order_yr = j.work_order_yr
		AND jobm9921.work_order_no = j.work_order_no	
INNER JOIN ##labmain9921 l on l.work_order_no = jobm9921.work_order_no and l.work_order_yr = jobm9921.work_order_yr --and l.TASK_task_code = jobm9921v.TASK_task_code
) tm 
left join #tskcat tcc on tcc.task_task_code = tm.TASK_task_code 
INNER JOIN [LTD-EAM].ltd_db.[dbo].[bus_classes] b WITH (NOLOCK)
	ON b.eq_equip_no = tm.eq_equip_no_jobm9921ain	
LEFT JOIN ( select task_task_code as rtcc_task, repair_group_code,repair_group,category,task_type,[description] from 
	[LTD-EAM].ltd_db.[dbo].[des_main_v] WITH (NOLOCK) ) rtcc 
	ON rtcc.rtcc_task = tm.TASK_task_code 
LEFT JOIN [LTD-EAM].ltd_db.[dbo].[employee_info] e WITH (NOLOCK) on e.EMP_empl_no = tm.EMP_empl_no


IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[wrk].[workOrderDW]') AND type in (N'U'))
DROP TABLE [wrk].[workOrderDW]

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[wrk].[workOrderDW]') AND type in (N'U'))
CREATE TABLE [wrk].[workOrderDW](
	[X_datetime_insert] [DATETIME] NULL,
	[work_order_yr] [INT] NULL,
	[work_order_no] [INT] NULL,
	[estimate] [CHAR](1) NULL,
	[job_type] [VARCHAR](15) NULL,
	[wcl_work_class] VARCHAR(3) NULL,
	[eq_equip_no_jobm9921ain] [VARCHAR](20) NULL,
	[work_order_status] [VARCHAR](15) NULL,
	[datetime_out_service] [DATETIME] NULL,
	[datetime_in_service] [DATETIME] NULL,
	[datetime_closed] [DATETIME] NULL,
	[datetime_unit_in] [DATETIME] NULL,
	[qty_est_hours] [NUMERIC](12, 1) NULL,
	[meter_1_life_total] [INT] NULL,
	[meter_1_reading] [INT] NULL,
	[TASK_task_code] [VARCHAR](12) NULL,
	[task_type] VARCHAR(90) NULL,
	[task_reason] VARCHAR(90) NULL,
	[emp_empl_no] [VARCHAR](9) NULL,
	[labor_rate] [NUMERIC](12, 2) NULL,
	[labor_hours] [NUMERIC](12, 1) NULL,
	[lab_date] [DATETIME] NULL,
	[wo_task_inserted] [DATETIME] NULL,
	[wo_task_calendar_id] [INT] NULL,
	[wo_task_yr_no] [VARCHAR](12) NULL,
	[employee_name] [VARCHAR](90) NULL,
	[eq_equip_no] [VARCHAR](20) NULL,
	[life_miles] [INT] NULL,
	[ltd_bus_class] [VARCHAR](11) NOT NULL,
	[bio_diesel] [INT] NOT NULL,
	[atric] [INT] NOT NULL,
	[emx_bus] [INT] NOT NULL,
	[hybrid] [INT] NOT NULL,
	[electric] [INT] NOT NULL,
	[max_fuel] [INT] NOT NULL,
	[active] [VARCHAR](1) NOT NULL,
	[unit_is_active] [CHAR](1) NULL,
	[ltd_bus_class_adj] [INT] NULL,
	[repair_group] [VARCHAR](255) NULL,
	[repair_group_code] [VARCHAR](12) NULL,
	[repair_category] [VARCHAR](32) NULL,
	[backupCategory] [VARCHAR](32) NULL,
	[category] [VARCHAR](32) NULL
) ON [PRIMARY]
 

insert [wrk].[workOrderDW] (
[X_datetime_insert]
      ,[work_order_yr]
      ,[work_order_no]
      ,[estimate]
      ,[job_type]
	  ,[wcl_work_class]
      ,[work_order_status]
      ,[datetime_out_service]
      ,[datetime_in_service]
      ,[datetime_closed]
      ,[datetime_unit_in]
      ,[qty_est_hours]
      ,[meter_1_life_total]
      ,[meter_1_reading]
      ,[TASK_task_code]
	  ,[task_type]
	  ,[task_reason]
      ,[emp_empl_no]
      ,[labor_rate]
      ,[labor_hours]
	  ,[lab_date]
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
select [X_datetime_insert]
      ,[work_order_yr]
      ,[work_order_no]
      ,[estimate]
      ,[job_type]
	  ,[wcl_work_class]
      ,[work_order_status]
      ,[datetime_out_service]
      ,[datetime_in_service]
      ,[datetime_closed]
      ,[datetime_unit_in]
      ,[qty_est_hours]
      ,[meter_1_life_total]
      ,[meter_1_reading]
      ,[TASK_task_code]
       ,[task_type]
	  ,[task_reason]
      ,[emp_empl_no]
      ,[labor_rate]
      ,sum([labor_hours])
	  ,[lab_date] = cast([lab_date] as date)
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
  FROM #stageWorkOrder
  group by
  [X_datetime_insert]
      ,[work_order_yr]
      ,[work_order_no]
      ,[estimate]
      ,[job_type]
	  ,[wcl_work_class]
      ,[work_order_status]
      ,[datetime_out_service]
      ,[datetime_in_service]
      ,[datetime_closed]
      ,[datetime_unit_in]
      ,[qty_est_hours]
      ,[meter_1_life_total]
      ,[meter_1_reading]
      ,[TASK_task_code]
       ,[task_type]
	  ,[task_reason]
      ,[emp_empl_no]
      ,[labor_rate]
	  ,cast([lab_date] as date)
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

--declare @OutputTbl9959u table (ActionName varchar(32))
--declare @OutputTbl9959i table (ActionName varchar(32))
--declare @OutputTbl9959d table (ActionName varchar(32))

INSERT -- select * from -- truncate table 
eam.[workOrderTaskCategoryTime] (
[X_datetime_insert]
      ,[work_order_yr]
      ,[work_order_no]
      ,[estimate]
      ,[job_type]
	  ,[wcl_work_class]
      ,[work_order_status]
      ,[datetime_out_service]
      ,[datetime_in_service]
      ,[datetime_closed]
      ,[datetime_unit_in]
      ,[qty_est_hours]
      ,[meter_1_life_total]
      ,[meter_1_reading]
      ,[TASK_task_code]
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
select s.[X_datetime_insert]
      ,s.[work_order_yr]
      ,s.[work_order_no]
      ,s.[estimate]
      ,isnull(s.[job_type],'Other')
	  ,s.[wcl_work_class]
      ,s.[work_order_status]
      ,s.[datetime_out_service]
      ,s.[datetime_in_service]
      ,s.[datetime_closed]
      ,s.[datetime_unit_in]
      ,s.[qty_est_hours]
      ,s.[meter_1_life_total]
      ,s.[meter_1_reading]
      ,isnull(s.[TASK_task_code],'Other')
      ,s.[task_type]
	  ,s.[task_reason]
      ,isnull(s.[emp_empl_no],'Not Known') 
      ,isnull(s.[labor_rate],0)
      ,isnull(s.[labor_hours],0)
	  ,s.lab_date
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
from [wrk].[workOrderDW] s
where not exists (select 1 from eam.[workOrderTaskCategoryTime] t where
 t.[work_order_yr] = s.[work_order_yr]
and t.[work_order_no] = s.[work_order_no]
and t.[eq_equip_no] = s.[eq_equip_no]
and t.[emp_empl_no] = isnull(s.[emp_empl_no],'Not Known')
and t.labor_date = s.lab_date
and t.labor_rate = s.labor_rate
AND t.job_type = isnull(s.job_type,'Other')
and t.task_task_code = s.task_task_code)


UPDATE t 
SET t.[wo_task_calendar_id] = s.[wo_task_calendar_id]
, t.[estimate] = isnull(s.[estimate],'0')
, t.[wcl_work_class] = s.[wcl_work_class] 
, t.[task_type] = s.[task_type]
, t.[task_reason] = s.[task_reason] 
, t.[work_order_status] = isnull(s.[work_order_status],'')
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
eam.[workOrderTaskCategoryTime] t 
join [wrk].[workOrderDW] s
on  t.[work_order_yr] = s.[work_order_yr]
and t.[work_order_no] = s.[work_order_no]
and t.[eq_equip_no] = s.[eq_equip_no]
and t.[emp_empl_no] = isnull(s.[emp_empl_no],'Not Known')
and t.labor_date = s.lab_date
and t.labor_rate = s.labor_rate
AND t.job_type = isnull(s.job_type,'Other')
and isnull(t.task_task_code,'Other') = isnull(s.task_task_code,'Other')
and t.[wo_task_calendar_id] = s.[wo_task_calendar_id]
where
(  isnull(t.[estimate],'0') <> isnull(s.[estimate],'0')
OR ISNULL(t.[wcl_work_class],'') <> ISNULL(s.[wcl_work_class],'')
OR ISNULL(t.[task_type],'') <> ISNULL(s.[task_type],'')
OR ISNULL(t.[task_reason],'') <> ISNULL(s.[task_reason],'')
OR isnull(t.[work_order_status],'') <> isnull(s.[work_order_status],'')
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


declare @n int = (select isnull(count(*),0) from eam.[workOrderTaskCategoryTime] where record_created_date >= CONVERT (datetime,convert(char(8),@stdt-100000000)))
declare @u int = (select isnull(count(*),0) from eam.[workOrderTaskCategoryTime] where record_updated_date >= CONVERT (datetime,convert(char(8),@stdt-100000000)))
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
		  'WORK', 'ltd_dw.eam.workOrderTaskCategoryTime','EAMM','ltd_dw.eam.work_task_category_time',  isnull( @n,0),isnull(@u,0), 0, @workstartdt, sysdatetime())

IF (SELECT COUNT(*) FROM tempdb.sys.tables WHERE name LIKE '%labmain9921%') <> 0
BEGIN
DROP TABLE ##labmain9921
END

IF (SELECT COUNT(*) FROM tempdb.sys.tables WHERE name LIKE '%jobm9921%') <> 0
BEGIN
DROP TABLE ##jobm9921
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
