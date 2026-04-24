SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

--/****** Object:  View [dbo].[sql_agent_job_details_ltd_test_dw2]    Script Date: 1/13/2026 4:44:04 PM ******/
--SET ANSI_NULLS ON
--GO

--SET QUOTED_IDENTIFIER ON
--GO


CREATE view [dbo].[sql_agent_job_details_ltd_test_dw2]
as

with job_schedules as
(
select schedule_id
      ,sysschedules.name as schedule_name
      ,SchedDesc=TimeOfDay+Frequency+EffDtRange  -- select * 
from [ltd-test-dw2].msdb.dbo.sysschedules 
cross apply 
  (select StDate=convert(datetime
                        ,convert(varchar(8),active_start_date))
         ,EnDate=convert(datetime
                        ,convert(varchar(8),active_end_date))
         ,StTime=convert(datetime
                        ,stuff(stuff(right(1000000+active_start_time
                                          ,6)
                                    ,3,0,N':')
                              ,6,0,N':'))
         ,EnTime=convert(datetime
                        ,stuff(stuff(right(1000000+active_end_time
                                          ,6)
                                    ,3,0,N':')
                              ,6,0,N':'))
  ) F_DtTm
cross apply
  --Translate the times into appropriate HH:MM:SSam or HH:MMam char formats
  (select replace(replace(replace(substring(lower(convert(varchar(30),StTime,109))
                                           ,13,14)
                                 ,N':000',N'')
                         ,N':00a',N'a')
                 ,N':00p',N'p')
         ,replace(replace(replace(substring(lower(convert(varchar(30),EnTime,109))
                                           ,13,14)
                                 ,N':000',N'')
                         ,N':00a',N'a')
                 ,N':00p',N'p')
  ) F_Tms(StTimeString,EnTimeString)
cross apply 
  --What Time of Day? Single Time or Range of Times/Intervals
  (select case 
            when freq_subday_type=0
            then N''
            else case 
                   when freq_subday_type=1
                   then N'At '
                   else N'Every '
                       +convert(nvarchar(10),freq_subday_interval)
                       +' '
                       +case freq_subday_type
                          when 2 then N'Second'
                          when 4 then N'Minute'
                          when 8 then N'Hour'
                        end
                       +case 
                          when freq_subday_interval=1 then N'' else N's' end
                       +N' From '
                 end
                +StTimeString
                +case
                   when freq_subday_type=1
                   then N''
                   else N' to '+EnTimeString
                 end
                +N' '
          end
  ) F_Tm(TimeOfDay)
cross apply
  --Translate Frequency  
  (select case freq_type
            when 1
            then N'One Time Only'
            when 4
            then N'Every '
                +case freq_interval 
                   when 1
                   then N'Day'
                   else convert(nvarchar(10),freq_interval)+N' Days'
                 end
            when 8
            then N'Every '
                +case freq_recurrence_factor
                   when 1
                   then N''
                   else convert(nvarchar(10),freq_recurrence_factor)+N' Weeks on '
                 end
                +stuff(case when freq_interval& 1<>0 then N', Sunday' else N'' end
                      +case when freq_interval& 2<>0 then N', Monday' else N'' end
                      +case when freq_interval& 4<>0 then N', Tuesday' else N'' end
                      +case when freq_interval& 8<>0 then N', Wednesday' else N'' end
                      +case when freq_interval&16<>0 then N', Thursday' else N'' end
                      +case when freq_interval&32<>0 then N', Friday' else N'' end
                      +case when freq_interval&64<>0 then N', Saturday' else N'' end
                      ,1,2,N'')
            when 16
            then N'Every '
                +case freq_recurrence_factor 
                   when 1
                   then N'Month '
                   else convert(nvarchar(10),freq_recurrence_factor)+N' Months '
                 end
                +N'on the '
                +convert(nvarchar(10),freq_interval)
                +case 
                   when freq_interval in (1,21,31)
                   then N'st'
                   when freq_interval in (2,22)
                   then N'nd'
                   when freq_interval in (3,23)
                   then N'rd'
                   else N'th'
                 end
                +N' of the Month'
            when 32
            then N'Every '
                +case freq_recurrence_factor 
                   when 1
                   then N'Month '
                   else convert(nvarchar(10),freq_recurrence_factor)+N' Months '
                 end
                +N'on the '
                +case freq_relative_interval 
                   when  1 then N'1st '
                   when  2 then N'2nd '
                   when  4 then N'3rd '
                   when  8 then N'4th '
                   when 16 then N'Last '
                 end
                +case freq_interval 
                   when  1 then N'Sunday'
                   when  2 then N'Monday'
                   when  3 then N'Tuesday'
                   when  4 then N'Wednesday'
                   when  5 then N'Thursday'
                   when  6 then N'Friday'
                   when  7 then N'Saturday'
                   when  8 then N'Day'
                   when  9 then N'Weekday'
                   when 10 then N'Weekend Day'
                 end
                +N' of the Month'
            when 64
            then N'When SQL Server Agent Starts'
            when 128
            then N'Whenever the CPUs become Idle'
            else N'Unknown'
          end
  ) F_Frq(Frequency)
cross apply
  --When is it effective?
  (select N' (Effective '+convert(nvarchar(11),StDate,100)
         +case  
            when EnDate='99991231'
            then N''
            else N' thru '+convert(nvarchar(11),EnDate,100)
          end
         +N')'           
  ) F_Eff(EffDtRange)
where schedule_id in (select s.schedule_id 
from [ltd-test-dw2].msdb.dbo.sysjobschedules as s
inner join [ltd-test-dw2].msdb.dbo.sysjobs as j 
on j.job_id = s.job_id )
)

