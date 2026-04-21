SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE VIEW [cits].[incidents_for_dashboard_demo]
AS
SELECT i.ID,
C.p_lname+', '+COALESCE(C.p_nickname, C.p_fname) operator_nickname_and_last
,i.[Staff Number]
,s.p_lname+', '+COALESCE(s.p_nickname, s.p_fname) supervisor_nickname_and_last
,CAST(i.[Given to Supervisor] AS DATE) [Given to Supervisor]
,i.[Received by Number]
,CAST(i.[Date Entered] AS DATE) [Date Entered]
,i.[Bus Number]
,i.[Route Number]
,CAST(i.[Date Of Incident] AS DATE) [Date Of Incident]
,i.[Time of Incident]
,i.[Direction of Travel]
,i.[Type]
,n.Category Category_of_Incident
,i.[Nature of Incident]
,CAST(i.NOC AS TINYINT) NOC
,CASE WHEN [Staff Comments] IS NOT NULL THEN 1 ELSE 0 END hasSupervisorNotes
FROM cits.CITS_Input i WITH (NOLOCK)
LEFT JOIN [cits].[Nature_of_Input] n ON i.[Nature of Incident] = n.[Nature of Input]
LEFT JOIN pds.Integration_CITS_Employee C WITH (NOLOCK) ON C.varchar_emp_no = i.[Employee Number]
LEFT JOIN pds.Integration_CITS_Employee s WITH (NOLOCK) ON s.varchar_emp_no = i.[Staff Number]
--WHERE n.[CITS_Nature_Status] = 'Current'
--AND i.CITS_STATUS = 'Current'
--AND ((C.p_jobname = 'Bus Operator' )
--WHERE
--([Bus Number] <> '0' OR [Route Number] <> '0')) 
--AND CAST(i.[Given to Supervisor] AS DATE) IS NOT NULL
 GROUP BY 
 i.ID,
C.p_lname+', '+COALESCE(C.p_nickname, C.p_fname) 
,i.[Staff Number]
,s.p_lname+', '+COALESCE(s.p_nickname, s.p_fname) 
,CAST(i.[Given to Supervisor] AS DATE) 
,i.[Received by Number]
,CAST(i.[Date Entered] AS DATE) 
,i.[Bus Number]
,i.[Route Number]
,CAST(i.[Date Of Incident] AS DATE) 
,i.[Time of Incident]
,i.[Direction of Travel]
,i.[Type]
,n.Category 
,i.[Nature of Incident]
,CAST(i.NOC AS TINYINT) 
,CASE WHEN [Staff Comments] IS NOT NULL THEN 1 ELSE 0 END 
	

GO
