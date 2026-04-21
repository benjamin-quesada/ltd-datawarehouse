SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   PROCEDURE  [eam].[work_cost_detail_lab]
@work_order_no INT NULL, @work_order_yr INT NULL
/**********************************


exec eam.work_cost_detail_lab 5947,2021

*/
AS

/*------------------LTD_GLOSSARY---------------
UPDATED BY:	Sopheap Suy
UPDATED DT:  10/31/2024
purpose	 :  Add object activities on who, what, when call this object
			write this data to aud.object_activity table everytime it's called */

SET NOCOUNT ON

DECLARE @SPROC VARCHAR(100)
SET @SPROC = OBJECT_SCHEMA_NAME(@@PROCID) + '.' + OBJECT_NAME(@@PROCID)

INSERT INTO DBA.[aud].[Object_Activity]
	([server_name], [database_name] ,[host_name], [System_User], [object_name]
	,[client_net_address], [local_net_address], [auth_Scheme], [last_read], [last_write]
	,[most_recent_sql_handle], [Timestamp], object_type)
SELECT DISTINCT @@SERVERNAME, DB_NAME(),HOST_NAME(),SYSTEM_USER, @SPROC,
	client_net_address, local_net_address , auth_Scheme, last_read, last_write 
	,most_recent_sql_handle, CURRENT_TIMESTAMP AS [Timestamp], 'PROC'
FROM sys.dm_exec_connections 
WHERE session_id = @@SPID ;


SELECT	m.lab_date
	   ,m.cost,m.labor_rate
	   ,CAST(ROUND(CASE WHEN ISNULL(m.labor_rate,0) = 0 THEN 0 else cost/m.labor_rate END,4) AS DECIMAL(16,4))  labor_calc_hours
	   ,m.EMP_empl_no
	   ,e.name emp_name
	   ,m.TASK_task_code
	   ,d.task_type
	   ,d.[description]
	   ,m.LOC_work_order_loc
	   ,m.work_order_no
	   ,m.work_order_yr
	   ,(LOC_work_order_loc + '-' + CONVERT(VARCHAR, m.work_order_yr) + '-' + CONVERT(VARCHAR, m.work_order_no)) loc_wo_yr
FROM	[LTD-EAM].proto.emsdba.LAB_MAIN m
JOIN	[LTD-EAM].proto.emsdba.DES_MAIN d ON d.TASK_task_code = m.TASK_task_code
JOIN	[ltd-eam].proto.emsdba.EMP_MAIN e ON e.EMP_empl_no = m.EMP_empl_no
WHERE (work_order_yr = @work_order_yr OR @work_order_yr IS NULL)
AND (work_order_no = @work_order_no OR @work_order_no IS NULL)

GO
