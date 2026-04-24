SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   PROCEDURE [rpt].[get_pullout_pullin_blocks_with_soc]
-- grant execute on rpt.get_pullout_pullin_blocks_with_soc to public
-- exec rpt.get_pullout_pullin_blocks_with_soc
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


DECLARE @startDateInt CHAR(32) = '120210601'
declare @currdtIntFrom bigint
declare @currdtIntTo bigint

SELECT @currdtIntTo   = CAST(CONCAT('1',(CONCAT( CONVERT(VARCHAR(32),GETDATE(),112), '999999'))) AS BIGINT)


DROP TABLE IF EXISTS #socVals
SELECT license_number,socCalKey = 100000000 + CAST(CONVERT(VARCHAR(32), CAST(last_input_time AS DATETIME), 112) AS INT)
	   ,SOCDatetimekey = CAST(CAST(100000000 + CAST(CONVERT(VARCHAR(32), CAST(last_input_time AS DATETIME), 112) AS INT) AS VARCHAR(32)) + RIGHT('000000' + CAST([dbo].[F_DATE_TO_SEC_SINCE_MIDNITE](last_input_time) AS VARCHAR(32)), 6) AS BIGINT)
	   ,last_input_value AS SOC
INTO #socVals
FROM dbo.newflyer_vehicleParameters WHERE parameter_type = 40340 
AND 100000000 + CAST(CONVERT(VARCHAR(32), CAST(last_input_time AS DATETIME), 112) AS INT) >= @startDateInt
AND 100000000 + CAST(CONVERT(VARCHAR(32), CAST(last_input_time AS DATETIME), 112) AS INT) < @currdtIntTo
--GROUP BY 
--license_number,100000000 + CAST(CONVERT(VARCHAR(32), CAST(last_input_time AS DATETIME), 112) AS INT)
--	   ,CAST(CAST(100000000 + CAST(CONVERT(VARCHAR(32), CAST(last_input_time AS DATETIME), 112) AS INT) AS VARCHAR(32)) + RIGHT('000000' + CAST([dbo].[F_DATE_TO_SEC_SINCE_MIDNITE](last_input_time) AS VARCHAR(32)), 6) AS BIGINT)
--	   ,last_input_value

DROP TABLE IF EXISTS #pullinfo
SELECT CAST(CALENDAR_ID AS BIGINT) CALENDAR_ID
,b.BLOCK_ID
,b.BLOCK_ABBR
,SCHEDULED_PULLIN_VEHICLE_ID
,ACTUAL_PULLOUT_VEHICLE_ID
,v.PROPERTY_TAG AS license_number
,SCHEDULED_PULLOUT_TIME
,SCHEDULED_PULLIN_TIME
,ACTUAL_PULLOUT_TIME
,ACTUAL_PULLIN_TIME
,CAST(CAST(CALENDAR_ID AS VARCHAR(32)) + RIGHT('000000' + CAST(p.SCHEDULED_PULLOUT_TIME AS VARCHAR(32)), 6) AS BIGINT) cal_sched_pullout_key
,CAST(CAST(CALENDAR_ID AS VARCHAR(32)) + RIGHT('000000' + CAST(p.ACTUAL_PULLOUT_TIME AS VARCHAR(32)), 6) AS BIGINT) cal_act_pullout_key
,CAST(CAST(CALENDAR_ID AS VARCHAR(32)) + RIGHT('000000' + CAST(p.SCHEDULED_PULLIN_TIME AS VARCHAR(32)), 6) AS BIGINT) cal_sched_pullin_key
,CAST(CAST(CALENDAR_ID AS VARCHAR(32)) + RIGHT('000000' + CAST(p.ACTUAL_PULLIN_TIME AS VARCHAR(32)), 6) AS BIGINT) cal_act_pullin_key
,OVERLOAD_NUM
,PULLOUT_OPERATOR_ID
,PULLIN_OPERATOR_ID
INTO #pullinfo 
FROM [LTD-TMDATA].tmdatamart.[dbo].[VEHICLE_PULLOUT_PULLIN] p
INNER JOIN [LTD-TMDATA].tmdatamart.dbo.VEHICLE v ON v.VEHICLE_ID = COALESCE(p.ACTUAL_PULLOUT_VEHICLE_ID,p.ACTUAL_PULLIN_VEHICLE_ID,p.SCHEDULED_PULLOUT_VEHICLE_ID, p.SCHEDULED_PULLIN_VEHICLE_ID)
INNER JOIN [LTD-TMDATA].tmdatamart.dbo.BLOCK b ON b.BLOCK_ID = p.BLOCK_ID
WHERE CANCELLED_FLAG = 0 AND v.PROPERTY_TAG LIKE '202[0-9][0-9]'
AND calendar_id >= @startDateInt
AND p.CALENDAR_ID < @currdtIntTo



