SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   PROCEDURE [eam].[task_category_time]
-- grant execute on [eam].[task_category_time] to "LTD\SQL_DW"
as
-- exec  eam.task_category_time

/* ------------------LTD_GLOSSARY---------------
UPDATED BY:	Sopheap Suy
UPDATED DT:  10/31/2024
purpose	 :  Add object activities on who, what, when call this object
			write this data to aud.object_activity table everytime it's called */

SET NOCOUNT ON

INSERT INTO DBA.[aud].[Object_Activity]
	([server_name], [database_name] ,[host_name], [System_User], [object_name]
	,[client_net_address], [local_net_address], [auth_Scheme], [last_read], [last_write]
	,[most_recent_sql_handle], [Timestamp], object_type)
SELECT DISTINCT @@SERVERNAME, DB_NAME(),HOST_NAME(),SYSTEM_USER, 'eam.task_category_time',
	client_net_address, local_net_address , auth_Scheme, last_read, last_write 
	,most_recent_sql_handle, CURRENT_TIMESTAMP AS [Timestamp], 'PROC'
FROM sys.dm_exec_connections 
WHERE session_id = @@SPID ;

select work_order_yr,work_order_no,
[datetime_out_service] = jobm.datetime_out_service
	,[days_out_of_service] = datediff(d, jobm.datetime_out_service, getdate())
	into #jobm 
	from [LTD-EAM].proto.emsdba.job_main jobm WITH (NOLOCK)
	where work_order_yr >= year(getdate())-5
	-- select * from #jobm
CREATE NONCLUSTERED INDEX [tmp_jobm]
ON #jobm ([work_order_yr],[work_order_no])


select * into #labmain from [LTD-EAM].proto.emsdba.lab_main
 where indirect_flag = 'N'
   and year(lab_date) >= year(getdate())-5
   and lab_date <= getdate()

select [task_code] = task_task_code 
      ,[category]  = case when task_task_code like '45%' then 'Road Call'
                          when task_task_code like '42%' then 'Road Test'
                          when task_task_code not like 'ind%' and task_task_code <> 'pit' and task_task_code like '[a-z]%' then 'Prevententive Maintenance'
                          when task_task_code like '10%' then 'Wheel Chair Lift Systems'
                          when task_task_code like '11%' then 'Wheel Chair Lift Systems'
                          when task_task_code like '12%' then 'Wheel Chair Lift Systems'
                          when task_task_code like '15%' then 'Wheel Chair Lift Systems'
                          when task_task_code like '20%' then 'Axle, Suspension, Steering'
                          when task_task_code like '21%' then 'Axle, Suspension, Steering'
                          when task_task_code like '22%' then 'Axle, Suspension, Steering'
                          when task_task_code like '24%' then 'Axle, Suspension, Steering'
                          when task_task_code like '25%' then 'Axle, Suspension, Steering'
                          when task_task_code like '23%' then 'Brakes'
                          when task_task_code like '61%' then 'Brakes'
                          when task_task_code like '62%' then 'Brakes'
                          when task_task_code like '63%' then 'Brakes'
                          when task_task_code like '26%' then 'Tires'
                          when task_task_code like '52%' then 'Vehicle ITS Components'
                          when task_task_code =    '70D' then 'Vehicle ITS Components'
                          when task_task_code =    '70H' then 'Vehicle ITS Components'
                          when task_task_code =    '70M' then 'Vehicle ITS Components'
                          when task_task_code =    '70N' then 'Vehicle ITS Components'
                          when task_task_code like '77%' then 'Vehicle ITS Components'
                          when task_task_code like '30%' then 'Body and Glass'
                          when task_task_code like '31%' then 'Body and Glass'
                          when task_task_code like '32%' then 'Body and Glass'
                          when task_task_code like '34%' then 'Body and Glass'
                          when task_task_code like '33%' then 'Passenger Doors'
                          when task_task_code =    '70A' then 'Electrical Systems'
                          when task_task_code =    '70B' then 'Electrical Systems'
                          when task_task_code =    '70C' then 'Electrical Systems'
                          when task_task_code =    '70F' then 'Electrical Systems'
                          when task_task_code =    '70G' then 'Electrical Systems'
                          when task_task_code =    '70I' then 'Electrical Systems'
                          when task_task_code =    '70L' then 'Electrical Systems'
                          when task_task_code =    '70Y' then 'Electrical Systems'
                          when task_task_code like '71%' then 'Electrical Systems'
                          when task_task_code like '72%' then 'Electrical Systems'
                          when task_task_code like '73%' then 'Electrical Systems'
                          when task_task_code like '74%' then 'Electrical Systems'
                          when task_task_code like '75%' then 'Electrical Systems'
                          when task_task_code like '76%' then 'Electrical Systems'
                          when task_task_code like '78%' then 'Electronic Control Systems'
                          when task_task_code like '80%' then 'Diesel Engines'
                          when task_task_code like '81%' then 'Diesel Engines'
                          when task_task_code like '82%' then 'Diesel Engines'
                          when task_task_code like '83%' then 'Diesel Engines'
                          when task_task_code like '84%' then 'Diesel Engines'
                          when task_task_code like '85%' then 'Diesel Engines'
                          when task_task_code like '86%' then 'Diesel Engines'
                          when task_task_code like '87%' then 'Diesel Engines'
                          when task_task_code like '90%' then 'Transmissions'
                          when task_task_code like '91%' then 'Transmissions'
                          when task_task_code like '92%' then 'Transmissions'
                          when task_task_code like '93%' then 'Transmissions'
                          when task_task_code like '94%' then 'Transmissions'
                          when task_task_code like '95%' then 'Transmissions'
                          when task_task_code like '53%' then 'Environmental Systems'
                          when task_task_code like '40%' then 'Cleaning and Washing Systems'
                                                         else 'Other'
                    end