select coalesce(i.rpt_name ,  job_name collate SQL_Latin1_General_CP1_CI_AS) name
     , i.job_id
     , i.schedule_id
     , i.schedule_name
     , i.SchedDesc
     , i.step_id
     , i.step_name
     , i.subsystem
     , i.command
     , i.run_date
     , i.run_time
     , i.rn_dt_tm
     , i.run_duration
     , i.run_status
from (
select distinct j.[name] job_name, case when e.ReportName is not null then 'PBI ' + e.ReportName else null end rpt_name
, jb.job_id
,s.schedule_id 
,d.schedule_name, d.SchedDesc
, jb.step_id
, jb.step_name
,jb.subsystem
, jb.command
,h.run_date
,h.run_time
,msdb.dbo.[agent_datetime](h.run_date,h.run_time) rn_dt_tm
,h.run_duration
,h.run_status
from [ltd-test-dw2].msdb.dbo.sysjobs as j 
left join [ltd-test-dw2].msdb.dbo.sysjobsteps as jb on j.job_id = jb.job_id
left join [ltd-test-dw2].msdb.dbo.sysjobschedules s on s.job_id = j.job_id
left join job_schedules d on d.schedule_id = s.schedule_id
left join [ltd-test-dw2].msdb.dbo.sysjobhistory h on h.job_id = jb.job_id and h.step_id = jb.step_id
left join (
        select b.name as JobName, b.job_id, c.Name as ReportName
        from [ltd-test-dw2].msdb.dbo.sysjobs as b
            join [ltd-test-dw2].PBIRS.dbo.ReportSchedule as rs on b.name = convert(sysname, rs.ScheduleID)
            join [ltd-test-dw2].PBIRS.dbo.Subscriptions as s on rs.SubscriptionID = s.SubscriptionID
            join [ltd-test-dw2].PBIRS.dbo.Catalog as c on s.Report_OID = c.ItemID
        ) e on e.job_id = j.job_id
where msdb.[dbo].[agent_datetime](h.run_date,h.run_time) >= dateadd(day,-30,cast(getdate() as date)) and h.step_name <> '(Job outcome)'
group by
j.name, e.ReportName
, jb.job_id
,s.schedule_id
,d.schedule_name,d.SchedDesc
, jb.step_id
, jb.step_name
,jb.subsystem
, jb.command
,h.run_date
,h.run_time
,h.run_duration
,h.run_status
    ) i
GO
