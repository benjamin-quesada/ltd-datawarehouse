SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE     PROCEDURE  [eam].[merge_eq_mile_daily_fct]
AS

/*-----------LTD_GLOSSARY---------------
CREATED BY:	Sopheap Suy
UPDATED DT: 09/08/2025 
purpose	:	pull data from eam.equipment_main, eam.EAM_ALL_MILE_ACTIVITY, eam.eq_main_stage
			and reporting.tm.DW_CALENDAR
use		:	exec eam.merge_eq_mile_daily_fct

purpose	 :  Add object activities on who, what, when call this object
			write this data to aud.object_activity table everytime it's called 


*/
SET NOCOUNT ON

DECLARE @SPROC VARCHAR(100)
SET @SPROC = OBJECT_SCHEMA_NAME(@@PROCID) + '.' + OBJECT_NAME(@@PROCID)


DECLARE		@ins INT,
			@upd INT --, 			@del INT

INSERT INTO dba.aud.Object_Activity
	(server_name, database_name ,host_name, [System_User], object_name
	,client_net_address, local_net_address, auth_Scheme, last_read, last_write
	,most_recent_sql_handle, Timestamp, object_type)
SELECT DISTINCT @@SERVERNAME, DB_NAME(),HOST_NAME(),SYSTEM_USER, @SPROC,
	client_net_address, local_net_address , auth_Scheme, last_read, last_write 
	,most_recent_sql_handle, CURRENT_TIMESTAMP AS Timestamp, 'PROC'
FROM sys.dm_exec_connections 
WHERE session_id = @@SPID ;

BEGIN TRY

DECLARE @sdt DATETIME2 = SYSDATETIME()

INSERT eam.eq_mile_daily_fct(calendar_id ,
	eq_key ,
	mileage,
	delete_date ,
	record_updated_date)
SELECT a.CALENDAR_ID,
	a.eq_key,  --e.begin_Date, e.end_date,
	a.meter_value,
	'9999-12-31',
	GETDATE()
FROM  (
	SELECT c.eq_key, c.CALENDAR_ID, --c.meter_value, 
	COALESCE( c.meter_value
		,  MAX( meter_value) OVER (PARTITION BY eq_key 
								ORDER BY c.CALENDAR_ID ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)) AS meter_value
	FROM (
		SELECT e.eq_key , c.CALENDAR_ID, c.CALENDAR_DATE ,m.meter_value 
		FROM  eam.equipment_main e
		INNER JOIN reporting.tm.DW_CALENDAR c
			ON c.CALENDAR_DATE BETWEEN  e.begin_Date AND e.end_date
		--LEFT JOIN (SELECT eq_equip_no,MAX(meter_value) AS meter_value,the_date 
		--			FROM eam.EAM_ALL_MILE_ACTIVITY 
		--			WHERE label_name NOT IN ('JOB_MAIN;METER_1_LIFE_TOTAL;DATETIME_PM_SCHED')					
					--WHERE eq_equip_no = '25101'
					--GROUP BY eq_equip_no, the_date 	) m
		LEFT JOIN (	SELECT eq_equip_no, MAX(life_total_meter_1) meter_value, CAST(X_datetime_update AS DATE) the_date FROM eam.eq_main_stage
					--WHERE eq_equip_no = '1106'
					GROUP BY eq_equip_no,  CAST(X_datetime_update AS DATE)	) m

			ON m.eq_equip_no = e.eq_equip_no
			AND m.the_date = c.CALENDAR_DATE
			--ORDER BY m.the_date
		) c
	) a
WHERE (a.meter_value IS NOT NULL AND a.meter_value <> 0)
AND NOT EXISTS (SELECT 1 FROM eam.eq_mile_daily_fct f 
				WHERE a.eq_key = f.eq_key
				--AND a.meter_value = f.mileage
				AND a.CALENDAR_ID = f.calendar_id)
--ORDER BY a.eq_key, a.CALENDAR_ID

SET @ins = @@ROWCOUNT

UPDATE f
SET f.fuel_mileage = m.meter_value
FROM eam.eq_mile_daily_fct f
INNER JOIN (
		SELECT e.eq_key , c.CALENDAR_ID, c.CALENDAR_DATE ,m.meter_value 
		FROM  eam.equipment_main e
		INNER JOIN reporting.tm.DW_CALENDAR c
			ON c.CALENDAR_DATE BETWEEN  e.begin_Date AND e.end_date
		LEFT JOIN (SELECT eq_equip_no,MAX(meter_value) AS meter_value,the_date 
					FROM eam.EAM_ALL_MILE_ACTIVITY 
					WHERE label_name = 'FTK_MAIN;METER_1_LIFE_TOTAL;FTK_DATE'
					--AND eq_equip_no = '25101'
					GROUP BY eq_equip_no, the_date
					) m
			ON m.eq_equip_no = e.eq_equip_no
			AND m.the_date = c.CALENDAR_DATE
			WHERE m.meter_value IS NOT NULL) m
ON m.eq_key = f.eq_key
AND m.CALENDAR_ID = f.calendar_id
WHERE f.fuel_mileage IS NULL

SET @upd = @@ROWCOUNT

