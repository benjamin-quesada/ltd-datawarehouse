SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view [rpt].[serivicedesk_all]
as

with assigned as (
select wo.WORKORDERID as RequestID, 
opened = dateadd(mi, datediff(mi, getutcdate(), getdate()),dateadd(second, (wo.CREATEDTIME/1000),{d '1970-01-01'})),
created = dateadd(mi, datediff(mi, getutcdate(), getdate()),dateadd(second, (wo.CREATEDTIME/1000),{d '1970-01-01'}))
	,coalesce(ti.first_name, 'Undefined') as Technician,wo.title,aau.first_name as "Requester"
              ,Department = coalesce(d.deptName, 'Undefined')
	,std.STATUSNAME as RequestStatus
from [LTD-ITDB2].servicedesk_new.dbo.WorkOrder wo with (nolock) 
left join [LTD-ITDB2].servicedesk_new.dbo.WorkOrderStates wos with (nolock) on wo.WORKORDERID = wos.WORKORDERID
left join [LTD-ITDB2].servicedesk_new.dbo.SDUser td with (nolock) on wos.OWNERID = td.USERID
left join [LTD-ITDB2].servicedesk_new.dbo.AaaUser ti with (nolock) on td.USERID = ti.[USER_ID]
left join [LTD-ITDB2].servicedesk_new.dbo.StatusDefinition std with (nolock) on wos.STATUSID = std.STATUSID
left join [LTD-ITDB2].servicedesk_new.dbo.aaauser rctd with (nolock) on ti.[user_id] = rctd.[user_id]
left join [LTD-ITDB2].servicedesk_new.dbo.sduser sdu with (nolock) on wo.requesterid = sdu.userid 
left join [LTD-ITDB2].servicedesk_new.dbo.aaauser aau with (nolock) on sdu.userid = aau.user_id 
left join [LTD-ITDB2].servicedesk_new.dbo.DepartmentDefinition d with (nolock) on d.DEPTID = wo.deptid	)

select        coalesce(rctd.first_name,a.Technician, 'Undefined') as "Time Spent Technician" 
              ,wo.workorderid as "ID"
              ,'Request' as "Module"
              ,wo.title as "Title"
              ,aau.first_name as "Requester"
              ,Department = coalesce(d.deptName, 'Undefined')
              ,std.statusname as "Status"
              ,isnull(sum(ct.timespent / cast(3600000 as float)),0) as "Time Spent" 
              ,created = dateadd(mi, datediff(mi, getutcdate(), getdate()),dateadd(second, (ct.CREATEDTIME/1000),{d '1970-01-01'}))
              ,opened = dateadd(mi, datediff(mi, getutcdate(), getdate()),dateadd(second, (wo.CREATEDTIME/1000),{d '1970-01-01'}))
			  ,closed = dateadd(mi, datediff(mi, getutcdate(), getdate()),dateadd(second, (wo.CREATEDTIME/1000),{d '1970-01-01'}))
			  ,workdate = dateadd(mi, datediff(mi, getutcdate(), getdate()),dateadd(second, (ct.TS_STARTTIME/1000),{d '1970-01-01'}))
 from   [LTD-ITDB2].servicedesk_new.dbo.workorder wo 
 inner join assigned a on a.RequestID = wo.workorderid
              left join [LTD-ITDB2].servicedesk_new.dbo.workordertocharge		wotoc		with (nolock) on wo.workorderid = wotoc.workorderid 
              left join [LTD-ITDB2].servicedesk_new.dbo.chargestable			ct			with (nolock) on wotoc.chargeid = ct.chargeid 
              left join [LTD-ITDB2].servicedesk_new.dbo.sduser					rcti        with (nolock) on ct.technicianid = rcti.userid 
              left join [LTD-ITDB2].servicedesk_new.dbo.aaauser					rctd        with (nolock) on rcti.userid = rctd.user_id 
              left join [LTD-ITDB2].servicedesk_new.dbo.sduser					sdu         with (nolock) on wo.requesterid = sdu.userid 
              left join [LTD-ITDB2].servicedesk_new.dbo.aaauser					aau         with (nolock) on sdu.userid = aau.user_id 
              left join [LTD-ITDB2].servicedesk_new.dbo.workorderstates			wos         with (nolock) on wo.workorderid = wos.workorderid 
              left join [LTD-ITDB2].servicedesk_new.dbo.statusdefinition		std         with (nolock) on wos.statusid = std.statusid 
              left join [LTD-ITDB2].servicedesk_new.dbo.DepartmentDefinition	d			with (nolock) on d.DEPTID = wo.deptid
where  wo.isparent = '1' 
              and 
			  ((ct.createdtime >= (datediff(s, getutcdate(), getdate())  )
				and ct.createdtime <= (datediff(s, getutcdate(), getdate()) 
                                                - datediff(s, getdate(), '1970-01-01 00:00:00') 
                                         ) * cast(1000 as bigint)
                )
			  or
			  (ct.TS_STARTTIME >=  (datediff(s, getutcdate(), getdate()) 
                                                - datediff(s, '1/1/2018', '1970-01-01 00:00:00') 
                                         ) * cast(1000 as bigint) 
			  and
              ct.TS_STARTTIME <= (datediff(s, getutcdate(), getdate()) 
                                                - datediff(s, getdate(), '1970-01-01 00:00:00') 
                                         ) * cast(1000 as bigint)   ))


