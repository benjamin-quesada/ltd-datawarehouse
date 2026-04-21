SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [rpt].[NewFlyer_AllParameters]
as
 -- grant execute on rpt.NewFlyer_AllParameters to rpt_reader
 -- exec  rpt.NewFlyer_AllParameters 

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

;

with tag as (
	select vehicle_id,cast( property_tag as INT) property_tag from [ltd-tmdata].tmdatamart.dbo.vehicle  WITH(NOLOCK) where property_tag in (
'20101',
'20102',
'20103',
'20104',
'20105',
'20201',
'20202',
'20203',
'20204',
'20205',
'20206',
'20207',
'20208',
'20209',
'20210',
'20211') 
)
, pc as (
select c.calendar_id, tm.convert_spm_to_hh_mm_ss(c.message_time) msgtime, cast(c.calendar_id as varchar(32)) +  right('00000' + c.message_time,5) calspm, c.vehicle_id
,z.time_table_version_name
,c.trip_id, [tm].[convert_passing_time](t.trip_end_time) trip_end_time
,block_abbr
, r.route_abbr, d.route_direction_name
,g.geo_node_abbr
, g.geo_node_name
, o.badge, o.onboard_logon_id, last_name + ', ' + first_name as operator_name
from [ltd-tmdata].tmdatamart.dbo.passenger_count c WITH(NOLOCK)
join [ltd-tmdata].tmdatamart.dbo.[route] r WITH(NOLOCK) on r.route_id = c.route_id
join[ltd-tmdata].tmdatamart.dbo.route_direction d WITH(NOLOCK) on d.route_direction_id = c.route_direction_id
join[ltd-tmdata].tmdatamart.dbo.geo_node g WITH(NOLOCK) on g.geo_node_id = c.geo_node_id
join [ltd-tmdata].tmdatamart.dbo.[block] b WITH(NOLOCK) on b.block_id = c.block_id
join [ltd-tmdata].tmdatamart.dbo.time_table_version z WITH(NOLOCK) on z.time_table_version_id = c.time_table_version_id
join [ltd-tmdata].tmdatamart.dbo.trip t WITH(NOLOCK) on t.trip_id = c.trip_id and t.time_table_version_id = c.time_table_version_id
join [ltd-tmdata].tmdatamart.dbo.operator o WITH(NOLOCK) on o.operator_id = c.operator_id
where 1=1
and c.calendar_id > 120201200
)

select pc.*, v.property_tag 
into -- select * from 
#vehicle_nf42
from pc 
join tag v on v.vehicle_id = pc.vehicle_id