UPDATE f
SET f.pm_due_mileage = m.meter_value
FROM eam.eq_mile_daily_fct f
INNER JOIN (
		SELECT e.eq_key , c.CALENDAR_ID, c.CALENDAR_DATE ,m.meter_value 
		FROM  eam.equipment_main e
		INNER JOIN reporting.tm.DW_CALENDAR c
			ON c.CALENDAR_DATE BETWEEN  e.begin_Date AND e.end_date
		LEFT JOIN (SELECT eq_equip_no,MAX(meter_value) AS meter_value,the_date 
					FROM eam.EAM_ALL_MILE_ACTIVITY 
					WHERE label_name IN ('TSK_MAIN;METER_1_LIFE_TOTAL;DATE_PM_DUE',
									'JOB_MAIN;METER_1_LIFE_TOTAL;DATETIME_PM_SCHED')
					--AND eq_equip_no = '24101'
					GROUP BY eq_equip_no, the_date
					) m
			ON m.eq_equip_no = e.eq_equip_no
			AND m.the_date = c.CALENDAR_DATE
			WHERE m.meter_value IS NOT NULL) m
ON m.eq_key = f.eq_key
AND m.CALENDAR_ID = f.calendar_id
WHERE f.pm_due_mileage IS NULL

SET @upd =@upd+ @@ROWCOUNT


UPDATE f
SET f.out_of_service_mileage = m.meter_value
FROM eam.eq_mile_daily_fct f
INNER JOIN (
		SELECT e.eq_key , c.CALENDAR_ID, c.CALENDAR_DATE ,m.meter_value 
		FROM  eam.equipment_main e
		INNER JOIN reporting.tm.DW_CALENDAR c
			ON c.CALENDAR_DATE BETWEEN  e.begin_Date AND e.end_date
		LEFT JOIN (SELECT eq_equip_no,MAX(meter_value) AS meter_value,the_date 
					FROM eam.EAM_ALL_MILE_ACTIVITY 
					WHERE label_name = 'JOB_MAIN;METER_1_LIFE_TOTAL;DATETIME_OUT_SERVICE'
					--AND eq_equip_no = '25101'
					GROUP BY eq_equip_no, the_date
					) m
			ON m.eq_equip_no = e.eq_equip_no
			AND m.the_date = c.CALENDAR_DATE
			WHERE m.meter_value IS NOT NULL) m
ON m.eq_key = f.eq_key
AND m.CALENDAR_ID = f.calendar_id
WHERE f.out_of_service_mileage IS NULL

SET @upd =@upd+ @@ROWCOUNT


UPDATE f
SET f.pm_actual_mileage = m.meter_value
FROM eam.eq_mile_daily_fct f
INNER JOIN (
		SELECT e.eq_key , c.CALENDAR_ID, c.CALENDAR_DATE ,m.meter_value 
		FROM  eam.equipment_main e
		INNER JOIN reporting.tm.DW_CALENDAR c
			ON c.CALENDAR_DATE BETWEEN  e.begin_Date AND e.end_date
		LEFT JOIN (SELECT eq_equip_no,MAX(meter_value) AS meter_value,the_date 
					FROM eam.EAM_ALL_MILE_ACTIVITY 
					WHERE label_name = 'TSK_MAIN;METER_1_LIFE_TOTAL;DATE_PM_ACTUAL'
					--AND eq_equip_no = '25101'
					GROUP BY eq_equip_no, the_date
					) m
			ON m.eq_equip_no = e.eq_equip_no
			AND m.the_date = c.CALENDAR_DATE
			WHERE m.meter_value IS NOT NULL) m
ON m.eq_key = f.eq_key
AND m.CALENDAR_ID = f.calendar_id
WHERE f.pm_actual_mileage IS NULL

SET @upd =@upd+ @@ROWCOUNT


INSERT process.mergeLogs
(		[MergeCode]
        ,[ObjectDestination]
        ,[ObjectSource]
        ,[ObjectProgram]
        ,[recInsert]
        ,[recUpdate]
        ,[recDelete]
        ,[MergeBeginDatetime]
        ,[MergeEndDatetime])
SELECT  'EAM_daily_FCT' 
		,'ltd_dw.eam.eq_mile_daily_fct' 
		,'ltd_dw.eam.equipment_main'
		,@SPROC  
		,ISNULL(@ins,0) 
		,ISNULL(@upd,0)
		,0
		,@sdt
		,SYSDATETIME()

		
END TRY	  

BEGIN CATCH

       DECLARE @profile VARCHAR(255) = (
                    SELECT TOP 1 NAME
                    FROM msdb.dbo.sysmail_profile
                    )
       DECLARE @errormsg VARCHAR(MAX)
             ,@error INT
             ,@message VARCHAR(MAX)
             ,@xstate INT
             ,@errsev INT
             ,@sub VARCHAR(255);

       SELECT @error = ERROR_NUMBER()
             ,@errsev = ERROR_SEVERITY()
             ,@message = ERROR_MESSAGE()
             ,@xstate = XACT_STATE();

       SELECT @errormsg = 'Error in ' + ISNULL(@SPROC, '') + ':'  + CAST(ISNULL(@error, '') AS NVARCHAR(32)) + '|' + COALESCE(@message, '') + '|' + CAST(ISNULL(@xstate, '') AS NVARCHAR(32)) + '|' +CAST(ISNULL(@errsev, '') AS NVARCHAR(32))

       SELECT @sub = 'ERROR: ' + @SPROC

       EXEC msdb.dbo.sp_send_dbmail @profile_name = @profile
             ,@recipients = 'data@ltd.org' 
             ,@subject = @sub
             ,@body = @errormsg;

       RAISERROR (
                    @errormsg
                    ,@errsev
                    ,1
                    )
END CATCH
GO