group by      coalesce(rctd.first_name,a.Technician, 'Undefined') 
                     ,wo.workorderid
                     ,wo.title
                     ,rctd.first_name
                     ,aau.first_name
                     ,std.statusname
                     ,d.deptname
                     ,ct.createdtime
                     ,wo.createdtime
                     ,wo.completedtime
					 ,ct.TS_STARTTIME


union


select        Technician "Time Spent Technician" 
              ,requestID as "ID"
              ,'Request' as "Module"
              ,Title
              ,Requester
              ,Department = Department
              ,RequestStatus
              ,0 as [Time Spent]
              ,created
              ,opened
			  ,null
			  ,null
 from   assigned


union 
select		coalesce(rctd.first_name, 'Undefined') as "Time Spent Technician" 
              ,coalesce(ctk.changeid, ch.changeid) as "ID"
              ,'Change' as "Module"
              ,ch.title as "Title"
              ,a.first_name as "Requester"
              ,Department = 'Information Technology'
              ,csd.statusname as "Status" 
              ,sum(ct.timespent / cast(3600000 as float)) as "Time Spent" 
              ,created = dateadd(mi, datediff(mi, getutcdate(), getdate()),dateadd(second, (ct.createdtime/1000),{d '1970-01-01'}))
              ,opened = dateadd(mi, datediff(mi, getutcdate(), getdate()),dateadd(second, (tk.createddate/1000),{d '1970-01-01'}))
              ,closed = dateadd(mi, datediff(mi, getutcdate(), getdate()),dateadd(second, (tk.ACTUALENDTIME/1000),{d '1970-01-01'}))
			  ,workdate = dateadd(mi, datediff(mi, getutcdate(), getdate()),dateadd(second, (tk.ACTUALSTARTTIME/1000),{d '1970-01-01'}))
from   [LTD-ITDB2].servicedesk_new.dbo.chargestable ct with (nolock)  
              left join [LTD-ITDB2].servicedesk_new.dbo.changetocharge chtoc with (nolock) on ct.chargeid = chtoc.chargeid 
              left join [LTD-ITDB2].servicedesk_new.dbo.changedetails ch with (nolock) on chtoc.changeid = ch.changeid 
              left join [LTD-ITDB2].servicedesk_new.dbo.tasktocharge tkc with (nolock) on ct.chargeid = tkc.chargeid 
              left join [LTD-ITDB2].servicedesk_new.dbo.taskdetails tk with (nolock) on tkc.taskid = tk.taskid 
              left join [LTD-ITDB2].servicedesk_new.dbo.changetotaskdetails ctk with (nolock) on tk.taskid = ctk.taskid 
              left join [LTD-ITDB2].servicedesk_new.dbo.changedetails ch2 with (nolock) on ctk.changeid = ch2.changeid 
              left join [LTD-ITDB2].servicedesk_new.dbo.sduser rcti with (nolock) on ct.technicianid = rcti.userid 
              left join [LTD-ITDB2].servicedesk_new.dbo.aaauser rctd with (nolock) on rcti.userid = rctd.user_id 
              left join [LTD-ITDB2].servicedesk_new.dbo.aaauser a with (nolock) on a.user_id = ch.technicianid 
              left join [LTD-ITDB2].servicedesk_new.dbo.change_statusdefinition csd with (nolock) on csd.wfstatusid = ch.wfstatusid 
where  ( ctk.changeid is not null 
                     or ch.changeid is not null ) 

 and 
			  ((ct.createdtime >= (      datediff(s, getutcdate(), getdate())  )
				and ct.createdtime <= 
			  (      datediff(s, getutcdate(), getdate()) 
                                                - datediff(s, getdate(), '1970-01-01 00:00:00') 
                                         ) * cast(1000 as bigint)
			  )
			  or
			  (tk.ACTUALSTARTTIME >=  (      datediff(s, getutcdate(), getdate()) 
                                                - datediff(s, '1/1/2018', '1970-01-01 00:00:00') 
                                         ) * cast(1000 as bigint) 



			  and tk.ACTUALSTARTTIME <= (      datediff(s, getutcdate(), getdate()) 
                                                - datediff(s, getdate(), '1970-01-01 00:00:00') 
                              )          * cast(1000 as bigint)   ))

group by      rctd.first_name
                     ,ctk.changeid
                     ,ch.changeid
                     ,ch.title
                     ,rctd.first_name
                     ,a.first_name
                     ,csd.statusname
                     ,ct.createdtime
                     ,tk.CREATEDDATE
                     ,tk.actualendtime
					 ,tk.ACTUALSTARTTIME

GO
