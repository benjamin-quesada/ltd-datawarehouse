SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [eam].[get_work_job_header]
AS

/*------------LTD_GLOSSARY-----------------

CREATED		20260219
AUTHOR		B Eichberger
PURPOSE		Prepares data and merges into [eam].[workOrderJobHeader]
			Provide source data primarily for eam_model but can be used
			for other reporting. Joins to eam.workOrderTaskCategoryTimeExtended
USE			exec [eam].[get_work_job_header]

*/

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

declare @sdt datetime2 = sysdatetime()
DECLARE @outputTbl TABLE (actionNm VARCHAR(32));

truncate table [eam].[workOrderJobHeader];

WITH yrFrom AS (SELECT YEAR(GETDATE())-12 yrFrom)
, rtcc
AS (
	select q.work_order_yr,q.work_order_no,q.task_type FROM (
SELECT m.work_order_yr,m.work_order_no, m.task_task_code AS rtcc_task,
           dbo.fn_ProperCase(d.repair_group_code) repair_group_code,
           dbo.fn_ProperCase(d.repair_group) repair_group,
           dbo.fn_ProperCase(d.category) category,
           dbo.fn_ProperCase(REPLACE(d.task_type, ' Task', '')) task_type,
           dbo.fn_ProperCase(d.description) task_type_description
    FROM [LTD-EAM].proto.[emsdba].lab_main  m WITH (NOLOCK)
	INNER JOIN [LTD-EAM].ltd_db.[dbo].[des_main_v] d ON m.task_task_code = d.task_task_code
	inner join yrFrom y on m.work_order_yr >= y.yrFrom
	) q
  group BY q.work_order_yr,q.work_order_no,q.task_type
)
, is_RC as (
	select distinct work_order_yr
     , work_order_no
     , work_order_yr_no
     , eq_equip_no
     , MilesAtLastRC
     , milesBetweenRC from eam.road_calls r
	 join yrFrom y on r.work_order_yr >= y.yrFrom
)

insert [eam].[workOrderJobHeader] (
work_order_yr
,[work_order_no]
,[work_order_yr_no]
,[job_type]
,[EQ_equip_no]
,[is_roadcall]
,[MilesAtLastRC]
,[milesBetweenRC]
,[calid_entered]
,[datetime_open]
,[calid_datetime_open]
,[calid_datetime_closed]
,[WorkorderVehicleKey]
,[date_entered]
,[datetime_out_service]
,[datetime_in_service]
,[work_order_status]
,[warranty]
,[job_account_id]
,[hours_out_of_service]
,[datetime_first_labor]
,[hours_to_first_work]
,[datetime_finished]
,[hours_to_finished_work]
,[datetime_closed]
,[hours_to_closed])
output Inserted.work_order_yr_no into @outputTbl
SELECT DISTINCT 
	   o.work_order_yr,
       o.work_order_no,
       o.work_order_yr_no,
	   UPPER(
		  REPLACE(
			COALESCE(b.job_type,c.task_type),'Repair Group','REPAIR')) job_type,
	   b.EQ_equip_no,
	   case when isnull(r.work_order_yr_no,'') = '' then 0 else 1 end as is_roadcall,
	   case when isnull(r.work_order_yr_no,'') = '' then null else MilesAtLastRC end MilesAtLastRC,
       case when isnull(r.work_order_yr_no,'') = '' then null else milesBetweenRC end milesBetweenRC ,
	   CAST(CONVERT(VARCHAR(32),o.date_entered,112) AS INT) + 100000000 calid_entered ,
	   b.datetime_open,
	   CAST(CONVERT(VARCHAR(32),b.datetime_open,112) AS INT) + 100000000 calid_datetime_open ,
	   CAST(CONVERT(VARCHAR(32),b.datetime_closed,112) AS INT) + 100000000 calid_datetime_closed ,
	   CAST(ISNULL(b.work_order_yr,year(b.datetime_open)) as varchar(12))
			+'-'+CAST(ISNULL(b.work_order_no,-1) as VARCHAR(12))
			+'-'+b.EQ_equip_no  AS WorkorderVehicleKey,
       o.date_entered,
       b.datetime_out_service,
       b.datetime_in_service,
       b.work_order_status,
	   b.warranty,
	   b.ACCT_acct_code job_account_id,
	   CASE WHEN (
	   CASE WHEN b.datetime_in_service IS NULL 
			THEN DATEDIFF(minute,b.datetime_out_service,GETDATE())/60.0
			ELSE DATEDIFF(minute,b.datetime_out_service,b.datetime_in_service)/60.0 END ) < 0 THEN 0
				ELSE 
			(CASE WHEN b.datetime_in_service IS NULL 
			THEN DATEDIFF(minute,b.datetime_out_service,GETDATE())/60.0
			ELSE DATEDIFF(minute,b.datetime_out_service,b.datetime_in_service)/60.0 END) END	
				hours_out_of_service,
       b.datetime_first_labor,
	   CASE WHEN (
	   CASE WHEN b.datetime_first_labor IS NULL
			THEN DATEDIFF(minute,b.datetime_out_service,GETDATE())/60.0
			ELSE DATEDIFF(minute,b.datetime_out_service,b.datetime_first_labor)/60.0 END) < 0 THEN 0 
				ELSE
			(CASE WHEN b.datetime_first_labor IS NULL
			THEN DATEDIFF(minute,b.datetime_out_service,GETDATE())/60.0
			ELSE DATEDIFF(minute,b.datetime_out_service,b.datetime_first_labor)/60.0 END) END hours_to_first_work,
       b.datetime_finished,
	   CASE WHEN (
	   CASE WHEN b.datetime_finished IS NULL  
			THEN DATEDIFF(minute,b.datetime_out_service,GETDATE())/60.0
			ELSE DATEDIFF(minute,b.datetime_out_service,b.datetime_finished)/60.0 END) < 0 THEN 0 
				ELSE
			(CASE WHEN b.datetime_finished IS NULL  
			THEN DATEDIFF(minute,b.datetime_out_service,GETDATE())/60.0
			ELSE DATEDIFF(minute,b.datetime_out_service,b.datetime_finished)/60.0 END) END hours_to_finished_work,
       b.datetime_closed,
	   CASE WHEN (
	   CASE WHEN b.datetime_closed IS NULL 
			THEN DATEDIFF(minute,b.datetime_out_service,GETDATE())/60.0 
			ELSE DATEDIFF(minute,b.datetime_out_service,b.datetime_closed)/60.0 END ) < 0 THEN 0 
				ELSE
			(CASE WHEN b.datetime_closed IS NULL 
			THEN DATEDIFF(minute,b.datetime_out_service,GETDATE())/60.0 
			ELSE DATEDIFF(minute,b.datetime_out_service,b.datetime_closed)/60.0 END ) END hours_to_closed
