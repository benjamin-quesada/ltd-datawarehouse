SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO








CREATE VIEW [dbo].[pds_Integration_iTRAK_Employee] 
 
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

,lkjn ( person_id, last_job_name,last_distribution_code ) AS (
SELECT person_id, [role],distribution_code FROM (
SELECT rn = ROW_NUMBER() OVER(PARTITION BY person_id ORDER BY [position_status_date] DESC)
	,[position_status_date], person_id,[role],distribution_code FROM [pds].[Integration_EmpPerson] 
	WHERE (person_id <> 0 AND emp_person_status = 'Expired') OR (emp_person_status = 'N' AND role IS NOT NULL)) y
	WHERE rn = 1 AND LTRIM(RTRIM(role)) <> '' )
,lksup AS
(SELECT * FROM (
SELECT p.person_id, rn = ROW_NUMBER() OVER (PARTITION BY p.person_id ORDER BY p.person_id)
, p.last_name, p.first_name,p.organization_code, p.organization
, r.is_primary lk_is_primary, r.job_code lk_job_code, r.pos_name lk_pos_name, r.job_name
, r.mgr_id lk_mgr_id, r.mgr_position lk_mgr_position, p2.hr_is_active sup_active
--,p2.last_name slname, p2.first_name sfname
,LTRIM(RTRIM(p2.last_name + ', ' + p2.first_name)) AS lksup_supervis
,LTRIM(RTRIM(p2.last_name + ', ' + p2.first_name + ' '+COALESCE(p2.middle_initial,p2.middle_name) )) AS lksup_supervisfull
, p2.employee_id sup_emp_no
FROM pds.Integration_EmpPerson p
JOIN (
	SELECT person_id, hr_is_active, last_name,first_name, middle_initial,
	hr_max_active_status = MAX(CAST(hr_status_date AS DATE))  OVER (PARTITION BY person_id, hr_status_date ORDER BY hr_status_date DESC)
	-- in case the person has more than one last active date (was rehired)
	FROM pds.Integration_EmpPerson WITH(NOLOCK)
	WHERE hr_is_active = 'Y' -- the person last active date in their primary role
	) q ON q.person_id = p.person_id AND CAST(p.hr_status_date AS DATE) = q.hr_max_active_status
LEFT JOIN pds.Integration_EmpDirectReport r 
		ON r.person_id = p.person_id AND r.job_code = r.job_code
		AND r.pos_code = p.position_code AND r.org_code = p.organization_code
LEFT JOIN  pds.Integration_EmpPerson p2 WITH(NOLOCK) ON p2.person_id = r.mgr_id
WHERE EXISTS (SELECT person_id FROM pds.Integration_EmpPerson n WITH(NOLOCK)
							WHERE p.person_id = n.person_id 
							AND hr_is_active = 'N' 
							AND [emp_person_status] = 'Current'
							)
							) o
WHERE rn = 1 )

,con AS (
SELECT person_id, contact_name = STUFF(
		(SELECT '; ' + contact_name+'  '+phone_no1, person_id
					FROM pds.Integration_EmpContact T1
					WHERE emp_econtact_status = 'Current' AND t1.person_id = t2.person_id
					FOR XML PATH(''), TYPE).value('.', 'varchar(254)'),1,1, '')
FROM pds.Integration_EmpContact T2
GROUP BY person_id
)



SELECT o.person_id,
p_empno						= [employee_number] ,
trimmed_emp_no				= RTRIM(LTRIM([employee_number])) ,
numeric_emp_no				= CAST([employee_number] AS INT),
varchar_emp_no				= CAST([employee_number] AS VARCHAR(12)),
seniority_number			= o.[seniority_number] ,
seniority_date				= REPLACE(CAST(REPLACE(o.seniority_date,'1900-01-01','') AS VARCHAR(15)),'1900-01-01',''),
p_fname						= o.[first_name] ,
p_mi						= o.middle_name ,
p_lname						= o.last_name ,
full_name					= o.fullname ,
p_nickname					= CASE WHEN RTRIM(LTRIM(o.aka)) = '' THEN o.[first_name] ELSE RTRIM(LTRIM(o.aka)) END,
last_and_first				= CASE WHEN LEN(LTRIM(RTRIM(ISNULL(o.last_name,'') + ', ' + ISNULL(o.first_name,'')))) < 4 THEN NULL ELSE 
									LTRIM(RTRIM(ISNULL(o.last_name,'') + ', ' + ISNULL(o.first_name,''))) END ,
nickname_and_last			= CASE WHEN LEN(LTRIM(RTRIM(CASE WHEN LEN(ISNULL(o.aka,'')) > 1 THEN o.aka ELSE o.first_name END + ' '+ o.last_name))) < 4 THEN NULL ELSE
									LTRIM(RTRIM(CASE WHEN LEN(o.aka) > 1 THEN o.aka ELSE o.first_name END + ' '+ o.last_name)) END,
p_active					= [currently_active] ,
p_department				= COALESCE(o.organization_code , s.organization_code),
distribution_name,
dist_abbreviation,
p_jobcode					= COALESCE(o.job_code, s.lk_job_code),
p_jobname					= COALESCE(o.position_role ,s.job_name),
gender_code,
p_jobdate					= REPLACE(REPLACE(o.position_status_date,'1900-01-01',''),'1900-01-01','') ,
p_supervis					= CASE WHEN LEN(LTRIM(RTRIM(ISNULL(p2.last_name,'') + ', ' + ISNULL(p2.first_name,'')))) < 4
										AND s.lksup_supervis IS NOT NULL THEN s.lksup_supervis  
										ELSE LTRIM(RTRIM(ISNULL(p2.last_name,'') + ', ' + ISNULL(p2.first_name,''))) END,
