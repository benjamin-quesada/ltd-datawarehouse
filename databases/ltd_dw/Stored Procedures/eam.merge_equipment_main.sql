SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE     PROCEDURE  [eam].[merge_equipment_main]
AS

/*-----------LTD_GLOSSARY---------------
CREATED BY:	Sopheap Suy
UPDATED DT: 08/12/2025 
purpose	:	pull data from eam.eq_main_stage to eam.equipment_main
use		:	exec eam.merge_equipment_main

purpose	 :  Add object activities on who, what, when call this object
			write this data to aud.object_activity table everytime it's called 

UPDATED DT: 09/03/2025 
UPDATED BY: Sopheap Suy
			add begin_date, AND end_date 
UPDATED DT: 10/02/2025 
UPDATED BY: Sopheap Suy
			add addition columns from eq_main

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

DECLARE @ETLProcessActivityID INT

SET @ETLProcessActivityID = (SELECT MIN(ETLProcessActivityID) 
							FROM ltd_dw.eam.eq_main_stage
							WHERE processed = 'N')
DECLARE @sdt DATETIME2 = SYSDATETIME()
--process a single ETLProcessActivityID data pull at a time


DROP TABLE IF EXISTS #eam_stg


SELECT s.eq_equip_no,
       s.PROCST_proc_status,
       ISNULL(s.EQCAT_equip_category,'') EQCAT_equip_category,
       s.LOC_assign_pm_loc,
       s.LOC_assign_repr_loc,
       ISNULL(s.LOC_stored_loc,'') LOC_stored_loc,
       s.DEPT_dept_code,
       ISNULL(s.CPY_company_code,'') CPY_company_code,
       s.CLASS_class_maint,
       s.CLASS_class_meter,
       s.CLASS_class_pm,
       s.CLASS_class_shop_sch,
       s.CLASS_class_rental,
       s.CLASS_class_stds,
       ISNULL(s.license_no,'') license_no,
       ISNULL(s.asset_no,'') asset_no,
       s.pm_prog_type,
       ISNULL(s.FLT_fleet_no,'') FLT_fleet_no,
       ISNULL(s.ACAT_category_no,'') ACAT_category_no,
       s.asset_type,
	   --'9999-12-31' equipment_status_date,
       s.X_datetime_update,
       s.X_datetime_insert,
	   --GETDATE(),
	   s.ETLProcessActivityID
	   , s.Processed
	   , is_updated =0
	   	, REPLACE(REPLACE(ISNULL(s.[EQTYP_equip_type],''),'`','ft'),'ý','') EQTYP_equip_type --equipment type
		, ISNULL(s.year,0) year --vehicle year
		, REPLACE(REPLACE(ISNULL(s.[manufacturer],''),'`','ft'),'ý','') manufacturer --vehicle manufacture
		, ISNULL(s.model,'') model --vehicle model
		, REPLACE(REPLACE(ISNULL(s.[description],''),'`','ft'),'ý','')  description --vehicle description
		, ISNULL(s.sla_status,'') sla_status --sla equipment category
		, ISNULL(s.work_order_status,'') work_order_status
		, ISNULL(s.fuel_card_no,0) fuel_card_no
		, ISNULL(s.months_in_operation,0) months_in_operation
		, ISNULL(s.deprec_months_life,0) deprec_months_life
		, ISNULL(s.depr_mths_remaining,0)  depr_mths_remaining
		, ISNULL(CASE WHEN s.description LIKE '%SEATING CAPACITY%'
			THEN CAST(LTRIM(RTRIM(SUBSTRING(s.description,PATINDEX('%SEATING CAPACITY%',s.description)+16,999))) AS INT)
			ELSE 0 END,0) scap
		, ISNULL(s.shop_status,'') shop_status
		,ISNULL(LOC_assgn_mobile_loc,'') LOC_assgn_mobile_loc
		,ISNULL(comment_area,'') comment_area
		,ISNULL(DEPT_temp_loaned_to,'') DEPT_temp_loaned_to
		,ISNULL(on_temp_loan,'') on_temp_loan 
		,ISNULL(in_service_date,'1900-01-01') in_service_date
		,ISNULL(inv_list_excl_switch,'') inv_list_excl_switch
		,ISNULL(last_meter_1_reading, 0) last_meter_1_reading
		,ISNULL(last_meter_2_reading, 0) last_meter_2_reading
		,ISNULL(LOC_station_loc,'') LOC_station_loc 
		,ISNULL(LOC_current_loc,'') LOC_current_loc 
		,ISNULL(meter_1_type,'' ) meter_1_type
		,ISNULL(meter_2_type,'') meter_2_type 
		,ISNULL(original_cost,0) original_cost
		,ISNULL(PRI_shop_priority,'') PRI_shop_priority
		,ISNULL(serial_no,'') serial_no 
		,ISNULL(status_codes, '') status_codes
		,ISNULL(life_total_meter_2, 0) life_total_meter_2
		,ISNULL(own_lease_customer, '') own_lease_customer
		,ISNULL(oper_name, '') oper_name 
		,ISNULL(ACCT_acct_code, '') ACCT_acct_code 
		,ISNULL(est_replace_cost,0) est_replace_cost
		,ISNULL(est_replace_yr , 0) est_replace_yr
		,ISNULL(est_replace_mo , 0) est_replace_mo
		,ISNULL(replace_code ,'') replace_code
		,ISNULL(delivery_date,'1900-01-01') delivery_date
		,ISNULL(meter_1_at_delivery, 0) meter_1_at_delivery
		,ISNULL(meter_2_at_delivery,0) meter_2_at_delivery
		,ISNULL(monthly_rent, 0) monthly_rent
		,ISNULL(retire_date , '1900-01-01') retire_date
		,ISNULL(sale_date , '1900-01-01') sale_date
		,ISNULL(sale_price, 0) sale_price
		,ISNULL(disposal_method, '') disposal_method
		,ISNULL(last_pm_sched_date, '1900-01-01') last_pm_sched_date
		,ISNULL(next_pm_sched_date, '1900-01-01') next_pm_sched_date
		,ISNULL(inspection_month , '') inspection_month
		,ISNULL(stat_inspect_month, 0) stat_inspect_month
		,ISNULL(stat_inspect_year , 0) stat_inspect_year
		,ISNULL(stat_inspect_interv , 0) stat_inspect_interv
		,ISNULL(last_pm_slot , 0) last_pm_slot
		,ISNULL(next_pm_slot , 0) next_pm_slot
		,ISNULL(pm_meter_1_interval , 0) pm_meter_1_interval
		,ISNULL(pm_meter_2_interval , 0) pm_meter_2_interval
		,ISNULL(pm_fuel_override , 0) pm_fuel_override
		,ISNULL(pm_pref_shift , '') pm_pref_shift
		,ISNULL(oil_type , '') oil_type
		,ISNULL(depreciation_method , '') depreciation_method
		,ISNULL(depr_cur_decline_bal, 0) depr_cur_decline_bal
		,ISNULL(salvage_value ,0) salvage_value
		,ISNULL(cost_rpt_excl_switch, '') cost_rpt_excl_switch
		,ISNULL(excp_rpt_excl_switch, '') excp_rpt_excl_switch
		,ISNULL(DEPT_pm_notify_dept , '') DEPT_pm_notify_dept
		,ISNULL(work_orders_ok  	, '') work_orders_ok
		,ISNULL(fuel_tickets_ok 	, '') fuel_tickets_ok
		,ISNULL(usage_tickets_ok	, '') usage_tickets_ok
		,ISNULL(disposal_reason 	, '') disposal_reason
		,ISNULL(planned_deliv_date, '1900-01-01') planned_deliv_date
		,ISNULL(planned_insvc_date, '1900-01-01') planned_insvc_date
		,ISNULL(planned_retir_date, '1900-01-01') planned_retir_date
		,ISNULL(disposal_authority,'') disposal_authority
		,ISNULL(est_meter_at_replace,0) est_meter_at_replace
		,ISNULL(last_meter_source, '') last_meter_source 
		,ISNULL(fixed_monthly_cost, 0) fixed_monthly_cost
		,ISNULL(fixed_replace_cost, 0) fixed_replace_cost
		,ISNULL(fixed_licensing_cost, 0) fixed_licensing_cost
		,ISNULL(fixed_cost_other_1 , 0) fixed_cost_other_1
		,ISNULL(fixed_cost_other_2 , 0) fixed_cost_other_2
		,ISNULL(fixed_cost_other_3 , 0) fixed_cost_other_3
		,ISNULL(fixed_insurance_cost , 0) fixed_insurance_cost
		,ISNULL(orig_regist_date , '1900-01-01') orig_regist_date
		,ISNULL(license_st ,'') license_st
		,ISNULL(regist_expire_date , '1900-01-01') regist_expire_date

INTO #eam_stg
--SELECT * 
FROM eam.EQ_Main_stage s
WHERE s.ETLProcessActivityID =  @ETLProcessActivityID
AND s.processed = 'N';

--SELECT * FROM #eam_stg

--delete rows to be process for unnecessary update that have no data change
--SELECT *
DELETE s
FROM #eam_stg s
INNER JOIN eam.equipment_main m
ON m.eq_equip_no = s.eq_equip_no
AND m.PROCST_proc_status = s.PROCST_proc_status
AND ISNULL(m.EQCAT_equip_category,'') = s.EQCAT_equip_category
AND m.LOC_assign_pm_loc = s.LOC_assign_pm_loc
AND m.LOC_assign_repr_loc = s.LOC_assign_repr_loc
AND ISNULL(m.LOC_stored_loc,'') = s.LOC_stored_loc
AND m.DEPT_dept_code = s.DEPT_dept_code
AND ISNULL(m.CPY_company_code,'') = s.CPY_company_code
AND m.CLASS_class_maint = s.CLASS_class_maint
AND m.CLASS_class_meter = s.CLASS_class_meter
AND m.CLASS_class_pm = s.CLASS_class_pm
AND m.CLASS_class_shop_sch = s.CLASS_class_shop_sch
AND m.CLASS_class_rental = s.CLASS_class_rental
AND m.CLASS_class_stds = s.CLASS_class_stds
AND ISNULL(m.license_no,'') = s.license_no
AND ISNULL(m.asset_no,'') = s.asset_no
AND m.pm_prog_type = s.pm_prog_type
AND ISNULL( m.FLT_fleet_no,'') = s.FLT_fleet_no
AND ISNULL(m.ACAT_category_no,'') = s.ACAT_category_no
AND m.asset_type = s.asset_type
AND m.X_datetime_insert = s.X_datetime_insert
AND ISNULL(m.EQTYP_equip_type,'') = s.EQTYP_equip_type --equipment type
AND ISNULL(m.year,0) = s.year --vehicle year
AND ISNULL(m.manufacturer,'') = s.manufacturer --vehicle manufacture
AND ISNULL(m.model,'') = s.model --vehicle model
AND ISNULL(m.description,'') = s.description --vehicle description
AND ISNULL( m.sla_status,'') = s.sla_status --sla equipment category
AND ISNULL(m.work_order_status,'') = s.work_order_status
AND ISNULL(m.fuel_card_no,0) = s.fuel_card_no
AND ISNULL(m.months_in_operation,0) = s.months_in_operation
AND ISNULL(m.deprec_months_life,0) = s.deprec_months_life
AND ISNULL(m.depr_mths_remaining,0) = s.depr_mths_remaining
AND ISNULL(m.shop_status,'') = s.shop_status
AND ISNULL(m.scap,0) = s.scap 
AND ISNULL(m.LOC_assgn_mobile_loc,'') = s.LOC_assgn_mobile_loc
AND ISNULL(m.comment_area,'') = s.comment_area
AND ISNULL(m.DEPT_temp_loaned_to,'') = s.DEPT_temp_loaned_to
AND ISNULL(m.on_temp_loan,'') = s.on_temp_loan 
AND ISNULL(m.in_service_date,'1900-01-01') = s.in_service_date
AND ISNULL(m.inv_list_excl_switch,'')  = s.inv_list_excl_switch
AND ISNULL(m.last_meter_1_reading, 0)  = s.last_meter_1_reading
AND ISNULL(m.last_meter_2_reading, 0)  = s.last_meter_2_reading
AND ISNULL(m.LOC_station_loc,'')  = s.LOC_station_loc 
AND ISNULL(m.LOC_current_loc,'')  = s.LOC_current_loc 
AND ISNULL(m.meter_1_type,'' )  = s.meter_1_type
AND ISNULL(m.meter_2_type,'')   = s.meter_2_type 
AND ISNULL(m.original_cost,0)   = s.original_cost
AND ISNULL(m.PRI_shop_priority,'') = s.PRI_shop_priority
AND ISNULL(m.serial_no,'')  = s.serial_no 
AND ISNULL(m.status_codes, '')  = s.status_codes
AND ISNULL(m.life_total_meter_2, 0)  = s.life_total_meter_2
AND ISNULL(m.own_lease_customer, '') = s.own_lease_customer
AND ISNULL(m.oper_name, '')  = s.oper_name 
AND ISNULL(m.ACCT_acct_code, '')  = s.ACCT_acct_code 
AND ISNULL(m.est_replace_cost,0)  = s.est_replace_cost
AND ISNULL(m.est_replace_yr , 0)  = s.est_replace_yr
AND ISNULL(m.est_replace_mo , 0)  = s.est_replace_mo
AND ISNULL(m.replace_code ,'')  = s.replace_code
AND ISNULL(m.delivery_date,'1900-01-01')  = s.delivery_date
AND ISNULL(m.meter_1_at_delivery, 0)  = s.meter_1_at_delivery
AND ISNULL(m.meter_2_at_delivery,0)   = s.meter_2_at_delivery
AND ISNULL(m.monthly_rent, 0)  = s.monthly_rent
AND ISNULL(m.retire_date, '1900-01-01')  = s.retire_date
AND ISNULL(m.sale_date  , '1900-01-01')  = s.sale_date
AND ISNULL(m.sale_price, 0)  = s.sale_price
AND ISNULL(m.disposal_method, '')  = s.disposal_method
AND ISNULL(m.last_pm_sched_date, '1900-01-01')  = s.last_pm_sched_date
AND ISNULL(m.next_pm_sched_date, '1900-01-01')  = s.next_pm_sched_date
AND ISNULL(m.inspection_month , '')  = s.inspection_month
AND ISNULL(m.stat_inspect_month, 0)  = s.stat_inspect_month
AND ISNULL(m.stat_inspect_year , 0)  = s.stat_inspect_year
AND ISNULL(m.stat_inspect_interv , 0)  = s.stat_inspect_interv
AND ISNULL(m.last_pm_slot , 0)  = s.last_pm_slot
AND ISNULL(m.next_pm_slot , 0)  = s.next_pm_slot
AND ISNULL(m.pm_meter_1_interval , 0)  = s.pm_meter_1_interval
AND ISNULL(m.pm_meter_2_interval , 0)  = s.pm_meter_2_interval
AND ISNULL(m.pm_fuel_override , 0)  = s.pm_fuel_override
AND ISNULL(m.pm_pref_shift , '')  = s.pm_pref_shift
AND ISNULL(m.oil_type , '')  = s.oil_type
AND ISNULL(m.depreciation_method , '')  = s.depreciation_method
AND ISNULL(m.depr_cur_decline_bal, 0)  = s.depr_cur_decline_bal
AND ISNULL(m.salvage_value ,0)  = s.salvage_value
AND ISNULL(m.cost_rpt_excl_switch, '')  = s.cost_rpt_excl_switch
AND ISNULL(m.excp_rpt_excl_switch, '')  = s.excp_rpt_excl_switch
AND ISNULL(m.DEPT_pm_notify_dept , '')  = s.DEPT_pm_notify_dept
AND ISNULL(m.work_orders_ok  	, '')  = s.work_orders_ok
AND ISNULL(m.fuel_tickets_ok 	, '')  = s.fuel_tickets_ok
AND ISNULL(m.usage_tickets_ok	, '')  = s.usage_tickets_ok
AND ISNULL(m.disposal_reason 	, '')  = s.disposal_reason
AND ISNULL(m.planned_deliv_date, '1900-01-01')  = s.planned_deliv_date
AND ISNULL(m.planned_insvc_date, '1900-01-01')  = s.planned_insvc_date
AND ISNULL(m.planned_retir_date, '1900-01-01')  = s.planned_retir_date
AND ISNULL(m.disposal_authority,'')   = s.disposal_authority
AND ISNULL(m.est_meter_at_replace,0)  = s.est_meter_at_replace
AND ISNULL(m.last_meter_source, '')  = s.last_meter_source 
AND ISNULL(m.fixed_monthly_cost, 0)  = s.fixed_monthly_cost
AND ISNULL(m.fixed_replace_cost, 0)  = s.fixed_replace_cost
AND ISNULL(m.fixed_licensing_cost, 0) = s.fixed_licensing_cost
AND ISNULL(m.fixed_cost_other_1 , 0)  = s.fixed_cost_other_1
AND ISNULL(m.fixed_cost_other_2 , 0)  = s.fixed_cost_other_2
AND ISNULL(m.fixed_cost_other_3 , 0)  = s.fixed_cost_other_3
AND ISNULL(m.fixed_insurance_cost , 0)  = s.fixed_insurance_cost
AND ISNULL(m.orig_regist_date , '1900-01-01')  = s.orig_regist_date
AND ISNULL(m.license_st ,'')  = s.license_st
AND ISNULL(m.regist_expire_date , '1900-01-01')  = s.regist_expire_date
WHERE  m.equipment_status_date = '9999-12-31'


--SELECT * FROM #eam_stg
UPDATE s
SET s.is_updated = 1	--identify previously known equipment
FROM eam.equipment_main m
INNER JOIN #eam_stg s
	ON m.eq_equip_no = s.eq_equip_no
WHERE (m.equipment_status_date = '9999-12-31' OR m.end_date = '9999-12-31')
	AND s.ETLProcessActivityID = @ETLProcessActivityID;

UPDATE m
SET m.equipment_status_date = DATEADD(DAY, -1,s.X_datetime_update),
	m.end_date = DATEADD(DAY, -1,s.X_datetime_update)
FROM eam.equipment_main m
INNER JOIN #eam_stg s
	ON m.eq_equip_no = s.eq_equip_no
WHERE (m.equipment_status_date = '9999-12-31' OR m.end_date = '9999-12-31')
	AND s.ETLProcessActivityID = @ETLProcessActivityID;

SET @upd = @@ROWCOUNT



-- insert new equipment
INSERT eam.equipment_main
(    eq_equip_no,
    PROCST_proc_status,
    EQCAT_equip_category,
    LOC_assign_pm_loc,
    LOC_assign_repr_loc,
    LOC_stored_loc,
    DEPT_dept_code,
    CPY_company_code,
    CLASS_class_maint,
    CLASS_class_meter,
    CLASS_class_pm,
    CLASS_class_shop_sch,
    CLASS_class_rental,
    CLASS_class_stds,
    license_no,
    asset_no,
    pm_prog_type,
    FLT_fleet_no,
    ACAT_category_no,
    asset_type,
    equipment_status_date,
    X_datetime_update,
    X_datetime_insert,
 --   record_created_date,
    record_updated_date
	, ETLProcessActivityID
	, begin_date
	, end_date
	, EQTYP_equip_type --equipment type
	, year --vehicle year
	, manufacturer --vehicle manufacture
	, model --vehicle model
	, description --vehicle description
	, sla_status --sla equipment category
	, work_order_status
	, fuel_card_no
	, months_in_operation
	, deprec_months_life
	, depr_mths_remaining 
	, shop_status
	, scap
	, LOC_assgn_mobile_loc
	, comment_area
	, DEPT_temp_loaned_to
	, on_temp_loan 
	, in_service_date
	, inv_list_excl_switch
	, last_meter_1_reading
	, last_meter_2_reading
	, LOC_station_loc 
	, LOC_current_loc 
	, meter_1_type 
	, meter_2_type 
	, original_cost
	, PRI_shop_priority
	, serial_no 
	, status_codes
	, life_total_meter_2
	, own_lease_customer
	, oper_name 
	, ACCT_acct_code 
	, est_replace_cost
	, est_replace_yr 
	, est_replace_mo 
	, replace_code 
	, delivery_date
	, meter_1_at_delivery
	, meter_2_at_delivery
	, monthly_rent
	, retire_date 
	, sale_date 
	, sale_price
	, disposal_method 
	, last_pm_sched_date
	, next_pm_sched_date
	, inspection_month 
	, stat_inspect_month
	, stat_inspect_year 
	, stat_inspect_interv 
	, last_pm_slot 
	, next_pm_slot 
	, pm_meter_1_interval 
	, pm_meter_2_interval 
	, pm_fuel_override 
	, pm_pref_shift 
	, oil_type 
	, depreciation_method 
	, depr_cur_decline_bal
	, salvage_value 
	, cost_rpt_excl_switch
	, excp_rpt_excl_switch
	, DEPT_pm_notify_dept 
	, work_orders_ok  
	, fuel_tickets_ok 
	, usage_tickets_ok
	, disposal_reason 
	, planned_deliv_date
	, planned_insvc_date
	, planned_retir_date
	, disposal_authority
	, est_meter_at_replace
	, last_meter_source 
	, fixed_monthly_cost
	, fixed_replace_cost
	, fixed_licensing_cost
	, fixed_cost_other_1 
	, fixed_cost_other_2 
	, fixed_cost_other_3 
	, fixed_insurance_cost 
	, orig_regist_date 
	, license_st 
	, regist_expire_date		)

SELECT s.eq_equip_no,
       s.PROCST_proc_status,
       s.EQCAT_equip_category,
       s.LOC_assign_pm_loc,
       s.LOC_assign_repr_loc,
       s.LOC_stored_loc,
       s.DEPT_dept_code,
       s.CPY_company_code,
       s.CLASS_class_maint,
       s.CLASS_class_meter,
       s.CLASS_class_pm,
       s.CLASS_class_shop_sch,
       s.CLASS_class_rental,
       s.CLASS_class_stds,
       s.license_no,
       s.asset_no,
       s.pm_prog_type,
       s.FLT_fleet_no,
       s.ACAT_category_no,
       s.asset_type,
	   '9999-12-31' equipment_status_date,
       s.X_datetime_update,
       s.X_datetime_insert,
	   GETDATE(),
	   s.ETLProcessActivityID,
	   s.X_datetime_insert, --initial insert
	   '9999-12-31' end_date
	   	, s.EQTYP_equip_type --equipment type
		, s.year --vehicle year
		, s.manufacturer --vehicle manufacture
		, s.model --vehicle model
		, s.description --vehicle description
		, s.sla_status --sla equipment category
		, s.work_order_status
		, s.fuel_card_no
		, s.months_in_operation
		, s.deprec_months_life
		, s.depr_mths_remaining 
		, s.shop_status
		, s.scap
		, s.LOC_assgn_mobile_loc
		, s.comment_area
		, s.DEPT_temp_loaned_to
		, s.on_temp_loan 
		, s.in_service_date
		, s.inv_list_excl_switch
		, s.last_meter_1_reading
		, s.last_meter_2_reading
		, s.LOC_station_loc 
		, s.LOC_current_loc 
		, s.meter_1_type 
		, s.meter_2_type 
		, s.original_cost
		, s.PRI_shop_priority
		, s.serial_no 
		, s.status_codes
		, s.life_total_meter_2
		, s.own_lease_customer
		, s.oper_name 
		, s.ACCT_acct_code 
		, s.est_replace_cost
		, s.est_replace_yr 
		, s.est_replace_mo 
		, s.replace_code 
		, s.delivery_date
		, s.meter_1_at_delivery
		, s.meter_2_at_delivery
		, s.monthly_rent
		, s.retire_date 
		, s.sale_date 
		, s.sale_price
		, s.disposal_method 
		, s.last_pm_sched_date
		, s.next_pm_sched_date
		, s.inspection_month 
		, s.stat_inspect_month
		, s.stat_inspect_year 
		, s.stat_inspect_interv 
		, s.last_pm_slot 
		, s.next_pm_slot 
		, s.pm_meter_1_interval 
		, s.pm_meter_2_interval 
		, s.pm_fuel_override 
		, s.pm_pref_shift 
		, s.oil_type 
		, s.depreciation_method 
		, s.depr_cur_decline_bal
		, s.salvage_value 
		, s.cost_rpt_excl_switch
		, s.excp_rpt_excl_switch
		, s.DEPT_pm_notify_dept 
		, s.work_orders_ok  
		, s.fuel_tickets_ok 
		, s.usage_tickets_ok
		, s.disposal_reason 
		, s.planned_deliv_date
		, s.planned_insvc_date
		, s.planned_retir_date
		, s.disposal_authority
		, s.est_meter_at_replace
		, s.last_meter_source 
		, s.fixed_monthly_cost
		, s.fixed_replace_cost
		, s.fixed_licensing_cost
		, s.fixed_cost_other_1 
		, s.fixed_cost_other_2 
		, s.fixed_cost_other_3 
		, s.fixed_insurance_cost 
		, s.orig_regist_date 
		, s.license_st 
		, s.regist_expire_date
FROM #eam_stg s
WHERE s.ETLProcessActivityID = @ETLProcessActivityID
AND s.processed = 'N'
AND s.is_updated = 0;

SET @ins = @@ROWCOUNT

--insert updated equipment
INSERT eam.equipment_main
(    eq_equip_no,
    PROCST_proc_status,
    EQCAT_equip_category,
    LOC_assign_pm_loc,
    LOC_assign_repr_loc,
    LOC_stored_loc,
    DEPT_dept_code,
    CPY_company_code,
    CLASS_class_maint,
    CLASS_class_meter,
    CLASS_class_pm,
    CLASS_class_shop_sch,
    CLASS_class_rental,
    CLASS_class_stds,
    license_no,
    asset_no,
    pm_prog_type,
    FLT_fleet_no,
    ACAT_category_no,
    asset_type,
    equipment_status_date,
    X_datetime_update,
    X_datetime_insert,
 --   record_created_date,
    record_updated_date
	, ETLProcessActivityID
	, begin_date
	, end_date
	, EQTYP_equip_type --equipment type
	, year --vehicle year
	, manufacturer --vehicle manufacture
	, model --vehicle model
	, description --vehicle description
	, sla_status --sla equipment category
	, work_order_status
	, fuel_card_no
	, months_in_operation
	, deprec_months_life
	, depr_mths_remaining 
	, shop_status
	, scap
	, LOC_assgn_mobile_loc
	, comment_area
	, DEPT_temp_loaned_to
	, on_temp_loan 
	, in_service_date
	, inv_list_excl_switch
	, last_meter_1_reading
	, last_meter_2_reading
	, LOC_station_loc 
	, LOC_current_loc 
	, meter_1_type 
	, meter_2_type 
	, original_cost
	, PRI_shop_priority
	, serial_no 
	, status_codes
	, life_total_meter_2
	, own_lease_customer
	, oper_name 
	, ACCT_acct_code 
	, est_replace_cost
	, est_replace_yr 
	, est_replace_mo 
	, replace_code 
	, delivery_date
	, meter_1_at_delivery
	, meter_2_at_delivery
	, monthly_rent
	, retire_date 
	, sale_date 
	, sale_price
	, disposal_method 
	, last_pm_sched_date
	, next_pm_sched_date
	, inspection_month 
	, stat_inspect_month
	, stat_inspect_year 
	, stat_inspect_interv 
	, last_pm_slot 
	, next_pm_slot 
	, pm_meter_1_interval 
	, pm_meter_2_interval 
	, pm_fuel_override 
	, pm_pref_shift 
	, oil_type 
	, depreciation_method 
	, depr_cur_decline_bal
	, salvage_value 
	, cost_rpt_excl_switch
	, excp_rpt_excl_switch
	, DEPT_pm_notify_dept 
	, work_orders_ok  
	, fuel_tickets_ok 
	, usage_tickets_ok
	, disposal_reason 
	, planned_deliv_date
	, planned_insvc_date
	, planned_retir_date
	, disposal_authority
	, est_meter_at_replace
	, last_meter_source 
	, fixed_monthly_cost
	, fixed_replace_cost
	, fixed_licensing_cost
	, fixed_cost_other_1 
	, fixed_cost_other_2 
	, fixed_cost_other_3 
	, fixed_insurance_cost 
	, orig_regist_date 
	, license_st 
	, regist_expire_date		)

SELECT s.eq_equip_no,
       s.PROCST_proc_status,
       s.EQCAT_equip_category,
       s.LOC_assign_pm_loc,
       s.LOC_assign_repr_loc,
       s.LOC_stored_loc,
       s.DEPT_dept_code,
       s.CPY_company_code,
       s.CLASS_class_maint,
       s.CLASS_class_meter,
       s.CLASS_class_pm,
       s.CLASS_class_shop_sch,
       s.CLASS_class_rental,
       s.CLASS_class_stds,
       s.license_no,
       s.asset_no,
       s.pm_prog_type,
       s.FLT_fleet_no,
       s.ACAT_category_no,
       s.asset_type,
	   '9999-12-31' equipment_status_date,
       s.X_datetime_update,
       s.X_datetime_insert,
	   GETDATE(),
	   s.ETLProcessActivityID,
	   s.X_datetime_update AS begin_Date, --subsequence insert of the same equipment
	   '9999-12-31' end_date
	   	, s.EQTYP_equip_type --equipment type
		, s.year --vehicle year
		, s.manufacturer --vehicle manufacture
		, s.model --vehicle model
		, s.description --vehicle description
		, s.sla_status --sla equipment category
		, s.work_order_status
		, s.fuel_card_no
		, s.months_in_operation
		, s.deprec_months_life
		, s.depr_mths_remaining 
		, s.shop_status
		, s.scap
		, s.LOC_assgn_mobile_loc
		, s.comment_area
		, s.DEPT_temp_loaned_to
		, s.on_temp_loan 
		, s.in_service_date
		, s.inv_list_excl_switch
		, s.last_meter_1_reading
		, s.last_meter_2_reading
		, s.LOC_station_loc 
		, s.LOC_current_loc 
		, s.meter_1_type 
		, s.meter_2_type 
		, s.original_cost
		, s.PRI_shop_priority
		, s.serial_no 
		, s.status_codes
		, s.life_total_meter_2
		, s.own_lease_customer
		, s.oper_name 
		, s.ACCT_acct_code 
		, s.est_replace_cost
		, s.est_replace_yr 
		, s.est_replace_mo 
		, s.replace_code 
		, s.delivery_date
		, s.meter_1_at_delivery
		, s.meter_2_at_delivery
		, s.monthly_rent
		, s.retire_date 
		, s.sale_date 
		, s.sale_price
		, s.disposal_method 
		, s.last_pm_sched_date
		, s.next_pm_sched_date
		, s.inspection_month 
		, s.stat_inspect_month
		, s.stat_inspect_year 
		, s.stat_inspect_interv 
		, s.last_pm_slot 
		, s.next_pm_slot 
		, s.pm_meter_1_interval 
		, s.pm_meter_2_interval 
		, s.pm_fuel_override 
		, s.pm_pref_shift 
		, s.oil_type 
		, s.depreciation_method 
		, s.depr_cur_decline_bal
		, s.salvage_value 
		, s.cost_rpt_excl_switch
		, s.excp_rpt_excl_switch
		, s.DEPT_pm_notify_dept 
		, s.work_orders_ok  
		, s.fuel_tickets_ok 
		, s.usage_tickets_ok
		, s.disposal_reason 
		, s.planned_deliv_date
		, s.planned_insvc_date
		, s.planned_retir_date
		, s.disposal_authority
		, s.est_meter_at_replace
		, s.last_meter_source 
		, s.fixed_monthly_cost
		, s.fixed_replace_cost
		, s.fixed_licensing_cost
		, s.fixed_cost_other_1 
		, s.fixed_cost_other_2 
		, s.fixed_cost_other_3 
		, s.fixed_insurance_cost 
		, s.orig_regist_date 
		, s.license_st 
		, s.regist_expire_date

FROM #eam_stg s
WHERE s.ETLProcessActivityID = @ETLProcessActivityID
AND s.processed = 'N'
AND s.is_updated = 1;

SET @ins = @ins + @@ROWCOUNT

--Disposed equipment
UPDATE m
SET m.equipment_status_date = DATEADD(DAY, -1,m.X_datetime_update),
	m.end_date = DATEADD(DAY, -1,m.X_datetime_update)
FROM eam.equipment_main m
WHERE (m.end_date = '9999-12-31')
	AND PROCST_proc_status = 'D'


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
SELECT  'EAME' 
		,'ltd_dw.eam.equipment_main' 
		,'ltd_dw.eam.eq_main_stage'
		,@SPROC  
		,ISNULL(@ins,0) 
		,ISNULL(@upd,0)
		,0
		,@sdt
		,SYSDATETIME()
	

UPDATE s
SET s.processed = 'Y'
FROM  eam.EQ_Main_stage s	
WHERE s.ETLProcessActivityID = @ETLProcessActivityID
	AND Processed = 'N';

/*
Life Cycle Status:
OR On Order
IN Inspection Period
A Active
PD Prep for Disposal
D Disposed

SLA Equpipment Category:Service Type:
Revenue
Non-Revenue
DemAND Response 
etc...

Asset Category ID:Vehicle Type:
Bus
Cutaway
Van
Sedan
Truck
etc...

PM Location:Repair Location:
Who is responsible for repairing AND doing PM for the vehicle
Lane transit District
Ride Source
etc...

Stored Location:
LTD
Ridesource
South Lane Wheels
Etc...

Department ID:
Department Responsible for the Vehicle:
Mibility services (for specialized services vehicles)
Fleet
Facilities
Admin
IT

Registration Class:
This identifies where the title is located:
LTD,
ODOT

*/


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