from
(SELECT i.work_order_yr,i.work_order_no,i.work_order_yr_no,MIN(i.date_entered) date_entered FROM (
    SELECT work_order_yr,
           work_order_no,
           work_order_yr_no = CAST(work_order_yr AS VARCHAR(32)) + '-' + CAST(work_order_no AS VARCHAR(32)),
           ([X_datetime_insert]) date_entered
    FROM [LTD-EAM].proto.emsdba.[TSK_MAIN]
	JOIN yrFrom y ON work_order_yr >= y.yrFrom
	WHERE work_order_yr IS NOT NULL AND delete_row = 'N' 
	GROUP BY work_order_yr,work_order_no,[X_datetime_insert]
    UNION
    SELECT work_order_yr,
           work_order_no,
           work_order_yr_no = CAST(work_order_yr AS VARCHAR(32)) + '-' + CAST(work_order_no AS VARCHAR(32)),
           ([X_datetime_insert]) date_entered
    FROM [LTD-EAM].proto.[emsdba].[PTS_REQUEST]
	JOIN yrFrom y ON work_order_yr >= y.yrFrom
	WHERE work_order_yr IS NOT null 
	GROUP BY work_order_yr,work_order_no,[X_datetime_insert]
    UNION 
	SELECT work_order_yr,
           work_order_no,
           work_order_yr_no = CAST(work_order_yr AS VARCHAR(32)) + '-' + CAST(work_order_no AS VARCHAR(32)),
           ([X_datetime_insert]) date_entered
    FROM [LTD-EAM].proto.[emsdba].[PTD_MAIN]
	JOIN yrFrom y ON work_order_yr >= y.yrFrom
	WHERE work_order_yr IS NOT null 
	GROUP BY work_order_yr,work_order_no,[X_datetime_insert]
    UNION
    SELECT work_order_yr,
           work_order_no,
           work_order_yr_no = CAST(work_order_yr AS VARCHAR(32)) + '-' + CAST(work_order_no AS VARCHAR(32)),
           ([X_datetime_insert]) date_entered
    FROM [LTD-EAM].proto.[emsdba].[JOB_MAIN]
	JOIN yrFrom y ON work_order_yr >= y.yrFrom
	WHERE work_order_yr IS NOT null 
	GROUP BY work_order_yr,work_order_no,[X_datetime_insert]
    UNION
    SELECT work_order_yr,	
           work_order_no,
           work_order_yr_no = CAST(work_order_yr AS VARCHAR(32)) + '-' + CAST(work_order_no AS VARCHAR(32)),
           ([X_datetime_insert]) date_entered
    FROM [LTD-EAM].proto.[emsdba].[LAB_MAIN]
	JOIN yrFrom y ON work_order_yr >= y.yrFrom
	WHERE fully_reversed = 'N' 
	AND work_order_yr IS NOT NULL
	GROUP BY work_order_yr,work_order_no,[X_datetime_insert]
	) i
	GROUP BY i.work_order_yr,i.work_order_no,i.work_order_yr_no
) o
INNER JOIN [LTD-EAM].proto.[emsdba].job_main b
        ON b.work_order_yr = o.work_order_yr
           AND b.work_order_no = o.work_order_no
JOIN yrFrom y ON b.work_order_yr >= y.yrFrom
LEFT JOIN rtcc c ON c.work_order_yr = o.work_order_yr AND c.work_order_no = o.work_order_no
left join is_RC r on r.work_order_yr = o.work_order_yr AND r.work_order_no = o.work_order_no
WHERE NOT ( o.work_order_yr = 2013 and o.work_order_no = 2) -- problem work order, likely could be researched again to see if ok
and NOT ( b.work_order_yr = 2013 and b.work_order_no = 2)
AND b.work_order_status = 'CLOSED'
AND b.datetime_open IS NOT null
order by o.work_order_yr,
       o.work_order_no


DECLARE @ins INT = (SELECT COUNT(*) FROM @outputTbl)
DECLARE @prg varchar(90) = @@SERVERNAME + '.ltd_dw.eam.get_work_job_header'

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
'ltd_dw.eam.workOrderJobHeader',
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
