SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE    PROCEDURE  [eam].[eq_main_data_stage]
AS

/*-----------LTD_GLOSSARY---------------
CREATED BY:	Sopheap Suy
UPDATED DT: 08/12/2025 
purpose	:	pull data from eam eq_main to eam.eq_main_stage
use		:	exec eam.eq_main_data_stage

purpose	 :  Add object activities on who, what, when call this object
			write this data to aud.object_activity table everytime it's called 

UPDATED DT: 10/02/2025 
UPDATED BY: Sopheap Suy
			add addition columns from eq_main
			
			*/

SET NOCOUNT ON

DECLARE @SPROC VARCHAR(100)
SET @SPROC = OBJECT_SCHEMA_NAME(@@PROCID) + '.' + OBJECT_NAME(@@PROCID)

INSERT INTO dba.aud.Object_Activity
	(server_name, database_name ,HOST_NAME, [System_User], OBJECT_NAME
	,client_net_address, local_net_address, auth_Scheme, last_read, last_write
	,most_recent_sql_handle, TIMESTAMP, object_type)
SELECT DISTINCT @@SERVERNAME, DB_NAME(),HOST_NAME(),SYSTEM_USER, @SPROC,
	client_net_address, local_net_address , auth_Scheme, last_read, last_write 
	,most_recent_sql_handle, CURRENT_TIMESTAMP AS TIMESTAMP, 'PROC'
FROM sys.dm_exec_connections 
WHERE session_id = @@SPID ;

