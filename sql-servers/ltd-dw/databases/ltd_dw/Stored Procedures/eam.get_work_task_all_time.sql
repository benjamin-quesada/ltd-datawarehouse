SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   PROCEDURE [eam].[get_work_task_all_time]
as
-- exec eam.get_work_task_all_time

/*---------------------------------------
Standardized Work Task Cost and Time Calculations

CREATED		20210826
AUTHOR		B EICHBERGER
PURPOSE		Prepares data and merges into [eam].[work_task_all_time]
			to provide data for eam_model or other analysis

-- GRANT SELECT on [eam].[work_task_all_time] to rpt_reader

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

			  
declare @workstartdt datetime = sysdatetime() 
-- clean up merge log in case some previous processing did not complete
update ltd_dw.[process].[MergeLogs]
	set recInsert =  0 
	,[MergeEndDatetime] = sysdatetime()
		where mergecode = 'TASK'
			and [ObjectDestination] = 'ltd_dw.eam.work_task_all_time'
			AND [ObjectSource] = 'EAM'
			AND [ObjectProgram] = 'ltd_dw.eam.work_task_all_time'
			AND [MergeEndDatetime] is null
			AND (isnull(recInsert,0) = 0 or isnull(recUpdate,0) = 0 or isnull(recDelete,0) = 0)

declare @stdt datetime = '7/24/2021'
--select @stdt = (select ISNULL(MIN(sdt),'1/1/2000') FROM 
--				(select max(record_created_date) sdt from eam.work_task_all_time
--				UNION
--				select max([record_updated_date]) from eam.work_task_all_time) o )
declare @pdt DATETIME = '7/31/2021' --DATEADD(DAY,-1,GETDATE())
;
declare @tasks table (taskid int identity(1,1),taskcode varchar(32))
insert @tasks (taskcode)
select distinct task_task_code from eam.workOrderTaskCategoryTime

declare @i int = 1
declare @t varchar(32) = ''
declare @r int = (select max(taskid) from @tasks)
While @i <= @r
BEGIN

select @t = (select taskcode from @tasks where taskid = @i)
;
WITH mr as (select eq_equip_no, meter_prev_total,last_meter_reading,meter_diff,last_meter_date FROM (
	select rn = row_number() over (partition by eq_equip_no,last_meter_reading order by last_meter_date,meter_diff desc),
	eq_equip_no, meter_prev_total,last_meter_reading,meter_diff,last_meter_date
	from [LTD-EAM].[proto].[emsdba].[EQ_METER_READ] ) y
	WHERE rn = 1
	)
, prt as (
SELECT tm.work_order_no, tm.work_order_yr,tm.task_task_code,tm.unique_id, pr.[PART_part_no],pm.[description_keyword],[part_description],[last_order_date],[last_order_price]
,[request_qty],[unit_issue_price], issued_value = [request_qty]*[unit_issue_price]
from [LTD-EAM].proto.emsdba.[TSK_MAIN] tm
join [LTD-EAM].proto.[emsdba].[PTS_REQUEST] pr on pr.work_order_yr = tm.work_order_yr and pr.[work_order_no] = tm.[work_order_no] and pr.[TASK_task_code] = tm.[TASK_task_code]
JOIN [LTD-EAM].proto.[emsdba].[PTS_MAIN] pm on pm.[PART_part_no] = pr.part_part_no
where confirmed_no_parts = 'N' and tm.work_order_yr > 2016 and tm.task_task_code = @t
)

select u.*
 , CASE WHEN LAG(u.Miles_At_Service) OVER (PARTITION BY u.eq_equip_no ORDER BY u.Miles_At_Service, u.meter_diff DESC) IS NULL THEN u.meter_diff 
			ELSE LAG(u.Miles_At_Service) OVER (PARTITION BY u.eq_equip_no ORDER BY u.labor_date, u.meter_diff DESC) END MilesAtLastTask
 , CASE WHEN LAG(u.Miles_At_Service) OVER (PARTITION BY u.eq_equip_no ORDER BY u.Miles_At_Service, u.meter_diff DESC) IS NULL THEN u.meter_diff
			ELSE u.Miles_At_Service -LAG(u.Miles_At_Service) OVER (PARTITION BY u.eq_equip_no ORDER BY u.labor_date, u.meter_diff DESC) END milesBetweenTasks
INTO  #taskdetail
FROM	   ( 
	SELECT rn = ROW_NUMBER() OVER (PARTITION BY t.work_order_yr,t.work_order_no,t.TASK_task_code ORDER BY t.labor_date)
		  ,t.work_order_yr
		  ,t.work_order_no
		  ,t.wo_task_yr_no
		  ,t.calendar_id
		  ,t.job_type
		  ,t.work_order_status
		  ,t.life_miles
		  ,t.TASK_task_code
		  ,t.[task_code]
		  ,t.emp_empl_no
		  ,CAST(t.[eq_equip_no] AS VARCHAR(32)) [eq_equip_no]
		  ,t.repair_group
		  ,t.repair_group_code
		  ,t.repair_category
		  ,t.category 
		  ,t.labor_date
		  ,t.meter_1_reading Miles_At_Service
		  ,mr.meter_prev_total
		  ,mr.meter_diff
		  ,t.[estimate]
		  ,t.[labor_rate]
		  ,t.[labor_hours]
		  ,t.[wo_task_calendar_id]
		   --,r.life_total_meter
	, DATEDIFF(HOUR,t.datetime_out_service,t.datetime_in_service) AS HoursOutofServ
	, DATEDIFF(HOUR,t.datetime_out_service,t.datetime_in_service) /24.0 DaysOutOfServ
	FROM eam.[workOrderTaskCategoryTime] t
	LEFT JOIN mr WITH (NOLOCK) ON mr.last_meter_reading = t.meter_1_reading AND mr.EQ_equip_no COLLATE SQL_Latin1_General_CP850_CI_AS = t.EQ_equip_no
	left join (select work_order_no, work_order_yr, task_task_code, unique_id, sum(issued_value) prtsValue from prt
				group by work_order_no, work_order_yr, task_task_code, unique_id) p
			on p.work_order_no = t.work_order_no
			and p.work_order_yr = t.work_order_yr
			and p.task_task_code COLLATE SQL_Latin1_General_CP850_CI_AS = t.task_task_code COLLATE SQL_Latin1_General_CP850_CI_AS 
	WHERE labor_date >= @stdt AND t.labor_date <= @pdt
	and t.TASK_task_code = @t
) u
WHERE u.rn = 1

--select * from #taskdetail

DECLARE @outputRC TABLE (actionType VARCHAR(32))
MERGE eam.work_task_all_time t
USING #taskdetail s
on s.calendar_id = t.calendar_id
			and s.category = t.category
			and s.emp_empl_no = t.emp_empl_no
			and s.job_type = t.job_type
			and s.TASK_task_code = t.TASK_task_code
			and t.labor_date = t.labor_date
			and s.work_order_no = t.work_order_no
			and s.work_order_yr = t.work_order_yr
WHEN NOT MATCHED THEN INSERT
(	   [work_order_yr]
      ,[work_order_no]
      ,[wo_task_yr_no]
      ,[calendar_id]
      ,[job_type]
      ,[work_order_status]
      ,[life_miles]
      ,[TASK_task_code]
      ,[task_code]
      ,[emp_empl_no]
      ,[eq_equip_no]
      ,[repair_group]
      ,[repair_group_code]
      ,[repair_category]
      ,[category]
      ,[labor_date]
      ,[Miles_At_Service]
      ,[meter_prev_total]
      ,[meter_diff]
      ,[estimate]
      ,[labor_rate]
      ,[labor_hours]
      ,[wo_task_calendar_id]
      ,[HoursOutofServ]
      ,[DaysOutOfServ]
      ,MilesAtLastTask
      ,milesBetweenTasks	   )
     VALUES
    (  s.[work_order_yr]
      ,s.[work_order_no]
      ,s.[wo_task_yr_no]
      ,s.[calendar_id]
      ,s.[job_type]
      ,s.[work_order_status]
      ,s.[life_miles]
      ,s.[TASK_task_code]
      ,s.[task_code]
      ,s.[emp_empl_no]
      ,s.[eq_equip_no]
      ,s.[repair_group]
      ,s.[repair_group_code]
      ,s.[repair_category]
      ,s.[category]
      ,s.[labor_date]
      ,s.[Miles_At_Service]
      ,s.[meter_prev_total]
      ,s.[meter_diff]
      ,s.[estimate]
      ,s.[labor_rate]
      ,s.[labor_hours]
      ,s.[wo_task_calendar_id]
      ,s.[HoursOutofServ]
      ,s.[DaysOutOfServ]
      ,s.MilesAtLastTask
      ,s.milesBetweenTasks)
WHEN MATCHED AND
(isnull(s.[work_order_status],'') <> isnull(t.[work_order_status],'')
OR isnull(s.[life_miles],0) <> isnull(t.[life_miles],0)
OR isnull(s.[wo_task_yr_no],'') <> isnull(t.[wo_task_yr_no],'')
OR isnull(s.[eq_equip_no],'') <> isnull(t.[eq_equip_no],'')
OR isnull(s.[repair_group],'') <> isnull(t.[repair_group],'')
OR isnull(s.[repair_group_code],'') <> isnull(t.[repair_group_code],'')
OR isnull(s.[repair_category],'') <> isnull(t.[repair_category],'')
OR isnull(s.[Miles_At_Service],0) <> isnull(t.[Miles_At_Service],0)
OR isnull(s.[meter_prev_total],0) <> isnull(t.[meter_prev_total],0)
OR isnull(s.[meter_diff],0) <> isnull(t.[meter_diff],0)
OR isnull(s.[estimate],0) <> isnull(t.[estimate],0)
OR isnull(s.[labor_rate],0) <> isnull(t.[labor_rate],0)
OR isnull(s.[labor_hours],0) <> isnull(t.[labor_hours],0)
OR isnull(s.[wo_task_calendar_id],0) <> isnull(t.[wo_task_calendar_id],0)
OR isnull(s.[HoursOutofServ],0) <> isnull(t.[HoursOutofServ],0)
OR isnull(s.[DaysOutOfServ],0) <> isnull(t.[DaysOutOfServ],0)
OR isnull(s.MilesAtLastTask,0) <> isnull(t.MilesAtLastTask,0)
OR isnull(s.milesBetweenTasks,0) <> isnull(t.milesBetweenTasks,0))
THEN UPDATE SET
t.[work_order_status] = s.[work_order_status]
, t.[life_miles] = s.[life_miles]
, t.[wo_task_yr_no] = s.[wo_task_yr_no]
, t.[eq_equip_no] = s.[eq_equip_no]
, t.[repair_group] = s.[repair_group]
, t.[repair_group_code] = s.[repair_group_code]
, t.[repair_category] = s.[repair_category]
, t.[Miles_At_Service] = s.[Miles_At_Service]
, t.[meter_prev_total] = s.[meter_prev_total]
, t.[meter_diff] = s.[meter_diff]
, t.[estimate] = s.[estimate]
, t.[labor_rate] = s.[labor_rate]
, t.[labor_hours] = s.[labor_hours]
, t.[wo_task_calendar_id] = s.[wo_task_calendar_id]
, t.[HoursOutofServ] = s.[HoursOutofServ]
, t.[DaysOutOfServ] = s.[DaysOutOfServ]
, t.MilesAtLastTask = s.MilesAtLastTask
, t.milesBetweenTasks = s.milesBetweenTasks
OUTPUT $ACTION INTO @outputRC;

declare @n int = (select isnull(count(*),0) from @outputRC where actionType = 'INSERT')
declare @u int = (select isnull(count(*),0) from @outputRC where actionType = 'UPDATE')
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
		  'TASK', 'ltd_dw.eam.work_task_all_time','EAMM','ltd_dw.eam.work_task_all_time '+@t ,  isnull( @n,0),isnull(@u,0), 0, @workstartdt, sysdatetime())
select count(*) from #taskdetail
drop table #taskdetail

select @i = @i + 1
if @i > @r BREAK
	else continue

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