DROP TABLE IF EXISTS #maxSOC
SELECT 
l.license_number,
l.socCalKey,
p.CALENDAR_ID,
p.BLOCK_ID,
p.BLOCK_ABBR,
p.SCHEDULED_PULLIN_VEHICLE_ID,
p.ACTUAL_PULLOUT_VEHICLE_ID,
p.SCHEDULED_PULLOUT_TIME,
p.SCHEDULED_PULLIN_TIME,
p.ACTUAL_PULLOUT_TIME,
p.ACTUAL_PULLIN_TIME,
p.cal_sched_pullout_key,
p.cal_act_pullout_key,
p.cal_sched_pullin_key,
p.cal_act_pullin_key,
p.OVERLOAD_NUM,
p.PULLOUT_OPERATOR_ID,
p.PULLIN_OPERATOR_ID,
MIN(l.SOCDatetimekey) minDateKey,
MAX(l.SOC) maxSOC
INTO -- select * from 
#maxsoc
FROM #socVals l
JOIN #pullinfo p ON p.license_number = l.license_number 
		AND p.CALENDAR_ID = l.socCalKey
		AND (l.SOCDatetimekey BETWEEN p.cal_sched_pullout_key AND p.cal_sched_pullin_key
			OR 
			l.SOCDatetimekey BETWEEN p.cal_act_pullout_key AND p.cal_act_pullin_key)
GROUP by 
l.license_number,
l.socCalKey,
p.CALENDAR_ID,
p.BLOCK_ID,
p.BLOCK_ABBR,
p.SCHEDULED_PULLIN_VEHICLE_ID,
p.ACTUAL_PULLOUT_VEHICLE_ID,
p.license_number,
p.SCHEDULED_PULLOUT_TIME,
p.SCHEDULED_PULLIN_TIME,
p.ACTUAL_PULLOUT_TIME,
p.ACTUAL_PULLIN_TIME,
p.cal_sched_pullout_key,
p.cal_act_pullout_key,
p.cal_sched_pullin_key,
p.cal_act_pullin_key,
p.OVERLOAD_NUM,
p.PULLOUT_OPERATOR_ID,
p.PULLIN_OPERATOR_ID




DROP TABLE IF EXISTS #minSOC
SELECT 
l.license_number,
l.socCalKey,
p.CALENDAR_ID,
p.BLOCK_ID,
p.BLOCK_ABBR,
p.SCHEDULED_PULLIN_VEHICLE_ID,
p.ACTUAL_PULLOUT_VEHICLE_ID,
p.SCHEDULED_PULLOUT_TIME,
p.SCHEDULED_PULLIN_TIME,
p.ACTUAL_PULLOUT_TIME,
p.ACTUAL_PULLIN_TIME,
p.cal_sched_pullout_key,
p.cal_act_pullout_key,
p.cal_sched_pullin_key,
p.cal_act_pullin_key,
p.OVERLOAD_NUM,
p.PULLOUT_OPERATOR_ID,
p.PULLIN_OPERATOR_ID,
max(l.SOCDatetimekey) maxDateKey,
min(l.SOC) minSOC
INTO #minSOC
FROM #socVals l
JOIN #pullinfo p ON p.license_number = l.license_number 
		AND p.CALENDAR_ID = l.socCalKey
		AND (l.SOCDatetimekey BETWEEN p.cal_sched_pullout_key AND p.cal_sched_pullin_key
			OR 
			l.SOCDatetimekey BETWEEN p.cal_act_pullout_key AND p.cal_act_pullin_key)
GROUP by 
l.license_number,
l.socCalKey,
p.CALENDAR_ID,
p.BLOCK_ID,
p.BLOCK_ABBR,
p.SCHEDULED_PULLIN_VEHICLE_ID,
p.ACTUAL_PULLOUT_VEHICLE_ID,
p.license_number,
p.SCHEDULED_PULLOUT_TIME,
p.SCHEDULED_PULLIN_TIME,
p.ACTUAL_PULLOUT_TIME,
p.ACTUAL_PULLIN_TIME,
p.cal_sched_pullout_key,
p.cal_act_pullout_key,
p.cal_sched_pullin_key,
p.cal_act_pullin_key,
p.OVERLOAD_NUM,
p.PULLOUT_OPERATOR_ID,
p.PULLIN_OPERATOR_ID
HAVING min(l.SOC) > 0



SELECT q.license_number AS the_bus,
       q.socCalKey calendar_id,
       q.block_id,
       q.block_abbr [block],
       q.OperatorID,
       o.LAST_NAME + ', ' + UPPER(LEFT(o.FIRST_NAME, 1)) AS Operator,
       q.SCHEDULED_PULLOUT_TIME,
       q.ACTUAL_PULLOUT_TIME,
       q.SCHEDULED_PULLIN_TIME,
       q.ACTUAL_PULLIN_TIME,
       q.SCHEDULED_PULLOUT_HHMMSS,
       q.ACTUAL_PULLOUT_HHMMSS,
       q.SCHEDULED_PULLIN_HHMMSS,
       q.ACTUAL_PULLIN_HHMMSS,
       MAX(q.maxSOC) maxSOC,
       MIN(q.minSOC) minSOC
