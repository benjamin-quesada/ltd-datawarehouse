SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO









CREATE VIEW [dbo].[pds_Integration_CITS_Employee]
AS



WITH hdt (person_id, hdt) AS (
	SELECT person_id, MAX(dt) hdt FROM (
		SELECT person_id,MAX(hire_date) AS dt FROM pds.integration_EmpPerson WITH (NOLOCK) GROUP BY person_id
		UNION
		SELECT person_id,MAX(rehire_date) AS dt FROM pds.integration_EmpPerson WITH (NOLOCK) GROUP BY person_id
		UNION
		SELECT person_id,MAX(actual_hire_date) AS dt FROM pds.integration_EmpPerson WITH (NOLOCK) GROUP BY person_id)
		o
		GROUP BY person_id
	)
,pdt (person_id, pdt) AS (
	SELECT person_id, MIN(dt) hdt FROM (
		SELECT person_id,MIN(hire_date) AS dt FROM pds.integration_EmpPerson WITH (NOLOCK) GROUP BY person_id
		UNION
		SELECT person_id,MIN(rehire_date) AS dt FROM pds.integration_EmpPerson WITH (NOLOCK) GROUP BY person_id
		UNION
		SELECT person_id,MIN(actual_hire_date) AS dt FROM pds.integration_EmpPerson WITH (NOLOCK) GROUP BY person_id)
		o
		GROUP BY person_id
	)
,tdt (person_id, tdt) AS (
	SELECT person_id,CAST(MAX(termination_date) AS DATE) AS tdt FROM pds.integration_EmpPerson WITH (NOLOCK) GROUP BY person_id
	)
,sen (person_id,seniority_nbr) AS (
SELECT person_id, integer_value FROM [pds].[Integration_SenioritySeq] WHERE [seniority_status] = 'Current')

