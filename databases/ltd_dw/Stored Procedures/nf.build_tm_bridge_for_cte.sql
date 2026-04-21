SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   PROCEDURE [nf].[build_tm_bridge_for_cte]
@calendar_input INT
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


WITH sched AS (
SELECT s.CALENDAR_ID,
	   v.PROPERTY_TAG,
       s.TIME_TABLE_VERSION_ID,
       s.BLOCK_ID,
       s.TRIP_ID,
	   MIN(s.SCHEDULED_TIME) SCHED_START,
	   MAX(s.SCHEDULED_TIME) SCHED_END,
	   t.TRIP_END_TIME,
	   s.ROUTE_ID,
       s.ROUTE_DIRECTION_ID,
       s.OPERATOR_ID,
       s.RUN_ID,
       s.WORK_PIECE_ID,
       s.VEHICLE_ID
FROM [ltd-tmdata].tmdatamart.[dbo].[SCHEDULE] s
JOIN [ltd-tmdata].tmdatamart.[dbo].[TRIP] t ON t.TRIP_ID = s.TRIP_ID
JOIN [ltd-tmdata].tmdatamart.dbo.VEHICLE v ON v.VEHICLE_ID = s.VEHICLE_ID
WHERE s.CALENDAR_ID >= 120210400  
AND v.PROPERTY_TAG BETWEEN '20200' AND '20299'
GROUP BY 
       s.CALENDAR_ID,
	   v.PROPERTY_TAG,
       s.TIME_TABLE_VERSION_ID,
       s.BLOCK_ID,
       s.TRIP_ID,
	   t.TRIP_END_TIME,
	   s.ROUTE_ID,
       s.ROUTE_DIRECTION_ID,
       s.OPERATOR_ID,
       s.RUN_ID,
       s.WORK_PIECE_ID,
       s.VEHICLE_ID
	   )
SELECT Q.calId,
       Q.license_number,
       Q.vehicle_id,
       Q.[ROUTE],
       Q.ROUTE_DIRECTION,
       Q.OPERATOR_ID,
       Q.LAST_NAME,
       Q.FIRST_NAME,
       --Q.group_id,
       --Q.group_name,
       Q.[Date And Time],
       Q.NF_MSG_TIME,
       Q.SCHED_START,
       Q.SCHED_END,
       Q.[GPS LAT],
       Q.[GPS LON],
       Q.[Speed(Kph)],
       Q.[Mileage(Km)],
       Q.[NF TK_AmbTemp (40 ft)],
       Q.[NF XPAND BATT_Sys_Energy_System],
       Q.[VAN_DCDC_IIN_ST (SPN 65495)],
       Q.[VAN_DCDC_VIN_ST (SPN 65492)],
       Q.[NF XE_DICO_PWR_AX_MOT 1 (Auxiliary Motor Power Draw)],
       Q.[NF XPAND_SYS_SOC (PGN: 65349)],
       Q.[NF XE_DICO_BR_RWES_FB (Auxiliary Heater Power Draw)],
       Q.[NF CM0711_Electric_Heater_Energy_Consumption_kWh],
       Q.[NF CM0711_Trip_Motor_Energy_Consumption_kWh],
       Q.[NF CM0711_Trip_Regen_Energy_kWh]
       FROM (
SELECT c.calId,
       c.license_number,
       c.vehicle_id,
       s.OPERATOR_ID,
	   o.LAST_NAME,
	   o.FIRST_NAME,
       c.group_id,
       c.group_name,
       c.[Date And Time],
	   NF_MSG_TIME = [dbo].[F_DATE_TO_SEC_SINCE_MIDNITE]([Date And Time]) ,
	   s.SCHED_START,
	   s.SCHED_END,
       c.[GPS LAT],
       c.[GPS LON],
       c.[Speed(Kph)],
       c.[Mileage(Km)],
       c.[NF TK_AmbTemp (40 ft)],
       c.[NF XPAND BATT_Sys_Energy_System],
       c.[VAN_DCDC_IIN_ST (SPN 65495)],
       c.[VAN_DCDC_VIN_ST (SPN 65492)],
       c.[NF XE_DICO_PWR_AX_MOT 1 (Auxiliary Motor Power Draw)],
       c.[NF XPAND_SYS_SOC (PGN: 65349)],
       c.[NF XE_DICO_BR_RWES_FB (Auxiliary Heater Power Draw)],
       c.[NF CM0711_Electric_Heater_Energy_Consumption_kWh],
       c.[NF CM0711_Trip_Motor_Energy_Consumption_kWh],
       c.[NF CM0711_Trip_Regen_Energy_kWh],
       s.TIME_TABLE_VERSION_ID,
       s.BLOCK_ID,
       s.TRIP_ID,
       --s.TRIP_END_TIME,
	   r.ROUTE_ABBR AS [ROUTE],
	   ROUTE_DIRECTION = LEFT(UPPER(rd.ROUTE_DIRECTION_ABBR),1)
       --s.ROUTE_ID,
       --s.ROUTE_DIRECTION_ID
FROM nf.prepared_for_cte c
JOIN sched s ON s.PROPERTY_TAG = c.license_number
AND c.calId = s.CALENDAR_ID
AND [dbo].[F_DATE_TO_SEC_SINCE_MIDNITE]([Date And Time]) BETWEEN s.SCHED_START AND s.SCHED_END
JOIN [ltd-tmdata].tmdatamart.dbo.OPERATOR o ON o.OPERATOR_ID = s.OPERATOR_ID
JOIN [ltd-tmdata].tmdatamart.dbo.[ROUTE] r ON r.ROUTE_ID = s.ROUTE_ID
JOIN [ltd-tmdata].tmdatamart.dbo.ROUTE_DIRECTION rd ON rd.ROUTE_DIRECTION_ID = s.ROUTE_DIRECTION_ID
WHERE c.license_number = 20210
--AND c.[GPS LAT] IS NOT NULL	
--AND c.[GPS LON] IS NOT NULL	
) Q 
GROUP BY 
Q.calId,
       Q.license_number,
       Q.vehicle_id,
       Q.OPERATOR_ID,
       Q.LAST_NAME,
       Q.FIRST_NAME,
       --Q.group_id,
       --Q.group_name,
       Q.[Date And Time],
       Q.NF_MSG_TIME,
       Q.SCHED_START,
       Q.SCHED_END,
       Q.[GPS LAT],
       Q.[GPS LON],
       Q.[Speed(Kph)],
       Q.[Mileage(Km)],
       Q.[NF TK_AmbTemp (40 ft)],
       Q.[NF XPAND BATT_Sys_Energy_System],
       Q.[VAN_DCDC_IIN_ST (SPN 65495)],
       Q.[VAN_DCDC_VIN_ST (SPN 65492)],
       Q.[NF XE_DICO_PWR_AX_MOT 1 (Auxiliary Motor Power Draw)],
       Q.[NF XPAND_SYS_SOC (PGN: 65349)],
       Q.[NF XE_DICO_BR_RWES_FB (Auxiliary Heater Power Draw)],
       Q.[NF CM0711_Electric_Heater_Energy_Consumption_kWh],
       Q.[NF CM0711_Trip_Motor_Energy_Consumption_kWh],
       Q.[NF CM0711_Trip_Regen_Energy_kWh],
       Q.TIME_TABLE_VERSION_ID,       
       Q.[ROUTE],
       Q.ROUTE_DIRECTION
ORDER BY license_number,[Date And Time]
GO
