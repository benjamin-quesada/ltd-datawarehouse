SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

--USE [ltd_dw]
--GO

----/****** Object:  View [pds].[Integration_CITS_Employee]    Script Date: 7/3/2024 1:51:41 PM ******/
----SET ANSI_NULLS ON
----GO

CREATE VIEW [pds].[Integration_CITS_Employee] 
AS
SELECT distinct
CAST([p_empno] AS VARCHAR(32)) [p_empno]
      ,e.[trimmed_emp_no]
      ,e.[numeric_emp_no]
      ,e.[varchar_emp_no]
      ,e.[seniority_number]
      ,e.[seniority_date]
      ,e.[p_fname]
      ,e.[p_mi]
      ,e.[p_lname]
      ,e.[full_name]
      ,e.[p_nickname]
      ,e.[last_and_first]
      ,e.[nickname_and_last]
      ,e.[p_active]
      ,e.[p_department]
      ,e.[distribution_name]
      ,e.[dist_abbreviation]
      ,e.[p_jobcode]
      ,e.[p_jobname]
      ,e.[p_jobdate]
 	  ,CASE WHEN e.p_jobname = 'Bus Operator' THEN 
			COALESCE(c.supLastName COLLATE SQL_Latin1_General_CP1_CI_AS +', '+ c.supFirstName COLLATE SQL_Latin1_General_CP1_CI_AS,CAST(e.[p_supervis] AS VARCHAR(32))  ) 
			ELSE CAST(e.[p_supervis] AS VARCHAR(32)) 
			END p_supervis
			-- if bus operator and midas supervisor is not null then use midas supervisor name

      ,CASE WHEN e.p_jobname = 'Bus Operator' AND c.supLastName+c.supFirstName IS NOT NULL THEN 'Y' ELSE e.p_supv_active END AS [p_supv_active]
			-- if there is a supervisor in midas, then that supervisor is active

      ,CASE WHEN e.p_jobname = 'Bus Operator' THEN 
			COALESCE(c.supervisor_badge  COLLATE SQL_Latin1_General_CP1_CI_AS, e.[empno_supervisor]  COLLATE SQL_Latin1_General_CP1_CI_AS) 
			ELSE CAST(e.[empno_supervisor] AS VARCHAR(32)) 
			END [empno_supervisor]
			-- if bus operator and midas supervisor is not null then use midas supervisor number
      ,e.[p_orighire]
      ,e.[most_recent_hire_date]
      ,e.[most_recent_term_date]
      ,e.[earliest_hire_date]
	  FROM dbo.pds_Integration_CITS_Employee e -- pds vista
	  LEFT OUTER JOIN --SELECT * FROM 
	  ops.supervisor_and_manager_current c -- midas
			ON c.employee_badge COLLATE SQL_Latin1_General_CP1_CI_AS = e.p_empno COLLATE SQL_Latin1_General_CP1_CI_AS
  WHERE NOT (p_lname = 'Johnson' AND p_fname = 'Jane' AND numeric_emp_no = 1210)
  AND NOT (p_lname = 'Doe' AND p_fname = 'John' AND numeric_emp_no = 1209)


GO
GRANT SELECT ON  [pds].[Integration_CITS_Employee] TO [LTD\CITS]
GO
GRANT VIEW DEFINITION ON  [pds].[Integration_CITS_Employee] TO [LTD\CITS]
GO
