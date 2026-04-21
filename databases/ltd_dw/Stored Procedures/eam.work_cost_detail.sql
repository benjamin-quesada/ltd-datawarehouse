SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   PROCEDURE  [eam].[work_cost_detail]
@work_order_no INT NULL, @work_order_yr INT NULL
/**********************************


exec eam.work_cost_detail 5947,2021
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

SELECT	issue_date
	   ,total_cost
	   ,0.00 labor_rate,0.00 hours_calc,'00000' emp_no
	   ,LOC_work_order_loc
	   ,work_order_no
	   ,work_order_yr
	   ,(LOC_work_order_loc + '-' + CONVERT(VARCHAR, work_order_yr) + '-' + CONVERT(VARCHAR, work_order_no)) loc_string
	   ,'Parts' cost_source
FROM	[LTD-EAM].proto.emsdba.PTD_MAIN
WHERE (work_order_yr = @work_order_yr OR @work_order_yr IS NULL)
AND (work_order_no = @work_order_no OR @work_order_no IS NULL)

UNION ALL
SELECT	lab_date
	   ,cost,labor_rate
	   ,CASE WHEN ISNULL(labor_rate,0) = 0 THEN 0 else ROUND(labor_rate,cost/labor_rate,4) end
	   ,EMP_empl_no
	   ,LOC_work_order_loc
	   ,work_order_no
	   ,work_order_yr
	   ,(LOC_work_order_loc + '-' + CONVERT(VARCHAR, work_order_yr) + '-' + CONVERT(VARCHAR, work_order_no))
	   ,'Labor'
FROM	[LTD-EAM].proto.emsdba.LAB_MAIN
WHERE (work_order_yr = @work_order_yr OR @work_order_yr IS NULL)
AND (work_order_no = @work_order_no OR @work_order_no IS NULL)

UNION ALL
SELECT	X_datetime_insert
	   ,labor_cost + parts_cost + misc_cost,0.00
	   ,0.00 labor_rate,'00000' emp_no
	   ,LOC_work_order_loc
	   ,work_order_no
	   ,work_order_yr
	   ,(LOC_work_order_loc + '-' + CONVERT(VARCHAR, work_order_yr) + '-' + CONVERT(VARCHAR, work_order_no))
	   ,'Commercial'
FROM	[LTD-EAM].proto.emsdba.CML_MAIN 
WHERE (work_order_yr = @work_order_yr OR @work_order_yr IS NULL)
AND (work_order_no = @work_order_no OR @work_order_no IS NULL)

GO