p_supervis_full				= CASE WHEN LEN(RTRIM(LTRIM(RTRIM(ISNULL(p2.last_name,'') + ', ' + ISNULL(p2.first_name,''))) + ' ' + LTRIM(RTRIM(ISNULL(p2.middle_name,''))))) < 6 
										AND s.lksup_supervisfull IS NOT NULL THEN s.lksup_supervisfull
										ELSE LTRIM(RTRIM(ISNULL(p2.last_name,''))) + ', ' + ISNULL(p2.first_name,'') + ' ' + LTRIM(RTRIM(ISNULL(p2.middle_name,''))) END,
p_supv_active				= COALESCE(p2.hr_is_active,s.sup_active),
empno_supervisor			= COALESCE(p2.employee_id,s.sup_emp_no),
p_orighire					= REPLACE(CAST(REPLACE([earliest_hire_date],'1900-01-01','') AS VARCHAR(15)),'1900-01-01',''),
[most_recent_hire_date]		= REPLACE(CAST(REPLACE([most_recent_hire_date],'1900-01-01','') AS VARCHAR(15)),'1900-01-01',''),
[most_recent_term_date]		= REPLACE(CAST(REPLACE([most_recent_term_date],'1900-01-01','') AS VARCHAR(15)),'1900-01-01',''),
[earliest_hire_date]		= REPLACE(CAST(REPLACE([earliest_hire_date],'1900-01-01','') AS VARCHAR(15)),'1900-01-01',''),
[street],
[city],
[state],
[zip],
[telephone_number],
mobile_phone_number,
l.last_job_name,
last_distribution_code		= LEFT(l.last_distribution_code,3) + '.'+RIGHT(l.last_distribution_code,2) 
,EmergContact = contact_name
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
      ,p.hr_is_active AS [currently_active]
      ,CAST(h.hdt AS DATE) AS [most_recent_hire_date]
      ,REPLACE(t.tdt,'1900-01-01','') AS [most_recent_term_date]
	  ,REPLACE(CAST(x.pdt AS DATE),'1900-01-01','') AS [earliest_hire_date]
      ,[role] AS [job_title]
	  ,p.[job_code]
	  ,p.[role] AS position_role
	  ,p.gender_code
	  ,p.organization_code
	  ,CAST(p.position_status_date AS DATE) position_status_date
	  ,d.mgr_position
	  ,d.mgr_id
	  ,i.distribution_name
	  ,i.dist_abbreviation
      ,p.organization_code AS [department]
      ,f.phone_number AS [telephone_number]
      ,c.phone_number AS [mobile_phone_number]
      ,[seniority_date] AS [seniority_date]
      ,s.seniority_nbr AS [seniority_number]
      ,a.address_lines AS [street]
      ,a.city AS [city]
      ,a.state AS [state]
      ,a.zip_code AS [zip]
	  ,n.contact_name
  FROM pds.integration_EmpPerson p
  LEFT JOIN pds.Integration_EmpDirectReport d ON d.person_id = p.person_id AND d.job_code = p.job_code AND d.pos_code = p.position_code AND d.emp_direct_report_status = 'Current' 
  LEFT JOIN pds.Integration_Distribution i WITH (NOLOCK) ON i.distribution_code = p.distribution_code AND i.distribution_status = 'Current'
  LEFT JOIN pds.Integration_EmpAddress a WITH (NOLOCK) ON a.person_id = p.person_id AND a.emp_address_status = 'Current' AND address_code = 'HOME' 
  LEFT JOIN pds.Integration_EmpPhone f ON f.person_id = p.person_id AND f.emp_phone_status = 'Current' AND f.is_primary = 'Y' 
  LEFT JOIN pds.Integration_EmpPhone c ON c.person_id = p.person_id AND c.emp_phone_status = 'Current' AND c.phone_code = 'CELL'
  LEFT JOIN con n ON n.person_id = p.person_id
  LEFT JOIN sen s ON s.person_id = p.person_id
  LEFT JOIN hdt h ON h.person_id = p.person_id
  LEFT JOIN pdt x ON x.person_id = p.person_id
  LEFT JOIN tdt t ON t.person_id = p.person_id
  WHERE p.emp_person_status = 'Current' AND p.hr_is_active IN ('Y','N')
) o
LEFT JOIN 
(SELECT person_id,last_name,first_name,middle_name,middle_initial,aka,initials,employee_id,[role],hr_is_active FROM 
	pds.integration_EmpPerson 
	WHERE emp_person_status = 'Current'
	GROUP BY person_id,last_name,first_name,middle_name,middle_initial,aka,initials,employee_id,[role],hr_is_active) p2 
ON p2.person_id = o.mgr_id
LEFT JOIN lkjn l ON l.person_id = o.person_id
LEFT JOIN lksup s ON s.person_id = o.person_id
WHERE NOT (o.last_name = 'Johnson' AND o.first_name = 'Jane' AND CAST([employee_number] AS INT) = 1210)
  AND NOT (o.last_name = 'Doe' AND o.first_name = 'John' AND CAST([employee_number] AS INT) = 1209)

GO