SELECT 
license_nmbr, cal_id, calspm,nf_time,
isnull([52],0) as [J1939 Wheel-based Vehicle Speed (84)],        
isnull([58],0) as [J1939 Engine Speed (rpm) (190)],        
isnull([138],0) as [GPS Speed],           
isnull([280],0) as [GPS LAT],           
isnull([281],0) as [GPS LON],           
isnull([284],0) as [J1939 DTC Raw],          
isnull([285],0) as [J1939 DTC],           
isnull([527],0) as [Traffilog Unit DTC],          
isnull([630],0) as [Calc Vehicle Distance From Sys Speed],       
isnull([778],0) as [CAN 0 Error Count],         
isnull([779],0) as [CAN 1 Error Count],         
isnull([3196],0) as [NF_MRS_OFF (F2-32)],           
isnull([3838],0) as [NF IGN_BS_BAR_EXTND_TMR (C14-19)],          
isnull([4016],0) as [MBU-V2 MTST Battery Voltage],         
isnull([8470],0) as [NF Scheme Output 8470-MRS On for at least 2 minutes],   
isnull([8520],0) as [NF Scheme Output 8520-EBus Charging],        
isnull([8705],0) as [NF Scheme Output 8705-NF_Ignition Has Been On for at Least 90 Seconds], 
isnull([9075],0) as [NF Scheme Output 9075],         
isnull([9390],0) as [NF Scheme Output 9390-Interval for Session Logging for Broadcasting Parameters],   
isnull([10000],0) as [Sys Param Ignition],          
isnull([10001],0) as [Sys Param Ignition No Delay],        
isnull([10002],0) as [Sys Param Battery Voltage],         
isnull([10003],0) as [Sys Param Speed],          
isnull([10004],0) as [Sys Param Vehicle Distance],         
isnull([10007],0) as [Sys Param Fuel Level],         
isnull([12555],0) as [NF DY_NGHT_SEL_SW (I2-3)],          
isnull([13068],0) as [NF TK_HVACOperModeStatus],           
isnull([13068],0) as [NF Req-TK_HVACOperModeStatus],           
isnull([13071],0) as [NF TK_IntTempSetPtStatusCelsius_RR],           
isnull([13073],0) as [NF TK_AmbTemp (40 ft)],         
isnull([13074],0) as [NF TK_ReturnAirTemp_Main (RR)],          
isnull([15227],0) as [NF RR_AIR_PRS_PSI (F9-129)],          
isnull([16119],0) as [NF FRT_AIR_PRS_PSI (F9-128)],          
isnull([18398],0) as [Calc Outputs Front Door Open (18398)],       
isnull([18402],0) as [Calc Count Front Door Open (18398)],       
isnull([18403],0) as [Calc Outputs Rear Door Open (18403)],       
isnull([18407],0) as [Calc Count Rear Door Open (18403)],       
isnull([18408],0) as [Calc Outputs Wheelchair Ramp Deployed (18408)],       
isnull([18412],0) as [Calc Count Wheelchair Ramp Deployed (18408)],       
isnull([20971],0) as [NF RR_DR_OPN_LS (I11-6)],          
isnull([20972],0) as [NF FRT_DR_OPN_LS (I11-7)],          
isnull([22224],0) as [NF ABS_VEHICLE_SPD (M9-16)],          
isnull([28628],0) as [NF ALT_FLT_IND (T1-9)],          
isnull([29310],0) as [NF HV_INTER_LOCK_IND (T6-19)],          
isnull([29376],0) as [NF DICO_EV_MODE_ST (F13-5)],          
isnull([29383],0) as [NF STOP_SYS_FLAG (F13-12)],          
isnull([29429],0) as [NF DICO_CHK_SYS_ST(M13-10)],           
isnull([29601],0) as [NF HV_READY (F15-19)],          
isnull([30275],0) as [BMU_SOC_MSG_CM (PGN: 65439)],          
isnull([30893],0) as [NF ESS_SOC_FLAG (F15-142)],          
isnull([31463],0) as [VAN_DCDC_IIN_ST (SPN 65495)],          
isnull([31464],0) as [VAN_DCDC_VIN_ST (SPN 65492)],          
isnull([31465],0) as [NF XE_DICO_PWR_AX_MOT 1 (Auxiliary Motor Power Draw)],      
isnull([33731],0) as [NF_VMM_Program_P-N],            
isnull([33732],0) as [NF_VMM_Program_Revision],            
isnull([39056],0) as [NF XPAND BATT_Cnc_Temp_Module_Max],          
isnull([39057],0) as [NF XPAND BATT_Cnc_Temp_Module_Max_StrId],          
isnull([39058],0) as [NF XPAND BATT_Cnc_Temp_Module_Max_SubId],          
isnull([39070],0) as [NF XPAND BATT_Cnc_Energy_System],          
isnull([39188],0) as [NF XPAND BATT_Contactor_StringsConnected (65344)],         
isnull([39197],0) as [NF XPAND BATT_Current_System],          
isnull([39209],0) as [NF XPAND BATT_Sys_Volt_Cell_Max_VtbId],          
isnull([39211],0) as [NF XPAND BATT_Sys_Volt_Cell_Max_StrId],          
isnull([39212],0) as [NF XPAND BATT_Sys_Volt_Cell_Max_CellId],          
isnull([39213],0) as [NF XPAND BATT_Sys_Volt_Cell_Max],          
isnull([39223],0) as [NF XPAND BATT_Sys_Energy_System],          
isnull([39230],0) as [NF XPAND BATT_Sys_Temp_Module_Avg],          
isnull([39231],0) as [NF XPAND BATT_Sys_Temp_Module_Max],          
isnull([39232],0) as [NF XPAND BATT_Sys_Temp_Module_Max_StrId],          
isnull([39233],0) as [NF XPAND BATT_Sys_Temp_Module_Max_SubId],          
isnull([39234],0) as [NF XPAND BATT_Sys_Temp_Module_Min],          
isnull([39240],0) as [NF XPAND BATT_Sys_Temp_Module_Min_StrId],          
isnull([39241],0) as [NF XPAND BATT_Limit_DschrgCrrnt],          
isnull([39590],0) as [NF TK_BATT_COOL_SIG (M2-4)],          
isnull([39672],0) as [NF I-O_CONTROLLER STATE - PLUGIN_CHRG_STATE (F4-142)],       
isnull([40093],0) as [NF ESS_MIN_CELL_TEMP (F13-131)],          
isnull([40128],0) as [NF BATT_CLNT_PMP_SPD (M13-19)],          
isnull([40311],0) as [NF ESS_MAX_CELL_TEMP (F15-151)],          
isnull([40340],0) as [NF XPAND_SYS_SOC (PGN: 65350)],         
isnull([40341],0) as [NF XPAND_CNCTD_SOC (PGN: 65349)],         
isnull([41105],0) as [NF EV_WKUP_FLG (F4-8)],          
isnull([41401],0) as [NF DICO3_BUS_VOLT_FLAG (F11-131)],          
isnull([41720],0) as [NF ELEC_HTR_2_CNTOR_ST (I15-6)],          
isnull([41738],0) as [NF CM_BMU_MAIN_CONT_FB (M15-17)],          
isnull([43705],0) as [NF XPAND BATT_Sys_SOHC_Module_Avg],          
isnull([43707],0) as [NF XPAND BATT_Sys_SOHC_Module_Max],          
isnull([43708],0) as [NF XPAND BATT_Sys_SOHC_Module_Max_StrId],          
isnull([43711],0) as [NF XPAND BATT_Sys_SOHC_Module_Min],          
isnull([43712],0) as [NF XPAND BATT_Sys_SOHC_Module_Min_StrId],          
isnull([43715],0) as [NF XPAND BATT_Sys_SOHR_Module_Avg],          
isnull([43717],0) as [NF XPAND BATT_Sys_SOHR_Module_Max],          
isnull([43718],0) as [NF XPAND BATT_Sys_SOHR_Module_Max_StrId],          
isnull([43721],0) as [NF XPAND BATT_Sys_SOHR_Module_Min],          
isnull([43722],0) as [NF XPAND BATT_Sys_SOHR_Module_Min_StrId],          
isnull([43730],0) as [NF XPAND MCU_Version_SwMajCW m100],         
isnull([43731],0) as [NF XPAND MCU_Version_SwMajCY m100],         
isnull([43732],0) as [NF XPAND MCU_Version_SwMin m100],         
isnull([49472],0) as [NF XPAND BATT_Current_System (XE40 HG)],        
isnull([49821],0) as [NF CM0711_DCDC_Energy_Consumption_kWh],           
isnull([49822],0) as [NF CM0711_Aux_Inverter_Energy_Consumption_kWh],           
isnull([49823],0) as [NF CM0711_Electric_Heater_Energy_Consumption_kWh],           
isnull([49824],0) as [NF CM0711_XE_XALT_Charging_Energy_Transfer_kWh],           
isnull([49827],0) as [NF CM0711 Average Speed mi-h],        
isnull([49829],0) as [NF CM0711 Miles To Empty mi],       
isnull([49832],0) as [NF CM0711_VersionNumber],           
isnull([49833],0) as [NF CM0711_PartNumber],           
isnull([49834],0) as [NF CM0711 Energy Remaining in ESS kWh],      
isnull([49835],0) as [NF CM0711 Average Power kW],        
isnull([49837],0) as [NF CM0711 Time To Empty hr],       
isnull([49838],0) as [NF CM0711_Trip_Motor_Energy_Consumption_kWh],           
isnull([49839],0) as [NF CM0711_Trip_Regen_Energy_kWh],           
isnull([49840],0) as [NF CM0711 Instantaneous Power kW],        
isnull([49841],0) as [NF CM0711_XE_XALT_Net_Trip_Energy_kWh],           
isnull([50092],0) as [NF CM0711 Real Time Consumption rate kWh-mi],      
isnull([50093],0) as [NF CM0711 Average Consumption Rate TripkWh-mi],      
isnull([50094],0) as [NF CM0711 Trip Distance mi],        
isnull([50628],0) as [Depot_DIAG (F21-130)]           
into #newflyerDeets
FROM (
SELECT license_nmbr,parameter_type,cal_id =  cast(100000000+ cast(convert(varchar(32),cast(last_input_time as datetime), 112) as inT) as varchar(32)),
 cast(100000000+ cast(convert(varchar(32),cast(last_input_time as datetime), 112) as inT) as varchar(32))
+ right('00000'+cast((Left(right(last_input_time,8),2) * 3600 + substring(right(last_input_time,8), 4,2) * 60 + substring(right(last_input_time,8), 7,2)) as varchar(12)),5) calspm,
tm.convert_spm_to_hh_mm_ss(right('00000'+cast((Left(right(last_input_time,8),2) * 3600 + substring(right(last_input_time,8), 4,2) * 60 + substring(right(last_input_time,8), 7,2)) as varchar(12)),5) ) nf_time
--, Left(right(last_input_time,8),2) * 60 + substring(right(last_input_time,8), 4,2) mpm
--,[parameter_type_description]
,cast(last_input_value as decimal(22,8)) last_input_value
  FROM [ltd_dw].[dbo].[newflyer_vehicleParameters] r
  join (select distinct vehicle_id, license_nmbr from dbo.newflyer_vehicledata1) d on d.vehicle_id = r.vehicle_id
  where last_input_value <> 0
 ) o
 PIVOT
 (
	max(last_input_value) FOR
	[parameter_type] IN (
[52],
[58],
[138],
[280],
[281],
[284],
[285],
[527],
[630],
[778],
[779],
[3196],
[3838],
[4016],
[8470],
[8520],
[8705],
[9075],
[9390],
[10000],
[10001],
[10002],
[10003],
[10004],
[10007],
[12555],
[13068],
[13071],
[13073],
[13074],
[15227],
[16119],
[18398],
[18402],
[18403],
[18407],
[18408],
[18412],
[20971],
[20972],
[22224],
[28628],
[29310],
[29376],
[29383],
[29429],
[29601],
[30275],
[30893],
[31463],
[31464],
[31465],
[33731],
[33732],
[39056],
[39057],
[39058],
[39070],
[39188],
[39197],
[39209],
[39211],
[39212],
[39213],
[39223],
[39230],
[39231],
[39232],
[39233],
[39234],
[39240],
[39241],
[39590],
[39672],
[40093],
[40128],
[40311],
[40340],
[40341],
[41105],
[41401],
[41720],
[41738],
[43705],
[43707],
[43708],
[43711],
[43712],
[43715],
[43717],
[43718],
[43721],
[43722],
[43730],
[43731],
[43732],
[49472],
[49821],
[49822],
[49823],
[49824],
[49827],
[49829],
[49832],
[49833],
[49834],
[49835],
[49837],
[49838],
[49839],
[49840],
[49841],
[50092],
[50093],
[50094],
[50628])) as p