into #tskcat from #labmain
group by 
task_task_code , case when task_task_code like '45%' then 'Road Call'
                          when task_task_code like '42%' then 'Road Test'
                          when task_task_code not like 'ind%' and task_task_code <> 'pit' and task_task_code like '[a-z]%' then 'Prevententive Maintenance'
                          when task_task_code like '10%' then 'Wheel Chair Lift Systems'
                          when task_task_code like '11%' then 'Wheel Chair Lift Systems'
                          when task_task_code like '12%' then 'Wheel Chair Lift Systems'
                          when task_task_code like '15%' then 'Wheel Chair Lift Systems'
                          when task_task_code like '20%' then 'Axle, Suspension, Steering'
                          when task_task_code like '21%' then 'Axle, Suspension, Steering'
                          when task_task_code like '22%' then 'Axle, Suspension, Steering'
                          when task_task_code like '24%' then 'Axle, Suspension, Steering'
                          when task_task_code like '25%' then 'Axle, Suspension, Steering'
                          when task_task_code like '23%' then 'Brakes'
                          when task_task_code like '61%' then 'Brakes'
                          when task_task_code like '62%' then 'Brakes'
                          when task_task_code like '63%' then 'Brakes'
                          when task_task_code like '26%' then 'Tires'
                          when task_task_code like '52%' then 'Vehicle ITS Components'
                          when task_task_code =    '70D' then 'Vehicle ITS Components'
                          when task_task_code =    '70H' then 'Vehicle ITS Components'
                          when task_task_code =    '70M' then 'Vehicle ITS Components'
                          when task_task_code =    '70N' then 'Vehicle ITS Components'
                          when task_task_code like '77%' then 'Vehicle ITS Components'
                          when task_task_code like '30%' then 'Body and Glass'
                          when task_task_code like '31%' then 'Body and Glass'
                          when task_task_code like '32%' then 'Body and Glass'
                          when task_task_code like '34%' then 'Body and Glass'
                          when task_task_code like '33%' then 'Passenger Doors'
                          when task_task_code =    '70A' then 'Electrical Systems'
                          when task_task_code =    '70B' then 'Electrical Systems'
                          when task_task_code =    '70C' then 'Electrical Systems'
                          when task_task_code =    '70F' then 'Electrical Systems'
                          when task_task_code =    '70G' then 'Electrical Systems'
                          when task_task_code =    '70I' then 'Electrical Systems'
                          when task_task_code =    '70L' then 'Electrical Systems'
                          when task_task_code =    '70Y' then 'Electrical Systems'
                          when task_task_code like '71%' then 'Electrical Systems'
                          when task_task_code like '72%' then 'Electrical Systems'
                          when task_task_code like '73%' then 'Electrical Systems'
                          when task_task_code like '74%' then 'Electrical Systems'
                          when task_task_code like '75%' then 'Electrical Systems'
                          when task_task_code like '76%' then 'Electrical Systems'
                          when task_task_code like '78%' then 'Electronic Control Systems'
                          when task_task_code like '80%' then 'Diesel Engines'
                          when task_task_code like '81%' then 'Diesel Engines'
                          when task_task_code like '82%' then 'Diesel Engines'
                          when task_task_code like '83%' then 'Diesel Engines'
                          when task_task_code like '84%' then 'Diesel Engines'
                          when task_task_code like '85%' then 'Diesel Engines'
                          when task_task_code like '86%' then 'Diesel Engines'
                          when task_task_code like '87%' then 'Diesel Engines'
                          when task_task_code like '90%' then 'Transmissions'
                          when task_task_code like '91%' then 'Transmissions'
                          when task_task_code like '92%' then 'Transmissions'
                          when task_task_code like '93%' then 'Transmissions'
                          when task_task_code like '94%' then 'Transmissions'
                          when task_task_code like '95%' then 'Transmissions'
                          when task_task_code like '53%' then 'Environmental Systems'
                          when task_task_code like '40%' then 'Cleaning and Washing Systems'
                                                         else 'Other'
                    end

