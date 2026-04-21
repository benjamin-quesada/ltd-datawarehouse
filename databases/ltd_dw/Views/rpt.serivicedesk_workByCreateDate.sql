SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


 CREATE view [rpt].[serivicedesk_workByCreateDate]
 as

 
select RequestId,RequestCount,Technician,CreatedYrMo,createdCalId,cast(RequestCreated as date) createdDt,
100000000 + (cast(createdYrMo as varchar(12)) + '01') as Calendar_ID,RequesterName,Department,
sum(timespent) HoursSpent ,isnull(TimeToComplete,0) TimeToComplete,TimeOpen,RequestStatus,g.wo_status,
count(distinct cast(isnull(workcreatedtime,getdate()) as date)) WorkDaysPerRequest
	 from (
select isnull(Requester,'Unknown') RequesterName
,ID as RequestID
,ID as RequestCount
,Title as RequestTitle
,created as RequestCreated
,createdYrMo = left(convert(varchar(12),created,112),6)
,createdCalId = 100000000+ cast(left(convert(varchar(12),created,112),8) as int)
,createdYr = year(created)
,createdMo = month(created)
,[time spent technician] as Technician
,RequestStatus = case when [status] in (
						'Closed',
						'Resolved',
						'Close - In Progress',
						'Cancelled',
						'Completed',
						'Implementation - Completed') then 'Closed' else [status] end  
,wo.[status] wo_status
,closed as CompletedTime
,case when closed is not null then datediff(day,closed,created) else 0 end as TimeToComplete
,case when closed is null and [Status] not in ('Implementation - Completed','closed','completed','resolved','cancelled','close - In Progress') then datediff(day,created,getdate()) else 0 end as TimeOpen
,workdate as workcreatedtime
,[time spent] as TimeSpent
,[Department] 
from rpt.serivicedesk_all wo
where year(created) >= 2018 
 and wo.Status not like '%implementation%' and status not like '%planning%' and wo.Status not like '%review%'
) g
where requestId <> 209
group by cast(RequestCreated as date) ,createdCalId,RequesterName, RequestTitle, RequestId,RequestCount,createdYrMo, createdYr, createdMo, technician, timetocomplete,timeopen,department,RequestStatus
,g.wo_status

GO