select i.*,d.*,
baylatfueling = case when abs(case when isnull([gps lat],0.000) <> 0 then 44.043225911110355 - [gps lat] end) <= .0009 then 1 else 0 end,
baylonfueling = case when abs(case when isnull([gps lon],0.000) <> 0 then -123.04134000009165 - [gps lon] end) <= .0009 then 1 else 0 end,
latdiffyard1 = case when abs(case when isnull([gps lat],0.000) <> 0 then 44.043487 - [gps lat]  end) <= 0009 then 1 else 0 end, 
londiffyard1 = case when abs(case when isnull([gps lon],0.000) <> 0 then -123.039318 - [gps lon]  end) <= 0009 then 1 else 0 end, 
latdiffyard2 = case when abs(case when isnull([gps lat],0.000) <> 0 then 44.043106 - [gps lat]  end) <= 0009 then 1 else 0 end, 
londiffyard2 = case when abs(case when isnull([gps lon],0.000) <> 0 then -44.043106 - [gps lon]  end) <= 0009 then 1 else 0 end
from #newflyerDeets d 
left join (
SELECT min(cast(calspm as bigint)) travelstart ,max(cast(calspm as bigint)) travelend, calendar_id,property_tag, block_abbr,  trip_id, trip_end_time
, route_abbr, route_direction_name
, badge, onboard_logon_id, operator_name
from #vehicle_nf42
--where property_tag = 20204
group by property_tag,block_abbr,  trip_id, trip_end_time,  route_abbr, route_direction_name ,calendar_id
, badge, onboard_logon_id, operator_name 
) i
 on cast(d.calspm as bigint) between i.travelstart and i.travelend
and i.property_tag = d.license_nmbr 
and cal_id = calendar_id
--where license_nmbr = 20204
--and property_tag = 20204	
--and calendar_id = 120210523
--and cal_id = 120210523
order by travelstart, cast(d.calspm as bigint)
GO
