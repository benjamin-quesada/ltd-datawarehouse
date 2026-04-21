SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [eam].[draw_down_test_loader]
AS

	/*
CREATED BY:		B. Eichberger
CREATED ON:		20240926
PURPOSE   :		Populate a table with TEST data to enable report compares

MODIFIED DATE	MODIFIIED BY		DESCRIPTION

exec eam.[draw_down_test_loader]

select * from [eam].[draw_down_test] where work_order_no = 7631
	
*------------------LTD_GLOSSARY---------------
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

BEGIN TRY

DROP TABLE if exists #test_eamlabor
DROP TABLE if exists #test_empl
DROP TABLE if exists #test_jobmain
DROP TABLE if exists #test_parts
DROP TABLE if exists #test_reason



SELECT [EMP_empl_no] AS employee_id
		,REPLACE([name],'ý','') AS full_name
INTO #test_empl
FROM [LTD-TEST-EAMV22].[proto].[emsdba].[EMP_MAIN]
WHERE active = 'Y'
OPTION(MAXDOP 2) ;

SELECT	m.work_order_no
		,m.work_order_yr
		,work_order_yr_no = CAST(m.work_order_yr AS VARCHAR(32)) + '-' + CAST(m.work_order_no AS VARCHAR(32))
		,m.EQ_equip_no
		,m.ACCT_acct_code AS account_id
		,m.indirect_flag
		,m.REAS_reas_for_repair
		,SUM(m.[hours]) AS labor_hours
		,SUM(m.cost) cost_eam
		,calc_cost = SUM(m.[hours] * m.labor_rate)
		,t.warranty task_warranty
		,t.equip_warr_work
		,SUM(t.amt_warr_recovered) amt_warr_recovered
INTO	#test_eamlabor
FROM	[LTD-TEST-EAMV22].proto.[emsdba].[LAB_MAIN] m WITH(NOLOCK)
LEFT JOIN [LTD-TEST-EAMV22].proto.[emsdba].[TSK_MAIN] t ON t.TASK_task_code = m.TASK_task_code AND t.work_order_yr = m.work_order_yr AND t.work_order_no = m.work_order_no
WHERE	ISNULL(m.work_order_yr, 0) >= 2022
		AND m.fully_reversed = 'N'
		AND m.work_order_yr <= YEAR(GETDATE())
		AND m.posting_complete = 'Y'
		AND RTRIM(LTRIM(m.EQ_equip_no)) <> ''
		AND (ISNUMERIC(m.CLASS_class_maint) = 1 OR m.CLASS_class_maint LIKE '%ALLFLEET%')  --Per Matt, Added to filter to allow for ALLFLEET records --Pamela Mahan 08162023
		AND m.[work_order_yr] >= 2022
		AND m.[work_order_yr] <= YEAR(GETDATE())
GROUP BY m.work_order_no
		,m.work_order_yr
		,m.EQ_equip_no
		,m.ACCT_acct_code
		,m.indirect_flag
		,m.REAS_reas_for_repair
		,t.warranty
		,t.equip_warr_work
OPTION(MAXDOP 2) ;

SELECT	meter_1_reading
		,work_order_yr
		,work_order_no
		,ACCT_acct_code  AS account_id
		,work_order_status
		,meter_1_life_total
		,[usr_finished_by] = LOWER(USR_finished_by)
		,[usr_closed_by] = LOWER(USR_closed_by)
		,[datetime_closed]
		,[datetime_open]
		,[warranty]
		,[comml_cost]
		,comment_area
		,[REAS_reas_for_repair]
INTO	#test_jobmain
FROM	[LTD-TEST-EAMV22].proto.emsdba.JOB_MAIN WITH(NOLOCK)
WHERE	ISNULL(work_order_yr, 0) >= 2022
OPTION(MAXDOP 2) ;

SELECT [RepairReasonID]
		,[Description]
INTO #test_reason
FROM [LTD-TEST-EAMV22].[proto].[emsdba].[QRepairReason] WITH(NOLOCK)
OPTION(MAXDOP 2) ;	
	
SELECT	*		
INTO	#test_parts
FROM	OPENQUERY
	([LTD-TEST-EAMV22], '
SELECT work_order_yr_no=CAST(pm.work_order_yr AS VARCHAR(32))+''-''+CAST(pm.work_order_no AS VARCHAR(32))
  ,SUM([qty_issued]) qty_issued,[EQ_equip_no]
  ,SUM([amt_warr_recovered]) amt_warr_recovered
  ,SUM(pm.total_cost) parts_total_cost
  ,SUM(pm.total_cost)-SUM([amt_warr_recovered]) total_cost_minus_warranty
FROM proto.[emsdba].[PTD_MAIN] pm WITH (NOLOCK) --
WHERE pm.work_order_yr >= 2022 and pm.work_order_yr <= year(getdate())
		AND pm.[fully_reversed] = ''N''
		AND pm.return_flag <> ''Y''	
group by 
CAST(pm.work_order_yr AS VARCHAR(32))+''-''+CAST(pm.work_order_no AS VARCHAR(32))	,[EQ_equip_no]
OPTION (MAXDOP 2)') ;

--SELECT * FROM #test_parts WHERE parts_total_cost <> total_cost_minus_warranty


TRUNCATE TABLE [eam].[draw_down_test]
	
INSERT INTO [eam].[draw_down_test]
           ([rn]
           ,[work_order_yr]
           ,[work_order_no]
           ,[work_order_yr_no]
           ,[account_id]
           ,[usr_closed_by]
           ,[usr_finished_by]
           ,[EQ_equip_no]
           ,[busclass]
           ,[datetime_closed]
           ,[datetime_open]
           ,[warranty]
           ,[comml_cost]
           ,[indirect_flag]
           ,[eam_labor_cost]
           ,[ltd_calculated_labor_cost]
           ,[parts_issued_value]
		   ,parts_total_cost
		   ,REAS_reas_for_repair
		   ,[Description]
		   ,comment_area)

	SELECT	u.rn
		   ,u.work_order_yr
		   ,u.work_order_no
		   ,u.work_order_yr_no
		   ,LEFT(u.account_id, 32) account_id
		   ,usr_closed_by = [dbo].[fn_ProperCase](LEFT(u.usr_closed_by COLLATE SQL_Latin1_General_CP1_CI_AS, 90))
		   ,usr_finished_by = [dbo].[fn_ProperCase](LEFT(u.usr_finished_by COLLATE SQL_Latin1_General_CP1_CI_AS, 90))
		   ,u.EQ_equip_no
		   ,busclass = CASE WHEN ISNUMERIC(u.EQ_equip_no)= 1
							THEN CAST(ROUND(u.EQ_equip_no, -2) AS INT)
							ELSE 0 END
		   ,u.[datetime_closed]
		   ,u.[datetime_open]
		   ,u.[warranty]
		   ,u.[comml_cost]
		   ,u.indirect_flag
		   ,u.cost_eam AS eam_labor_cost
		   ,u.calc_cost AS ltd_calculated_labor_cost
		   ,parts_issued_value = p.parts_total_cost
		   ,parts_total_cost = p.parts_total_cost
		   ,u.REAS_reas_for_repair
		   ,u.[Description]
		   ,u.comment_area
	FROM
	(	SELECT	rn = ROW_NUMBER() OVER (PARTITION BY l.work_order_yr
													,l.work_order_no
										ORDER BY j.[datetime_open])
			   ,l.work_order_yr
			   ,l.work_order_no
			   ,j.account_id
			   ,work_order_yr_no = CAST(l.work_order_yr AS VARCHAR(32)) + '-' + CAST(l.work_order_no AS VARCHAR(32))
			   ,l.indirect_flag
			   ,l.EQ_equip_no
			   ,l.cost_eam
			   ,calc_cost
			   ,j.[datetime_closed]
			   ,j.[datetime_open]
			   ,warranty = CASE WHEN l.task_warranty = 'YES' OR j.[warranty] = 'YES' OR l.equip_warr_work = 'YES' THEN 'YES' ELSE 'NO' END
			   ,j.[comml_cost]
			   ,[usr_finished_by] = COALESCE(jf.full_name COLLATE SQL_Latin1_General_CP1_CI_AS, j.usr_finished_by)
			   ,[usr_closed_by] = COALESCE(jc.full_name COLLATE SQL_Latin1_General_CP1_CI_AS, j.usr_closed_by)
			   ,j.REAS_reas_for_repair
			   ,r.[Description]
			   ,j.comment_area
		FROM	#test_eamlabor l
		LEFT JOIN #test_jobmain j WITH(NOLOCK)ON j.work_order_yr = l.work_order_yr
											AND j.work_order_no = l.work_order_no
		LEFT JOIN #test_empl jc WITH(NOLOCK)ON CAST(jc.employee_id AS VARCHAR(50)) COLLATE SQL_Latin1_General_CP1_CI_AS = j.usr_closed_by COLLATE SQL_Latin1_General_CP1_CI_AS
		LEFT JOIN #test_empl jf WITH(NOLOCK)ON CAST(jf.employee_id AS VARCHAR(50)) COLLATE SQL_Latin1_General_CP1_CI_AS = j.usr_finished_by COLLATE SQL_Latin1_General_CP1_CI_AS
		LEFT JOIN #test_reason r ON r.[RepairReasonID] = j.REAS_reas_for_repair
		) u
		LEFT JOIN #test_parts p ON p.work_order_yr_no = CAST(u.work_order_yr AS VARCHAR(32)) + '-' + CAST(u.work_order_no AS VARCHAR(32))


DROP TABLE if exists #test_eamlabor
DROP TABLE if exists #test_empl
DROP TABLE if exists #test_jobmain
DROP TABLE if exists #test_parts
DROP TABLE if exists #test_reason

END TRY
BEGIN CATCH

	DECLARE @profile VARCHAR(255) =
			(SELECT name FROM msdb .dbo.sysmail_profile)  ;
	DECLARE @errormsg VARCHAR(MAX)
		   ,@error INT
		   ,@message VARCHAR(MAX)
		   ,@xstate INT
		   ,@errsev INT
		   ,@sub VARCHAR(255) ;

	SELECT	@error = ERROR_NUMBER()
		   ,@errsev = ERROR_SEVERITY()
		   ,@message = ERROR_MESSAGE()
		   ,@xstate = XACT_STATE() ;

	SELECT	@errormsg = 'Error in ' + ISNULL(@SPROC, '') + ': ' + CAST(ISNULL(@error, '') AS NVARCHAR(32)) + '|' + COALESCE(@message, '') + '|' + CAST(ISNULL(@xstate, '') AS NVARCHAR(32)) + '|' + CAST(ISNULL(@errsev, '') AS NVARCHAR(32)) ;

	SELECT	@sub = 'ERROR: ' + @SPROC ;

	EXEC msdb.dbo.sp_send_dbmail @profile_name = @profile
								,@recipients = 'barb.eichberger@ltd.org'
								,@subject = @sub
								,@body = @errormsg ;

	RAISERROR(@errormsg, @errsev, 1) ;
END CATCH ;


GO