SELECT DISTINCT
p_empno						= [employee_number] ,
trimmed_emp_no				= RTRIM(LTRIM([employee_number])) ,
numeric_emp_no				= CAST([employee_number] AS INT),
varchar_emp_no				= CAST([employee_number] AS VARCHAR(12)),
seniority_number			= seniority_nbr ,
seniority_date				= REPLACE(CAST(REPLACE(o.seniority_date,'0001-01-01','') AS VARCHAR(15)),'1900-01-01',''),
p_fname						= o.[first_name] ,
p_mi						= o.middle_name ,
p_lname						= o.last_name ,
full_name					= o.fullname ,
p_nickname					= CASE WHEN RTRIM(LTRIM(o.aka)) = '' THEN o.[first_name] ELSE RTRIM(LTRIM(o.aka)) END,
last_and_first				= LTRIM(RTRIM(o.last_name + ', ' + o.first_name)) ,
nickname_and_last			= LTRIM(RTRIM(CASE WHEN LEN(o.aka)>1 THEN o.aka ELSE o.first_name END + ' '+ o.last_name)) ,
p_active					= [currently_active] ,
p_department				= o.organization_code ,
distribution_name,
dist_abbreviation,
p_jobcode					= o.job_code ,
p_jobname					= o.position_role ,
p_jobdate					= REPLACE(CAST(REPLACE(o.position_status_date,'0001-01-01','') AS VARCHAR(15)),'1900-01-01','') ,
p_supervis					= LTRIM(RTRIM(p2.last_name + ', ' + p2.first_name)) ,
p_supv_active				= p2.hr_is_active,
empno_supervisor			= p2.employee_id,
p_orighire					= REPLACE(CAST(REPLACE([earliest_hire_date],'0001-01-01','') AS VARCHAR(15)),'1900-01-01',''),
[most_recent_hire_date]		= REPLACE(CAST(REPLACE([most_recent_hire_date],'0001-01-01','') AS VARCHAR(15)),'1900-01-01',''),
[most_recent_term_date]		= REPLACE(CAST(REPLACE([most_recent_term_date],'0001-01-01','') AS VARCHAR(15)),'1900-01-01',''),
[earliest_hire_date]		= REPLACE(CAST(REPLACE([earliest_hire_date],'0001-01-01','') AS VARCHAR(15)),'1900-01-01','')
FROM (
SELECT p.person_id,
p.employee_id AS [employee_number]
      ,p.[first_name]
      ,p.[middle_name]
      ,p.[last_name]
	  ,p.fullname
	  ,p.aka
	  ,f.phone_number AS home_phone
	  ,c.phone_number AS cell_phone
      --,d.mgr_name as [supervisor_name]
      ,p.hr_is_active AS [currently_active]
      ,CAST(h.hdt AS DATE) AS [most_recent_hire_date]
      ,REPLACE(t.tdt,'1900-01-01','') AS [most_recent_term_date]
	  ,REPLACE(CAST(x.pdt AS DATE),'1900-01-01','') AS [earliest_hire_date]
      ,[role] AS [job_title]
	  ,p.[job_code]
	  ,p.[role] AS position_role
	  ,p.organization_code
	  ,CAST(p.position_status_date AS DATE) position_status_date
	  --,d.last_name mgr_last_name
	  --,d.first_name mgr_first_name
	  ,d.mgr_position
	  ,d.mgr_id
	  ,d.is_primary
	  --,distribution_name = REPLACE(i.distribution_name,'&','and')
	  --,dist_abbreviation = REPLACE(i.dist_abbreviation,'&','PLANDEV')
	  ,i.distribution_name
	  ,i.dist_abbreviation
      ,f.phone_number AS [telephone_number]
      ,c.phone_number AS [mobile_phone_number]
      ,REPLACE(CAST(REPLACE(CAST(p.[seniority_date] AS DATE),'1900-01-01','') AS VARCHAR(15)),'1900-01-01','') AS [seniority_date]
      ,s.seniority_nbr
      ,a.city AS [city]
      ,a.state AS [state]
      ,a.zip_code AS [zip]
  --select count(*) 
  FROM pds.integration_EmpPerson p 
  --where emp_person_status = 'Current' -- 1129
  LEFT JOIN pds.Integration_EmpDirectReport d ON d.person_id = p.person_id AND d.job_code = p.job_code AND d.pos_code = p.position_code AND d.emp_direct_report_status = 'Current' 
  LEFT JOIN pds.Integration_Distribution i WITH (NOLOCK) ON i.distribution_code = p.distribution_code AND i.distribution_status = 'Current'
  LEFT JOIN pds.Integration_EmpAddress a WITH (NOLOCK) ON a.person_id = p.person_id AND a.emp_address_status = 'Current' AND address_code = 'HOME' 
  LEFT JOIN pds.Integration_EmpPhone f WITH (NOLOCK) ON f.person_id = p.person_id AND f.emp_phone_status = 'Current' AND f.is_primary = 'Y' 
  LEFT JOIN pds.Integration_EmpPhone c WITH (NOLOCK) ON c.person_id = p.person_id AND c.emp_phone_status = 'Current' AND c.phone_code = 'CELL'
  LEFT JOIN sen s ON s.person_id = p.person_id
  LEFT JOIN hdt h ON h.person_id = p.person_id
  LEFT JOIN pdt x ON x.person_id = p.person_id
  LEFT JOIN tdt t ON t.person_id = p.person_id
  WHERE p.emp_person_status = 'Current' AND p.hr_is_active IN ('Y','N')
) o
LEFT JOIN 
(SELECT person_id,last_name,first_name,middle_name,middle_initial,aka,initials,employee_id,[role],hr_is_active FROM 
	pds.integration_EmpPerson 
	WHERE hr_is_active = 'Y' AND emp_person_status = 'Current'
	GROUP BY person_id,last_name,first_name,middle_name,middle_initial,aka,initials,employee_id,[role],hr_is_active) p2 
ON p2.person_id = o.mgr_id
--where currently_active = 'Y'
--where o.[first_name] in ( 'erica','lydia')
--order by [most_recent_term_date] desc

WHERE NOT (o.last_name = 'Johnson' AND o.first_name = 'Jane' AND CAST([employee_number] AS INT) = 1210)
  AND NOT (o.last_name = 'Doe' AND o.first_name = 'John' AND CAST([employee_number] AS INT) = 1209)
GO
GRANT SELECT ON  [dbo].[pds_Integration_CITS_Employee] TO [LTD\CITS]
GO
GRANT SELECT ON  [dbo].[pds_Integration_CITS_Employee] TO [public]
GO