FROM
(
    SELECT COALESCE(ms.license_number, ns.license_number) license_number,
           v.socCalKey
           ,COALESCE(ms.BLOCK_ID
		   , ns.BLOCK_ID) block_id
           ,COALESCE(ms.BLOCK_ABBR
		   , ns.BLOCK_ABBR) block_abbr
           ,COALESCE(ms.PULLOUT_OPERATOR_ID
		   , ms.PULLOUT_OPERATOR_ID
		   , ns.PULLOUT_OPERATOR_ID
		   , ns.PULLIN_OPERATOR_ID) OperatorID,
           COALESCE(ms.SCHEDULED_PULLOUT_TIME,  ns.SCHEDULED_PULLOUT_TIME) SCHEDULED_PULLOUT_TIME,
           COALESCE(ms.ACTUAL_PULLOUT_TIME, ns.ACTUAL_PULLOUT_TIME) ACTUAL_PULLOUT_TIME,
           COALESCE(ms.SCHEDULED_PULLIN_TIME, ns.SCHEDULED_PULLIN_TIME) SCHEDULED_PULLIN_TIME,
           COALESCE(ms.ACTUAL_PULLIN_TIME, ns.ACTUAL_PULLIN_TIME) ACTUAL_PULLIN_TIME,
		   [dbo].[F_getHHMMSS_from_SPM](COALESCE(ms.SCHEDULED_PULLOUT_TIME,  ns.SCHEDULED_PULLOUT_TIME)) SCHEDULED_PULLOUT_HHMMSS,
           [dbo].[F_getHHMMSS_from_SPM](COALESCE(ms.ACTUAL_PULLOUT_TIME, ns.ACTUAL_PULLOUT_TIME)) ACTUAL_PULLOUT_HHMMSS,
           [dbo].[F_getHHMMSS_from_SPM](COALESCE(ms.SCHEDULED_PULLIN_TIME, ns.SCHEDULED_PULLIN_TIME)) SCHEDULED_PULLIN_HHMMSS,
           [dbo].[F_getHHMMSS_from_SPM](COALESCE(ms.ACTUAL_PULLIN_TIME, ns.ACTUAL_PULLIN_TIME)) ACTUAL_PULLIN_HHMMSS,
           maxSOC = MAX(ms.maxSOC),
           minSOC = MIN(ns.minSOC)
    FROM #socVals v
        LEFT JOIN #maxsoc ms
            ON ms.license_number = v.license_number
               AND ms.CALENDAR_ID = v.socCalKey
        LEFT JOIN #minSOC ns
            ON ns.license_number = v.license_number
               AND ns.CALENDAR_ID = v.socCalKey
    WHERE (
              ms.license_number IS NOT NULL
              AND ns.license_number IS NOT NULL
          )
    GROUP BY COALESCE(ms.license_number, ns.license_number),
             v.socCalKey,
             COALESCE(ms.BLOCK_ID, ns.BLOCK_ID),
             COALESCE(ms.BLOCK_ABBR, ns.BLOCK_ABBR),
             COALESCE(ms.PULLOUT_OPERATOR_ID, ms.PULLOUT_OPERATOR_ID, ns.PULLOUT_OPERATOR_ID, ns.PULLIN_OPERATOR_ID),
             COALESCE(ms.PULLOUT_OPERATOR_ID, ms.PULLOUT_OPERATOR_ID, ns.PULLOUT_OPERATOR_ID, ns.PULLIN_OPERATOR_ID),
             ms.SCHEDULED_PULLOUT_TIME,
             ms.ACTUAL_PULLOUT_TIME,
             ms.SCHEDULED_PULLIN_TIME,
             ms.ACTUAL_PULLIN_TIME,
             ns.SCHEDULED_PULLOUT_TIME,
             ns.ACTUAL_PULLOUT_TIME,
             ns.SCHEDULED_PULLIN_TIME,
             ns.ACTUAL_PULLIN_TIME
) q
    LEFT JOIN [LTD-TMDATA].tmdatamart.[dbo].OPERATOR o
        ON o.OPERATOR_ID = q.OperatorID
group BY 
 q.license_number ,
       q.socCalKey,
       q.block_id,
       q.block_abbr,
       q.OperatorID,
       o.LAST_NAME + ', ' + UPPER(LEFT(o.FIRST_NAME, 1)) ,
       q.SCHEDULED_PULLOUT_TIME,
       q.ACTUAL_PULLOUT_TIME,
       q.SCHEDULED_PULLIN_TIME,
       q.ACTUAL_PULLIN_TIME,
       q.SCHEDULED_PULLOUT_HHMMSS,
       q.ACTUAL_PULLOUT_HHMMSS,
       q.SCHEDULED_PULLIN_HHMMSS,
       q.ACTUAL_PULLIN_HHMMSS;

GO
GRANT EXECUTE ON  [rpt].[get_pullout_pullin_blocks_with_soc] TO [public]
GO