BEGIN TRY

	DECLARE @ETLProcessID INT,
			@ETLProcessActivityID INT,
			@previous_start_time DATETIME,
			@cnt INT

	SET @ETLProcessID =(SELECT ETLProcessID FROM Staging.dbo.ETLProcess WHERE ProcessName = 'eq_main_stage' )

	--select ETLProcessID from Staging.dbo.ETLProcess WHERE ProcessName = 'eq_main_stage'
	--SELECT ISNULL(MAX(EndTime), '1950-01-01' ) FROM Staging.dbo.ETLProcessActivity WHERE ETLProcessID = 1
	
	--TRUNCATE TABLE Staging.dbo.ETLProcessActivity 
	--TRUNCATE TABLE  eam.eq_main_stage

	--find previouly staged date time for this data
	SET @previous_start_time = (SELECT ISNULL(MAX(EndTime), '1950-01-01' ) FROM Staging.dbo.ETLProcessActivity WHERE ETLProcessID = @ETLProcessID )

	--SELECT @previous_start_time 

	--insert into dbo.ETLProcessActivity for record keeping
	EXEC Staging.dbo.ETLProcessActivity_insert @ETLProcessID --eq_main_stage
 
	SET @ETLProcessActivityID = (SELECT MAX(ETLProcessActivityID ) FROM Staging.dbo.ETLProcessActivity WHERE ETLProcessID = @ETLProcessID )
	SELECT @ETLProcessActivityID

	--ALTER TABLE eam.eq_main_stage
	--ADD life_total_meter_1 int

	INSERT eam.eq_main_stage(
		  eq_equip_no 
		, PROCST_proc_status	--[life cycle status]
		, EQCAT_equip_category	-- [SLA EQUIPMENT CATEGORY]
		, LOC_assign_pm_loc		--[PM LOCATIONS] 
		, LOC_assign_repr_loc	--[REPAIR LOCATION]
		, LOC_stored_loc		--[stored location]
		, DEPT_dept_code		--[Department ID]
		, CPY_company_code		--[company id]
		, CLASS_class_maint
		, CLASS_class_meter
		, CLASS_class_pm
		, CLASS_class_shop_sch
		, CLASS_class_rental
		, CLASS_class_stds
		, license_no, asset_no
		, pm_prog_type
		, FLT_fleet_no
		, ACAT_category_no
		, asset_type
		, X_datetime_update 
		, X_datetime_insert
		, life_total_meter_1
		, ETLProcessActivityID
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
		, DB_ACC
		, row_id
		, LOC_assgn_mobile_loc 
		, assoc_equip_no 
		, POOLTYP_veh_type
		, serial_no 
		, meter_1_type
		, meter_2_type
		, color 
		, license_st 
		, OPER_oper_no 
		, oper_name 
		, status_codes 
		, radio_no 
		, cost_center 
		, billing_code
		, ACCT_acct_code
		, approval_level
		, PRI_shop_priority 
		, ready_disposition 
		, LOC_station_loc
		, parking_stall
		, comment_area 
		, title 
		, authorization_no 
		, original_cost 
		, est_replace_cost
		, est_replace_yr 
		, est_replace_mo 
		, replace_code 
		, date_added 
		, delivery_date 
		, in_service_date 
		, meter_1_at_delivery
		, meter_2_at_delivery
		, meter_1_prev_total 
		, meter_2_prev_total 
		, own_lease_customer 
		, monthly_rent 
		, lease_expiration_dt
		, fixed_monthly_cost 
		, orig_regist_date 
		, regist_expire_date
		, retire_date
		, sale_date 
		, disposal_method 
		, buy_back 
		, EQ_replaced_by_unit
		, EQ_replacing_unit 
		, last_pm_sched_date
		, last_pm_start_date
		, next_pm_sched_date
		, inspection_month 
		, stat_inspect_month
		, stat_inspect_year 
		, stat_inspect_interv 
		, last_pm_slot 
		, next_pm_slot 
		, last_pm_meter_1 
		, last_pm_meter_2 
		, pm_meter_1_interval
		, pm_meter_2_interval
		, pm_fuel_override 
		, pm_fuel_since_last
		, oil_type 
		, tire_type
		, qty_open_work_orders
		, qty_tires 
		, last_meter_1_reading
		, last_meter_2_reading
		, last_meter_1_date 
		, last_meter_2_date 
		, last_meter_source 
		, LOC_last_fuel_loc 
		, usage_ticket_flag 
		, off_road_use 
		, off_road_pct 
		, depreciation_method 
		, depr_cur_decline_bal
		, salvage_value 
		, LOC_reserv_loc
		, reserv_status 
		, last_reserv_date_out
		, last_reserv_date_in 
		, last_reserv_mtr_out 
		, last_reserv_meter_in
		, exception_switches 
		, cost_rpt_excl_switch 
		, excp_rpt_excl_switch 
		, inv_list_excl_switch 
		, fixed_insurance_cost 
		, fixed_replace_cost 
		, fixed_licensing_cost 
		, fixed_cost_other_1 
		, fixed_cost_other_2 
		, fixed_cost_other_3 
		, TAX_tax_code 
		, salvage_value_pct 
		, repl_cost_computed 
		, repl_cost_recov_year
		, repl_cst_totrcov_yr 
		, repl_cst_totrcov_lif
		, ACCT_rev_acct_code 
		, DEPT_pm_notify_dept
		, capital_cost_posted
		, work_orders_ok 
		, fuel_tickets_ok
		, usage_tickets_ok 
		, max_meter_1_value
		, max_meter_2_value
		, cur_oper_is_first
		, base_mrp_cost 
		, actual_company_cost 
		, base_mrp_first_oper 
		, actual_co_first_oper
		, shipping_cost 
		, duty_cost
		, vat_cost 
		, LOC_current_loc
		, on_temp_loan 
		, DEPT_temp_loaned_to
		, temp_loan_date 
		, disposal_reason
		, transferee_name
		, transferee_address1 
		, transferee_address2 
		, transferee_address3 
		, transferee_address4 
		, INS_insurance_code 
		, order_date 
		, planned_deliv_date
		, planned_insvc_date
		, planned_retir_date
		, capitalized_value 
		, capitalized_date
		, o_license_date 
		, disposal_authority
		, disposal_comment 
		, green_disk_no 
		, planned_licpl_date
		, lic_plating_no 
		, has_tachograph 
		, dielectric_testing 
		, est_meter_at_replace 
		, user_status_1 
		, user_status_2 
		, user_status_3 
		, study_code 
		, outfitting_cost 
		, outfitting_effort
		, last_regular_insp_dt 
		, last_statute_insp_dt 
		, last_oil_change_date 
		, last_oil_change_mtr1 
		, last_oil_change_mtr2 
		, life_total_meter_2 
		, license_no_2 
		, meter_posting_flag
		, last_fuel_date 
		, last_yardck_datetime
		, yardck_avail_repair 
		, is_test_equip 
		, LOC_access_rts_loc
		, comment_area_msg 
		, class_class_bench
		, file_path 
		, file_description 
		, is_asset
		, parent_life_meter_1
		, track_parent_meter 
		, ref_equip_pos 
		, LEASE_lease_id
		, lease_residual_value
		, currency_row_id
		, EQ_equip_no_new
		, eq_invalidated 
		, any_fuel_type 
		, pm_pref_shift 
		, sale_price 
		, LOC_sla_loc
		, RESV_last_reserv_no
		, radio_vehicle_loc 
		, radio_building_loc
		, radio_other_loc 
		, SYSGR_system_grouping
		, last_pm_start_meter_1
		, last_pm_start_meter_2
		, last_meter_2_source 
		)
	SELECT eq_equip_no 
		, PROCST_proc_status	--[life cycle status]
		, EQCAT_equip_category	-- [SLA EQUIPMENT CATEGORY]
		, LOC_assign_pm_loc		--[PM LOCATIONS] 
		, LOC_assign_repr_loc	--[REPAIR LOCATION]
		, LOC_stored_loc		--[stored location]
		, DEPT_dept_code		--[Department ID]
		, CPY_company_code		--[company id]
		, CLASS_class_maint
		, CLASS_class_meter
		, CLASS_class_pm
		, CLASS_class_shop_sch
		, CLASS_class_rental
		, CLASS_class_stds
		, license_no, asset_no
		, pm_prog_type
		, FLT_fleet_no
		, ACAT_category_no
		, asset_type
		, X_datetime_update 
		, X_datetime_insert
		, life_total_meter_1
		, @ETLProcessActivityID ETLProcessActivityID
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
		, DB_ACC
		, row_id
		, LOC_assgn_mobile_loc 
		, assoc_equip_no 
		, POOLTYP_veh_type
		, serial_no 
		, meter_1_type
		, meter_2_type
		, color 
		, license_st 
		, OPER_oper_no 
		, oper_name 
		, status_codes 
		, radio_no 
		, cost_center 
		, billing_code
		, ACCT_acct_code
		, approval_level
		, PRI_shop_priority 
		, ready_disposition 
		, LOC_station_loc
		, parking_stall
		, comment_area 
		, title 
		, authorization_no 
		, original_cost 
		, est_replace_cost
		, est_replace_yr 
		, est_replace_mo 
		, replace_code 
		, date_added 
		, delivery_date 
		, in_service_date 
		, meter_1_at_delivery
		, meter_2_at_delivery
		, meter_1_prev_total 
		, meter_2_prev_total 
		, own_lease_customer 
		, monthly_rent 
		, lease_expiration_dt
		, fixed_monthly_cost 
		, orig_regist_date 
		, regist_expire_date
		, retire_date
		, sale_date 
		, disposal_method 
		, buy_back 
		, EQ_replaced_by_unit
		, EQ_replacing_unit 
		, last_pm_sched_date
		, last_pm_start_date
		, next_pm_sched_date
		, inspection_month 
		, stat_inspect_month
		, stat_inspect_year 
		, stat_inspect_interv 
		, last_pm_slot 
		, next_pm_slot 
		, last_pm_meter_1 
		, last_pm_meter_2 
		, pm_meter_1_interval
		, pm_meter_2_interval
		, pm_fuel_override 
		, pm_fuel_since_last
		, oil_type 
		, tire_type
		, qty_open_work_orders
		, qty_tires 
		, last_meter_1_reading
		, last_meter_2_reading
		, last_meter_1_date 
		, last_meter_2_date 
		, last_meter_source 
		, LOC_last_fuel_loc 
		, usage_ticket_flag 
		, off_road_use 
		, off_road_pct 
		, depreciation_method 
		, depr_cur_decline_bal
		, salvage_value 
		, LOC_reserv_loc
		, reserv_status 
		, last_reserv_date_out
		, last_reserv_date_in 
		, last_reserv_mtr_out 
		, last_reserv_meter_in
		, exception_switches 
		, cost_rpt_excl_switch 
		, excp_rpt_excl_switch 
		, inv_list_excl_switch 
		, fixed_insurance_cost 
		, fixed_replace_cost 
		, fixed_licensing_cost 
		, fixed_cost_other_1 
		, fixed_cost_other_2 
		, fixed_cost_other_3 
		, TAX_tax_code 
		, salvage_value_pct 
		, repl_cost_computed 
		, repl_cost_recov_year
		, repl_cst_totrcov_yr 
		, repl_cst_totrcov_lif
		, ACCT_rev_acct_code 
		, DEPT_pm_notify_dept
		, capital_cost_posted
		, work_orders_ok 
		, fuel_tickets_ok
		, usage_tickets_ok 
		, max_meter_1_value
		, max_meter_2_value
		, cur_oper_is_first
		, base_mrp_cost 
		, actual_company_cost 
		, base_mrp_first_oper 
		, actual_co_first_oper
		, shipping_cost 
		, duty_cost
		, vat_cost 
		, LOC_current_loc
		, on_temp_loan 
		, DEPT_temp_loaned_to
		, temp_loan_date 
		, disposal_reason
		, transferee_name
		, transferee_address1 
		, transferee_address2 
		, transferee_address3 
		, transferee_address4 
		, INS_insurance_code 
		, order_date 
		, planned_deliv_date
		, planned_insvc_date
		, planned_retir_date
		, capitalized_value 
		, capitalized_date
		, o_license_date 
		, disposal_authority
		, disposal_comment 
		, green_disk_no 
		, planned_licpl_date
		, lic_plating_no 
		, has_tachograph 
		, dielectric_testing 
		, est_meter_at_replace 
		, user_status_1 
		, user_status_2 
		, user_status_3 
		, study_code 
		, outfitting_cost 
		, outfitting_effort
		, last_regular_insp_dt 
		, last_statute_insp_dt 
		, last_oil_change_date 
		, last_oil_change_mtr1 
		, last_oil_change_mtr2 
		, life_total_meter_2 
		, license_no_2 
		, meter_posting_flag
		, last_fuel_date 
		, last_yardck_datetime
		, yardck_avail_repair 
		, is_test_equip 
		, LOC_access_rts_loc
		, comment_area_msg 
		, class_class_bench
		, file_path 
		, file_description 
		, is_asset
		, parent_life_meter_1
		, track_parent_meter 
		, ref_equip_pos 
		, LEASE_lease_id
		, lease_residual_value
		, currency_row_id
		, EQ_equip_no_new
		, eq_invalidated 
		, any_fuel_type 
		, pm_pref_shift 
		, sale_price 
		, LOC_sla_loc
		, RESV_last_reserv_no
		, radio_vehicle_loc 
		, radio_building_loc
		, radio_other_loc 
		, SYSGR_system_grouping
		, last_pm_start_meter_1
		, last_pm_start_meter_2
		, last_meter_2_source 
	FROM [LTD-EAM].proto.emsdba.eq_main
	WHERE (COALESCE(X_datetime_insert, GETDATE()) >= @previous_start_time
	OR COALESCE(X_datetime_update,GETDATE())  >= @previous_start_time)

	SET @cnt = (SELECT COUNT(*) FROM eam.eq_main_stage
	WHERE ETLProcessActivityID = @ETLProcessActivityID)

	EXEC Staging.dbo.ETLProcessActivity_update @ETLProcessActivityID , @cnt


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
             ,@recipients = 'itdba@ltd.org' 
             ,@subject = @sub
             ,@body = @errormsg;

       RAISERROR (
                    @errormsg
                    ,@errsev
                    ,1
                    )
END CATCH
GO
