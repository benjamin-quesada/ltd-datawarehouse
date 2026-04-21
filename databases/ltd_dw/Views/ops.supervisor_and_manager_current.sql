SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   VIEW [ops].[supervisor_and_manager_current]

AS

SELECT z.emp_SID
	  ,z.employee_badge
	  ,z.empLastName
	  ,z.empFirstName
	  ,z.beginDate
	  ,z.endDate
	  ,z.supervisor_badge
	  ,z.supLastName
	  ,z.supFirstName
	  ,z.manager_badge
	  ,z.mgrLastNm
	  ,z.mgrFirstName	  
	  ,z.CITS_supervisor
--	  ,z.CITS_supervisor2

                                    
 FROM (
SELECT DISTINCT e.[emp_SID]
,t.personnelID employee_badge
,t.empLastName
,t.empFirstName
,e.[beginDate]
,e.[endDate]
,s.personnelID supervisor_badge
,s.supLastName
,s.supFirstName
,q.mgr_id manager_badge ----3rd change
--, q.employee_id
--,q.employee_id manager_badge 
,q.mgrLastNm, q.mgrFirstName
,CITS_supervisor = CASE WHEN s.personnelID IS NULL THEN q.mgrLastNm COLLATE SQL_Latin1_General_CP1_CI_AS +', ' + 
						q.mgrFirstName COLLATE SQL_Latin1_General_CP1_CI_AS +' (' + 
							CAST(q.mgr_id COLLATE SQL_Latin1_General_CP1_CI_AS AS VARCHAR(12)) +')'
						 WHEN s.personnelID IS NOT NULL THEN 	s.supLastName COLLATE SQL_Latin1_General_CP1_CI_AS +', ' + 
									s.supFirstName COLLATE SQL_Latin1_General_CP1_CI_AS +' (' + 
									CAST(s.personnelID COLLATE SQL_Latin1_General_CP1_CI_AS AS VARCHAR(12)) +')' 
									ELSE 'Unassigned' END
,CITS_supervisor2 = 
	CASE WHEN s.personnelID IS NOT NULL THEN s.supLastName COLLATE SQL_Latin1_General_CP1_CI_AS+', ' + s.supFirstName COLLATE SQL_Latin1_General_CP1_CI_AS + ' (' + CAST(s.personnelID COLLATE SQL_Latin1_General_CP1_CI_AS AS VARCHAR(12)) + ')'
	  WHEN s.personnelID IS NULL AND q.employee_id IS NOT NULL 
		THEN q.mgrLastNm+', ' + q.mgrFirstName + ' (' + CAST(q.employee_id AS VARCHAR(12)) + ')' 
		ELSE 'Unassigned' END      
,rnk = RANK() OVER (PARTITION BY e.emp_sid ORDER BY e.beginDate DESC)
FROM [LTD-OPS].[midas].[dbo].[employeeContact] e
	 LEFT JOIN ( ----- the employee detail
		 SELECT DISTINCT emp_SID
		,personnelID
		,lastName empLastName
		,firstName empFirstName
		 FROM [LTD-OPS].[midas].dbo.employee WITH (NOLOCK) 
	 ) t ON t.emp_SID = e.emp_SID
	 LEFT JOIN ( ----- the employees midas supervisor
		 SELECT DISTINCT emp_SID sup_emp_SID
		,personnelID
		,lastName supLastName
		,firstName supFirstName
		 FROM [LTD-OPS].[midas].dbo.employee WITH (NOLOCK) 
	 ) s ON s.personnelID = ISNULL(e.phoneNum4,0)
	 LEFT JOIN (
		SELECT * FROM ( SELECT DISTINCT p.employee_id
		,p.last_name
		,p.first_name
		,sp.employee_id mgr_id --,r.mgr_id --2nd change
		,sp.last_name mgrLastNm
		,sp.first_name mgrFirstName
		,rnk = RANK() OVER (PARTITION BY p.employee_id ORDER BY r.record_created_date ASC)-- SELECT *  
		FROM pds.Integration_EmpPerson p 
			  LEFT JOIN pds.Integration_EmpDirectReport r ON r.person_id = p.person_id
			  LEFT JOIN pds.Integration_EmpPerson sp ON sp.person_id = r.mgr_id
		 WHERE r.mgr_id IS NOT NULL 
			   AND p.emp_person_status = 'current'
			   AND sp.emp_person_status = 'current' 
			   AND r.emp_direct_report_status = 'current' --1st change
			   
			   ) x
			   WHERE x.rnk = 1 -- select only the most current known manager per PDS
	 ) q ON q.employee_id COLLATE SQL_Latin1_General_CP850_CI_AS = t.personnelID
WHERE e.contactRelation = 'PERF'  ----- PERF is used to identify the supervisor record
	) z
WHERE z.rnk = 1
--AND z.CITS_supervisor <> z.CITS_supervisor2
--ORDER BY 1
GO
