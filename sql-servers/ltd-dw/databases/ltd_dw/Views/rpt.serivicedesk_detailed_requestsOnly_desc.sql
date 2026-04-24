SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

 create view [rpt].[serivicedesk_detailed_requestsOnly_desc]
 as

with assigned as (
select wo.WORKORDERID as RequestID, 
opened = dateadd(mi, datediff(mi, getutcdate(), getdate()),dateadd(second, (wo.CREATEDTIME/1000),{d '1970-01-01'})),
created = dateadd(mi, datediff(mi, getutcdate(), getdate()),dateadd(second, (wo.CREATEDTIME/1000),{d '1970-01-01'}))
	,coalesce(ti.first_name, 'Undefined') as Technician,wo.title,aau.first_name as "Requester"
              ,Department = coalesce(d.deptName, 'Undefined')
	,std.STATUSNAME as RequestStatus
from [LTD-ITDB2].servicedesk_new.dbo.WorkOrder wo
left join [LTD-ITDB2].servicedesk_new.dbo.WorkOrderStates wos on wo.WORKORDERID = wos.WORKORDERID
left join [LTD-ITDB2].servicedesk_new.dbo.SDUser td on wos.OWNERID = td.USERID
left join[LTD-ITDB2].servicedesk_new.dbo.AaaUser ti on td.USERID = ti.[USER_ID]
left join [LTD-ITDB2].servicedesk_new.dbo.StatusDefinition std on wos.STATUSID = std.STATUSID
left join [LTD-ITDB2].servicedesk_new.dbo.aaauser					rctd        on ti.[user_id] = rctd.[user_id]
left join[LTD-ITDB2].servicedesk_new.dbo.sduser					sdu         on wo.requesterid = sdu.userid 
left join [LTD-ITDB2].servicedesk_new.dbo.aaauser					aau         on sdu.userid = aau.user_id 
left join [LTD-ITDB2].servicedesk_new.dbo.DepartmentDefinition	d			on d.DEPTID = wo.deptid
and std.statusname not in ('Cancelled')
where  wo.WORKORDERID <> 209
	)

select i.*,s.priorityId, s.statusid, p.[PRIORITYNAME]+'-'+[PRIORITYDESCRIPTION] as PriorityName 
from (
select   wo.workorderid,     coalesce(rctd.first_name,a.Technician, 'Undefined') as "Time Spent Technician"  --, wo.slaid
,sla.slaname, sla.duebydays,
MODENAME+ '-'+MODEDESCRIPTION as MODE
              ,wo.workorderid as "ID"
              --,'Request' AS "Module"
              ,wo.title as "Title"
			  ,wo.[DESCRIPTION] Request_Description
              ,aau.first_name as "Requester"
              ,Department = coalesce(d.deptName, 'Undefined')
              ,std.statusname  "Status", statusDescription "Status Described"
              ,isnull(sum(ct.timespent / cast(3600000 as float)),0) as "Time Spent" 
              ,created = dateadd(mi, datediff(mi, getutcdate(), getdate()),dateadd(second, (ct.CREATEDTIME/1000),{d '1970-01-01'}))
              ,opened = dateadd(mi, datediff(mi, getutcdate(), getdate()),dateadd(second, (wo.CREATEDTIME/1000),{d '1970-01-01'}))
			  ,closed = dateadd(mi, datediff(mi, getutcdate(), getdate()),dateadd(second, (wo.CREATEDTIME/1000),{d '1970-01-01'}))
			  ,workdate = dateadd(mi, datediff(mi, getutcdate(), getdate()),dateadd(second, (ct.TS_STARTTIME/1000),{d '1970-01-01'}))
 from  -- select top 100 * from 
 [LTD-ITDB2].servicedesk_new.dbo.workorder wo 
 inner join assigned a on a.RequestID = wo.workorderid
              left join [LTD-ITDB2].servicedesk_new.dbo.workordertocharge		wotoc		on wo.workorderid = wotoc.workorderid 
              left join [LTD-ITDB2].servicedesk_new.dbo.chargestable			ct			on wotoc.chargeid = ct.chargeid 
              left join [LTD-ITDB2].servicedesk_new.dbo.sduser					rcti        on ct.technicianid = rcti.userid 
              left join [LTD-ITDB2].servicedesk_new.dbo.aaauser					rctd        on rcti.userid = rctd.user_id 
              left join [LTD-ITDB2].servicedesk_new.dbo.sduser					sdu         on wo.requesterid = sdu.userid 
              left join [LTD-ITDB2].servicedesk_new.dbo.aaauser					aau         on sdu.userid = aau.user_id 
              left join [LTD-ITDB2].servicedesk_new.dbo.workorderstates			wos         on wo.workorderid = wos.workorderid 
              left join [LTD-ITDB2].servicedesk_new.dbo.statusdefinition		std         on wos.statusid = std.statusid 
			  left join [LTD-ITDB2].[servicedesk_new].[dbo].[SLADefinition]		sla			on sla.slaid = wo.slaid
              left join [LTD-ITDB2].servicedesk_new.dbo.DepartmentDefinition	d			on d.DEPTID = wo.deptid
			  left join [LTD-ITDB2].[servicedesk_new].[dbo].[ModeDefinition]	m			on m.modeid = wo.modeid
			 where  wo.isparent = '1' 
              and 
			  ((ct.createdtime >= (      datediff(s, getutcdate(), getdate())  )
				and ct.createdtime <= 
			  (      datediff(s, getutcdate(), getdate()) 
                                                - datediff(s, getdate(), '1970-01-01 00:00:00') 
                                         ) * cast(1000 as bigint)
			  )
			  or
			  (ct.TS_STARTTIME >=  (      datediff(s, getutcdate(), getdate()) 
                                                - datediff(s, '1/1/2018', '1970-01-01 00:00:00') 
                                         ) * cast(1000 as bigint) 



			  and ct.TS_STARTTIME <= (      datediff(s, getutcdate(), getdate()) 
                                                - datediff(s, getdate(), '1970-01-01 00:00:00') 
                              )          * cast(1000 as bigint)   ))
and std.statusname not in ('Cancelled')
 and wo.WORKORDERID <> 209
group by    wo.workorderid,  coalesce(rctd.first_name,a.Technician, 'Undefined') 
                     ,wo.workorderid
                     ,wo.title ,wo.[DESCRIPTION] ,
               wo.slaid
,sla.slaname, sla.duebydays,MODENAME+ '-'+MODEDESCRIPTION
                     ,rctd.first_name
                     ,aau.first_name
                     ,std.statusname , statusDescription
                     ,d.deptname
                     ,ct.createdtime
                     ,wo.createdtime
                     ,wo.completedtime
					 ,ct.TS_STARTTIME
) i
 left join [LTD-ITDB2].[servicedesk_new].[dbo].workorderstates		s			on s.[WORKORDERID] = i.[WORKORDERID] 
 left join [LTD-ITDB2].[servicedesk_new].[dbo].[PriorityDefinition] p on p.priorityid = s.priorityid
GO