select tm.*,
[wo_task_inserted] = tm.X_datetime_insert
	,wo_task_calendar_id = 100000000 + cast(convert(VARCHAR(32), tm.X_datetime_insert, 112) AS INT)
	,[wo_task_yr_no] = cast(tm.work_order_yr AS CHAR(4)) + '-' + cast(tm.work_order_no AS VARCHAR(7))
--,tm.EMP_empl_no
,case when e.[name] not like '%ý%' then replace(e.[name],'-',',') 
	  when e.[name]  like '%ý%' then replace(replace(e.[name],'ý',','),'-','') end  employee_name
--,ta.qty_labor_hrs_est
--,ta.qty_labor_hrs_chargd
,b.*
,ltd_bus_class_adj = cast(CASE 
			WHEN b.ltd_bus_class = 'unknown'
				THEN 999999
			ELSE b.ltd_bus_class
			END AS INT),
upper(rtcc.repair_group) repair_group,
upper(rtcc.[repair_group_code]) [repair_group_code],
upper(rtcc.[category]) repair_category,
case when tcc.category = 'Other' then rtcc.category end backupCategory
, tcc.*
FROM  (SELECT  j.[X_datetime_insert]
       ,j.[work_order_yr]
      ,j.[work_order_no]
      ,j.[estimate]
      ,j.[job_type]
      ,j.[EQ_equip_no]
      ,j.[work_order_status]
      ,j.[datetime_out_service]
      ,j.[datetime_in_service]
      ,j.[datetime_closed]
      ,j.[datetime_unit_in]
     ,j.[qty_est_hours]
	  ,t.TASK_task_code
	  ,coalesce(t.EMP_empl_no,l.EMP_empl_no) emp_empl_no
	  ,l.labor_rate
	--,avg(l.[hours]) OVER (PARTITION BY j.work_order_no,
	--	j.work_order_yr,
	--	t.TASK_TASK_CODE order by j.[X_datetime_insert] ROWS BETWEEN 30 PRECEDING and CURRENT ROW ) RollingAvgHoursByTask
	-- ,avg(l.[hours]) OVER (PARTITION BY j.work_order_no,
	--	j.work_order_yr,
	--	t.TASK_TASK_CODE, coalesce(t.EMP_empl_no,l.EMP_empl_no) order by j.[X_datetime_insert] ROWS BETWEEN 30 PRECEDING and CURRENT ROW ) RollingAvgHoursByTaskEmpNo
	  ,l.[hours] labor_hours
  FROM [LTD-EAM].[proto].[emsdba].[JOB_MAIN] j
  join [LTD-EAM].[proto].[emsdba].[TSK_MAIN] t on t.work_order_no = j.work_order_no and t.work_order_yr = j.work_order_yr
  left join [LTD-EAM].[proto].[emsdba].[LAB_MAIN] l on l.work_order_no = t.work_order_no and l.work_order_yr = t.work_order_yr and l.TASK_task_code = t.TASK_task_code
  where work_order_status = 'CLOSED'
  and isnull(l.[hours],0) > 0

) tm 
--inner join [LTD-EAM].[proto].[emsdba].[CLASS_TASK] ct on ct.task_task_code
--inner join [LTD-EAM].proto.[emsdba].[TSK_ASSIGN] ta WITH (NOLOCK) on ta.task_no = tm.task_no
--INNER JOIN [LTD-EAM].proto.[emsdba].[TSK_ASSIGN_EMP] te WITH (NOLOCK) on te.tsk_assign_id = ta.tsk_assign_id
INNER JOIN [LTD-EAM].ltd_db.[dbo].[bus_classes] b WITH (NOLOCK)
	ON b.eq_equip_no = tm.EQ_equip_no
INNER JOIN #jobm jobm WITH (NOLOCK)
	ON jobm.work_order_yr = tm.work_order_yr
		AND jobm.work_order_no = tm.work_order_no
--LEFT JOIN --select top 100 * from 
--[LTD-EAM].ltd_db.[dbo].employee_info e on e.emp_empl_no = tm.EMP_EMPL_NO
LEFT JOIN [LTD-EAM].ltd_db.[dbo].[des_main_v] rtcc
	ON rtcc.task_task_code = tm.TASK_task_code 
left join #tskcat tcc on tcc.task_code = tm.TASK_task_code
LEFT JOIN [LTD-EAM].ltd_db.[dbo].[employee_info] e WITH (NOLOCK) on e.EMP_empl_no = tm.EMP_empl_no
--where tm.work_order_yr >= year(getdate())-5
	--order by task_no desc
GO
