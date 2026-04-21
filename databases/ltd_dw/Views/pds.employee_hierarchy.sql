SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   VIEW [pds].[employee_hierarchy]
AS
WITH employee_hierarchy AS (

SELECT DISTINCT p.person_id, 0 AS mgr_id, 0 AS role_level 
, p.role AS job_name 
FROM pds.Integration_EmpPerson p
WHERE emp_person_status = 'Current' AND hr_is_active = 'Y'
              AND p.role_code = '400' -- this is the CEO role
    UNION ALL
    SELECT 
        e.person_id,
        e.mgr_id,
        eh.role_level + 1 -- Increment the level for the next level of the hierarchy
		, e.job_name
    FROM (SELECT person_id, mgr_id, record_created_date, job_name,
				rn=ROW_NUMBER() OVER (PARTITION BY person_id  ORDER BY record_created_date DESC)
			FROM pds.Integration_EmpDirectReport
			WHERE person_id <> 0 
				AND emp_direct_report_status = 'Current' 
		--AND is_primary = 'Y'
	) e
    INNER JOIN pds.Integration_EmpPerson n 
		ON n.person_id = e.person_id 
		AND n.hr_is_active = 'Y' 
		AND n.emp_person_status = 'Current' 
    INNER JOIN employee_hierarchy eh 
		ON eh.person_id = e.mgr_id
      --  WHERE e.rn = 1	
)


SELECT DISTINCT u.emp_person_id
              , u.emp_employee_id
              --, u.role_level
              , u.emp_lastn
              , u.emp_firstn
              , u.mgr_person_id
              , u.mgr_lastn
              , u.mgr_firstn
              , u.mgr_employee_id
			  , u.role
			  , u.job_name
			  , u.organization
			 -- , u.position_code
			  , CAST(hire_date AS DATE) AS hire_date
			  , CAST( s.date_value AS DATE) AS seniority_date
			  , CONVERT(VARCHAR(12), s.date_value,112)+'-'+ RIGHT ('000'+CAST(s.integer_value AS VARCHAR(12)),3) AS seniority_sequence
			 , CASE u.rehire_date WHEN '1900-01-01' THEN NULL ELSE u.rehire_date END AS rehire_date
				, u.actual_hire_date
				, CASE u.termination_date WHEN '1900-01-01' THEN NULL ELSE u.termination_date END AS termination_date
				, CASE h.end_date WHEN '1900-01-01' THEN NULL ELSE h.end_date END AS end_date 
				,  CASE h.start_date WHEN '1900-01-01' THEN NULL ELSE h.start_date END AS start_date 
				
FROM (
--SELECT * FROM (
	SELECT DISTINCT c.person_id emp_person_id
				  , p.employee_id emp_employee_id
				 -- , c.role_level
				  , p.last_name emp_lastn
				  , p.first_name emp_firstn
				  , m.person_id mgr_person_id
					,m.last_name mgr_lastn
					,m.first_name mgr_firstn
					,m.employee_id mgr_employee_id
					, CAST(p.hire_date AS DATE) hire_date
					, p.role
					, c.job_name
					, CAST(p.rehire_date	  AS DATE) rehire_date
					, CAST(p.actual_hire_date AS DATE) actual_hire_date
					, CAST(p.termination_date AS DATE) termination_date
					, p.organization
					,rn=ROW_NUMBER() OVER (PARTITION BY c.person_id, c.mgr_id ORDER BY role_level DESC)
				   FROM employee_hierarchy c 
	LEFT JOIN pds.Integration_EmpPerson p ON p.person_id = c.person_id
	LEFT JOIN pds.Integration_EmpPerson m ON m.person_id = c.mgr_id
	WHERE p.emp_person_status = 'Current'
		AND m.emp_person_status = 'Current'
		AND p.person_id = c.person_id
		AND p.hr_is_active = 'Y' 
		AND m.hr_is_active = 'Y' 
) u
LEFT JOIN pds.Integration_SenioritySeq s ON s.person_id = u.emp_person_id
	AND s.seniority_status = 'Current'
	AND s.field_code = 'SENIORITY_SEQ'
LEFT JOIN pds.Integration_EmpRoleHistory h 
	ON h.person_id = u.emp_person_id
	AND h.role_name = u.job_name
--WHERE rn = 1
--AND h.end_date = '1900-01-01'
--AND u.organization ='Transit Operations'
--ORDER BY u.emp_lastn
--order by u.role --_level, u.mgr_lastn, u.emp_lastn
GO
