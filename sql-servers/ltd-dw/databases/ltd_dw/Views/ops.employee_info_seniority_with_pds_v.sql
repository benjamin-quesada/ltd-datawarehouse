SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [ops].[employee_info_seniority_with_pds_v]
AS
/***************************
CREATED DT	: 20240403
CREATED BY	: B Eichberger
PURPOSE		: Support Reporting on Employee Seniority in Midas and PDS
			  


****************************/
WITH ei
AS (SELECT [emp_sid] = e.emp_SID
   ,[status_effective] = MAX(es.dateEffective)
	FROM [LTD-OPS].midas.dbo.employee e
		 LEFT JOIN [LTD-OPS].midas.dbo.employeeStatus es ON es.emp_SID = e.emp_SID
	WHERE es.dateEffective <= GETDATE()
	GROUP BY e.emp_SID)
,pds
AS (SELECT emp_person_id dw_emp_id
   ,emp_person_status dw_status
   ,CASE WHEN seniority_date LIKE '1900%' THEN NULL ELSE seniority_date END seniority_date_pds
   ,person_id pds_person_id
   ,employee_id
   ,hire_date
   --,actual_hire_date
   ,CASE WHEN rehire_date LIKE '1900%' THEN NULL ELSE rehire_date END rehire_date_pds
   ,CASE WHEN termination_date LIKE '1900%' THEN NULL ELSE termination_date END termination_date_pds
   ,CASE WHEN review_date LIKE '1900%' THEN NULL ELSE review_date END review_date_pds
   ,CASE WHEN adjusted_service_date LIKE '1900%' THEN NULL ELSE adjusted_service_date END adjusted_service_date_pds
   ,CASE WHEN return_date LIKE '1900%' THEN NULL ELSE return_date END return_date_pds
	FROM pds.Integration_EmpPerson
	WHERE 1=1
	AND TRIM(organization) = 'Transit Operations'
		  AND emp_person_status = 'Current')
SELECT [lastname] = e.lastName
,[firstname] = e.firstName
,[personnelid] = e.personnelID
,[status] = es.[status]
,[lottery] = es.lottery
,[dateseniority] = es.dateSeniority
,[seniority_seq] = CONVERT(VARCHAR(10), es.dateSeniority, 112) + '-' + RIGHT('0' + CAST(es.lottery AS VARCHAR(2)), 2)
,[retire_date] = (
	 SELECT TOP 1 i.dateEffective
	 FROM employeeStatus i
	 WHERE i.[status] = 'ret'
		   AND i.dateEffective >= GETDATE()
		   AND i.emp_SID = e.emp_SID
	 ORDER BY i.dateEffective DESC
)
,[emp_sid] = e.emp_SID
,p.dw_emp_id
,p.dw_status
,p.seniority_date_pds
,p.pds_person_id
,p.employee_id
,p.hire_date
,p.rehire_date_pds
,p.termination_date_pds
,p.review_date_pds
,p.adjusted_service_date_pds
,p.return_date_pds
FROM [LTD-OPS].midas.dbo.employee e
	 INNER JOIN ei cs ON e.emp_SID = cs.emp_sid
	 INNER JOIN [LTD-OPS].midas.dbo.employeeStatus es ON cs.emp_sid = es.emp_SID
														 AND cs.status_effective = es.dateEffective
	 FULL OUTER JOIN pds p ON p.employee_id = e.personnelID COLLATE SQL_Latin1_General_CP1_CI_AS
WHERE e.emp_SID <> 326;




GO
