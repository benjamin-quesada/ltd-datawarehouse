SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO







 
 CREATE view [rpt].[serivicedesk_workByCreateCalId]
 as

 
select createdCalId,
count(distinct RequestId) RequestCountDaily
	from (
	select isnull(Requester,'Unknown') RequesterName
	,ID as RequestID
	,ID as RequestCount
	,Title as RequestTitle
	,created as RequestCreated
	,createdYrMo = left(convert(varchar(12),created,112),6)
	,createdCalId = 100000000 + cast(left(convert(varchar(12),created,112),8) as int)
	,createdYr = year(created)
	,createdMo = month(created)
	,[time spent technician] as Technician
	,[status] as RequestStatus
	,closed as CompletedTime
	,case when closed is not null then datediff(day,closed,created) else 0 end as TimeToComplete
	,case when closed is null and [Status] not in ('closed','completed','resolved') then datediff(day,created,getdate()) else 0 end as TimeOpen
	,workdate as workcreatedtime
	,[time spent] as TimeSpent
	,[Department]
	from rpt.serivicedesk_all wo
	where ID <> 209
	) g
group by 
createdCalId

GO
