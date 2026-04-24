SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[sql_agent_job_details_all]
as

select srv_name, [name] as job_name
      ,[job_id]
      ,[schedule_id]
      ,[schedule_name]
      ,[SchedDesc]
      ,[step_id]
      ,[step_name]
      ,[subsystem]
      ,[command]
      ,[run_date]
      ,[run_time]
      ,spm = ltd_dw.[dbo].[F_DATE_TO_SEC_SINCE_MIDNITE]([rn_dt_tm])
      ,[rn_dt_tm]
      ,case when [run_duration] = 0 then 1 else run_duration end run_duration
      ,[run_status]
from (
    select *,'ltd-dw' as srv_name from dbo.sql_agent_job_details_ltd_dw
    union all
    select *,'ltd-tmdata' as srv_name from dbo.sql_agent_job_details_ltd_tmdata
    union all
    select *,'ltd-etl' as srv_name from dbo.sql_agent_job_details_ltd_etl
    union all
    select *,'ltd-test-dw2' as srv_name from dbo.sql_agent_job_details_ltd_test_dw2
 ) o

GO
