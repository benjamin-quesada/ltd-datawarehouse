SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE   PROCEDURE [eam].[Vehicle] as

--grant select on wrk.equipfuel to rpt_reader
--grant delete on wrk.equipfuel to rpt_reader
--grant insert on wrk.equipfuel to rpt_reader
--GRANT ALTER ON wrk.equipfuel TO rpt_reader;
--grant execute on [eam].[Vehicle] to rpt_reader

/* ------------------LTD_GLOSSARY---------------
UPDATED BY:	Sopheap Suy
UPDATED DT:  10/31/2024
purpose	 :  Add object activities on who, what, when call this object
			write this data to aud.object_activity table everytime it's called */

SET NOCOUNT ON

INSERT INTO DBA.[aud].[Object_Activity]
	([server_name], [database_name] ,[host_name], [System_User], [object_name]
	,[client_net_address], [local_net_address], [auth_Scheme], [last_read], [last_write]
	,[most_recent_sql_handle], [Timestamp], object_type)
SELECT DISTINCT @@SERVERNAME, DB_NAME(),HOST_NAME(),SYSTEM_USER, 'eam.Vehicle',
	client_net_address, local_net_address , auth_Scheme, last_read, last_write 
	,most_recent_sql_handle, CURRENT_TIMESTAMP AS [Timestamp], 'PROC'
FROM sys.dm_exec_connections 
WHERE session_id = @@SPID ;

SELECT m.[EQ_equip_no]
,c.ltd_bus_class
,c.life_miles
,c.bio_diesel
,c.atric as artic
,c.emx_bus
,c.hybrid
,c.electric
,[year]
,datediff(day,in_service_date,getdate()) UnitAgeDays
,[manufacturer]
,[model]
,[serial_no]
,m.[description]
,[meter_1_type]
,[meter_2_type]
,[radio_no]
,[asset_no]
,[cost_center]
,[billing_code]
,[ACCT_acct_code]
,[approval_level]
,[original_cost]
,[est_replace_cost]
,[est_replace_yr]
,[est_replace_mo]
,[replace_code]
,[date_added]
,[delivery_date]
,[in_service_date]
,[meter_1_at_delivery]
,[meter_2_at_delivery]
,[meter_1_prev_total]
,[meter_2_prev_total]
,[own_lease_customer]
,[monthly_rent]
,[lease_expiration_dt]
,[fixed_monthly_cost]
,[retire_date]
,[sale_date]
,[disposal_method]
,[buy_back]
,[oil_type]
,[tire_type]
,[months_in_operation]
,[last_meter_1_reading]
,[last_meter_2_reading]
,[last_meter_1_date]
,[last_meter_2_date]
,[last_meter_source]
,[fixed_insurance_cost]
,[fixed_replace_cost]
,[fixed_licensing_cost]
,f.fuel_type
,i.[description] fuel_desc
,[shipping_cost]
,[duty_cost]
,prs.unit_is_active
,prs.category_desc
,is_asset
,[asset_type]
	into #vehicle_setup
  FROM [LTD-EAM].proto.[emsdba].[EQ_MAIN] m
  inner join  [LTD-EAM].proto.emsdba.EQ_FUELTYPE f on f.[EQ_equip_no] = m.[EQ_equip_no]
  inner join  [LTD-EAM].proto.emsdba.FUE_TYPES i on i.fuel_type = f.fuel_type
  inner join  [LTD-EAM].proto.emsdba.prs_main prs on prs.procst_proc_status = m.procst_proc_status
  inner join  (select * from 
	[LTD-EAM].ltd_db.dbo.bus_classes where ltd_bus_class <> 'unknown') c on c.[EQ_equip_no] = m.[EQ_equip_no]



IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[wrk].[equipfuel]') AND type in (N'U'))
TRUNCATE TABLE wrk.equipfuel

insert wrk.equipfuel
select distinct
[EQ_equip_no]
 ,fuel_type
 ,fuel_desc
  from #vehicle_setup 


select [EQ_equip_no]
, [eam].[fnConcatenateFuelType](EQ_equip_no)  fuel_type
, [eam].[fnConcatenateFuelDesc](EQ_equip_no)  fuel_desc
into #veh_fueled
from #vehicle_setup
where isnumeric(eq_equip_no) = 1
		

select f.*, s.* from #veh_fueled f
left join ( 
select distinct [EQ_equip_no]
,ltd_bus_class
,life_miles
,bio_diesel
,artic
,emx_bus
,hybrid
,electric
,[year]
,UnitAgeDays
,[manufacturer]
,[model]
,[serial_no]
,[description]
,[meter_1_type]
,[meter_2_type]
,[radio_no]
,[asset_no]
,[cost_center]
,[billing_code]
,[ACCT_acct_code]
,[approval_level]
,[original_cost]
,[est_replace_cost]
,[est_replace_yr]
,[est_replace_mo]
,[replace_code]
,[date_added]
,[delivery_date]
,[in_service_date]
,[meter_1_at_delivery]
,[meter_2_at_delivery]
,[meter_1_prev_total]
,[meter_2_prev_total]
,[own_lease_customer]
,[monthly_rent]
,[lease_expiration_dt]
,[fixed_monthly_cost]
,[retire_date]
,[sale_date]
,[disposal_method]
,[buy_back]
,[oil_type]
,[tire_type]
,[months_in_operation]
,[last_meter_1_reading]
,[last_meter_2_reading]
,[last_meter_1_date]
,[last_meter_2_date]
,[last_meter_source]
,[fixed_insurance_cost]
,[fixed_replace_cost]
,[fixed_licensing_cost]
,[shipping_cost]
,[duty_cost]
,unit_is_active
,category_desc
,is_asset
,[asset_type] -- select * 
	  from #vehicle_setup i ) s
on s.[EQ_equip_no] = f.[EQ_equip_no] 
GO
GRANT EXECUTE ON  [eam].[Vehicle] TO [public]
GO
