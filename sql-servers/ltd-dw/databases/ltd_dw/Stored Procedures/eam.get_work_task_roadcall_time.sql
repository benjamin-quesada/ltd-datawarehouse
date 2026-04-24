SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   PROCEDURE [eam].[get_work_task_roadcall_time]
as
-- exec eam.get_work_task_roadcall_time

/*------------LTD_GLOSSARY----------------
Standardized Road Call Calculations

CREATED		20210826
AUTHOR		B EICHBERGER
PURPOSE		Prepares data and merges into [eam].[workOrderTaskRoadCallTime]
			to provide data for eam_model or other analysis
USE			exec eam.get_work_task_roadcall_time
SCHEDULE	is called by SQL Agent Job "Maintain Source Data - EAM Work Order Task Facts"

DESTINATION TABLE - Merges to eam.workOrderTaskRoadCallTime


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
		where mergecode = 'RCALL'
			and [ObjectDestination] = 'ltd_dw.eam.workOrderTaskRoadCallTime'
			AND [ObjectSource] = 'EAM'
			AND [ObjectProgram] = 'ltd_dw.eam.work_task_roadcall_time'
			AND [MergeEndDatetime] is null
			AND (isnull(recInsert,0) = 0 or isnull(recUpdate,0) = 0 or isnull(recDelete,0) = 0)

			
select eq_equip_no, meter_prev_total,last_meter_reading,meter_diff,last_meter_date
into #mrread
FROM (
	select rn = row_number() over (partition by eq_equip_no,last_meter_reading order by last_meter_date,meter_diff desc),
	eq_equip_no, meter_prev_total,last_meter_reading,meter_diff,last_meter_date
	from [LTD-EAM].[proto].[emsdba].[EQ_METER_READ] ) y
	WHERE rn = 1



declare @stdt int
select @stdt = 
			(select ISNULL(MIN(sdt),120000101) FROM 
				(select max(calendar_id) sdt from eam.workOrderTaskRoadCallTime
				UNION
				select 100000000 + max(cast(convert(varchar(32),[record_updated_date],112) as int)) from eam.workOrderTaskRoadCallTime) o )
declare @pdt int = (select 100000000 + convert(varchar(32),DATEADD(DAY,-1,GETDATE()),112)) 
 --select @stdt
 --select @pdt

select  u.work_order_yr, u.work_order_no, u.calendar_id
, u.work_order_status
, u.wo_task_yr_no, u.eq_equip_no
, u.Miles_At_Service
, u.meter_diff, u.HoursOutofServ, u.DaysOutOfServ
, case when LAG(Miles_At_Service) OVER (PARTITION BY eq_equip_no ORDER BY Miles_At_Service) is null then meter_diff
       else LAG(Miles_At_Service) OVER (PARTITION BY eq_equip_no ORDER BY Miles_At_Service) end MilesAtLastRC
, case when LAG(Miles_At_Service) OVER (PARTITION BY eq_equip_no ORDER BY Miles_At_Service) is null then meter_diff
       else Miles_At_Service-LAG(Miles_At_Service) OVER (PARTITION BY eq_equip_no ORDER BY Miles_At_Service) end milesBetweenRC
INTO #rcupdates
FROM (
select * from ( 
	SELECT rnd = ROW_NUMBER() OVER (PARTITION BY CAST(t.[eq_equip_no] AS VARCHAR(32)),t.wo_task_yr_no ORDER BY labor_date)
			---^ get the beginning task item of the labor date to order rows
		  ,rn = ROW_NUMBER() OVER (PARTITION BY CAST(t.[eq_equip_no] AS VARCHAR(32)),t.wo_task_yr_no ORDER BY cast(t.meter_1_reading as INT))
			---^ get the beginning task item of the raod call - see rn = 1 below
		  ,t.work_order_yr
		  ,t.work_order_no
		  ,t.wo_task_yr_no
		  ,t.calendar_id
		  ,t.work_order_status
		  ,CAST(t.[eq_equip_no] AS VARCHAR(32)) [eq_equip_no]
		  ,t.meter_1_reading Miles_At_Service
		  ,r.meter_diff
	, DATEDIFF(HOUR,t.datetime_out_service,t.datetime_in_service) AS HoursOutofServ
	, DATEDIFF(HOUR,t.datetime_out_service,t.datetime_in_service) /24.0 DaysOutOfServ
	FROM eam.[workOrderTaskCategoryTime] t
	LEFT JOIN #mrread r ON r.last_meter_reading = t.meter_1_reading AND r.EQ_equip_no COLLATE SQL_Latin1_General_CP850_CI_AS = t.EQ_equip_no
	WHERE (t.category = 'Road Call'  OR t.[wcl_work_class] = '4')
	AND t.calendar_id >= @stdt AND t.calendar_id <= @pdt --'11/1/2017' -- 20171101 --
	--and t.eq_equip_no = '1001'
	
	
	
	) i
	where i.rn = 1
) u




DECLARE @outputRC TABLE (actionType VARCHAR(32))
MERGE eam.workOrderTaskRoadCallTime t
USING #rcupdates s
			on s.calendar_id = t.calendar_id
			and s.work_order_no = t.work_order_no
			and s.work_order_yr = t.work_order_yr
WHEN NOT MATCHED THEN INSERT
(		    [work_order_yr]
           ,[work_order_no]
           ,[wo_task_yr_no]
           ,[calendar_id]
           ,[work_order_status]
           ,[eq_equip_no]
           ,[Miles_At_Service]
           ,[meter_diff]
           ,[MilesAtLastRC]
           ,[milesBetweenRC])
     VALUES
           (s.[work_order_yr]
           ,s.[work_order_no]
           ,s.[wo_task_yr_no]
           ,s.[calendar_id]
           ,s.[work_order_status]
           ,s.[eq_equip_no]
           ,s.[Miles_At_Service]
           ,s.[meter_diff]
           ,s.MilesAtLastRC
           ,s.[milesBetweenRC])
WHEN MATCHED AND
(isnull(s.[work_order_status],'') <> isnull(t.[work_order_status],'')
OR isnull(s.[wo_task_yr_no],'') <> isnull(t.[wo_task_yr_no],'')
OR isnull(s.[eq_equip_no],'') <> isnull(t.[eq_equip_no],'')
OR isnull(s.[Miles_At_Service],0) <> isnull(t.[Miles_At_Service],0)
OR isnull(s.[meter_diff],0) <> isnull(t.[meter_diff],0)
OR isnull(s.MilesAtLastRC,0) <> isnull(t.[MilesAtLastRC],0)
OR isnull(s.[milesBetweenRC],0) <> isnull(t.[milesBetweenRC],0))
THEN UPDATE SET
t.[work_order_status] = s.[work_order_status]
, t.[wo_task_yr_no] = s.[wo_task_yr_no]
, t.[eq_equip_no] = s.[eq_equip_no]
, t.[Miles_At_Service] = s.[Miles_At_Service]
, t.[MilesAtLastRC] = s.MilesAtLastRC
, t.[milesBetweenRC] = s.[milesBetweenRC]
OUTPUT $ACTION INTO @outputRC;

declare @n int = (select isnull((select count(*) from @outputRC where actionType = 'INSERT'),0))
declare @u int = (select isnull((select count(*)from @outputRC where actionType = 'UPDATE'),0))
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
		  'RCALL', 'ltd_dw.eam.workOrderTaskRoadCallTime','EAMM','ltd_dw.eam.work_task_roadcall_time',  isnull( @n,0),isnull(@u,0), 0, @workstartdt, sysdatetime())


	
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
