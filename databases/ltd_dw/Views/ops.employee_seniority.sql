SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view [ops].[employee_seniority]
as

select 
      [personnelid]   = e.personnelid
      ,[status]        = es.[status]
      ,[lottery]       = es.lottery
      ,[dateseniority] = es.dateseniority
      ,[seniority_seq] = convert(varchar(10), es.dateseniority, 112) + '-' + right('0' + cast(es.lottery as varchar(2)), 2)
      ,[retire_date]   = (select top 1 i.dateeffective from [ltd-ops].midas.dbo.employeestatus i where i.[status] = 'ret' and i.emp_sid = e.emp_sid order by i.dateeffective desc) 
      ,[emp_sid]       = e.emp_sid
	  , p.dw_emp_id
     , p.dw_status
     , p.seniority_date_pds
     , p.pds_person_id
     , p.employee_id
     , p.hire_date
     , p.rehire_date_pds
     , p.termination_date_pds
     , p.review_date_pds
     , p.adjusted_service_date_pds
     , p.return_date_pds
from      -- select * from 
  [ltd-ops].midas.dbo.employee                  e
 inner join [ltd-ops].midas.dbo.ltd_employeecurrentstatus cs on e.emp_sid  = cs.emp_sid
 inner join [ltd-ops].midas.dbo.employeestatus            es on cs.emp_sid = es.emp_sid and cs.status_effective = es.dateeffective
 full outer join (

 select emp_person_id dw_emp_id
	   ,emp_person_status dw_status
	   ,case when seniority_date like '1900%' then null else seniority_date end seniority_date_pds
	   ,person_id pds_person_id
	   ,employee_id
	   ,hire_date
	   --,actual_hire_date
	   ,case when rehire_date like '1900%' then null else rehire_date end rehire_date_pds
	   ,case when termination_date like '1900%' then null else termination_date end termination_date_pds
	   ,case when review_date like '1900%' then null else review_date end review_date_pds
	   ,case when adjusted_service_date like '1900%' then null else adjusted_service_date end adjusted_service_date_pds
	   ,case when return_date like '1900%' then null else return_date end return_date_pds
	    from pds.Integration_EmpPerson
		where trim(organization) = 'Transit OPERATIONS' and emp_person_status = 'Current'
		) p on p.employee_id = e.personnelID collate SQL_Latin1_General_CP1_CI_AS
		
GO
