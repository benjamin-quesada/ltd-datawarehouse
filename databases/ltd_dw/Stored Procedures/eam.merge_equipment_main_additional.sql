SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE   PROCEDURE  [eam].[merge_equipment_main_additional]
AS

/*-----------LTD_GLOSSARY---------------
CREATED BY:	Sopheap Suy
UPDATED DT: 10/08/2025 
purpose	:	pull data from eam.eq_main_stage to eam.equipment_main
use		:	exec eam.merge_equipment_main_additional

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


--DECLARE @SPROC VARCHAR(100)
--SET @SPROC = OBJECT_SCHEMA_NAME(@@PROCID) + '.' + OBJECT_NAME(@@PROCID)

--DECLARE		@ins INT,
--			@upd INT --, 			@del INT

DECLARE @ETLProcessActivityID INT

SET @ETLProcessActivityID = (SELECT MIN(ETLProcessActivityID) 
							FROM ltd_dw.eam.eq_main_addl_stage
							WHERE processed = 'N')
DECLARE @sdt DATETIME2 = SYSDATETIME()
--process a single ETLProcessActivityID data pull at a time

DROP TABLE IF EXISTS #eam_stg



SELECT	   X_datetime_insert
           ,X_userid_insert
           ,ISNULL(DB_ACC,'') DB_ACC
           ,row_id
           ,EQ_equip_no
           ,ISNULL(PART_part_no,'') PART_part_no
           ,ISNULL(part_suffix,0) part_suffix
           ,ISNULL(position,'') position
           ,ISNULL(mark_marker_from,'') mark_marker_from
           ,ISNULL(mark_marker_to,'') mark_marker_to
           ,ISNULL(seg_segment_from, '') seg_segment_from
           ,ISNULL(seg_segment_to,'') seg_segment_to
           ,ISNULL(elevation_from,0) elevation_from
           ,ISNULL(elevation_to,0) elevation_to
           ,ISNULL(latitude_from,'') latitude_from
           ,ISNULL(latitude_to,'') latitude_to
           ,ISNULL(longitude_from,'') longitude_from
           ,ISNULL(longitude_to, '') longitude_to
           ,ISNULL(repl_model_excl_switch, '')repl_model_excl_switch
           ,ISNULL(email_pm_sent, '') email_pm_sent
           ,ISNULL(LOC_last_order_loc, '') LOC_last_order_loc
           ,ISNULL(LAST_order_yr, 0) LAST_order_yr
           ,ISNULL(LAST_order_no, 0 ) LAST_order_no
           ,ISNULL(TASK_last_pm_service,'')TASK_last_pm_service
           ,ISNULL(LOC_stock_loc,'') LOC_stock_loc
           ,ISNULL(comp_meter_upd,'')comp_meter_upd
           ,ISNULL(sale_price_net,0) sale_price_net
           ,ISNULL(sale_expenses,0) sale_expenses
           ,ISNULL(sale_commission, 0) sale_commission
           ,ISNULL(last_unique_id, 0) last_unique_id
           ,ISNULL(lease_expiration_meter, 0) lease_expiration_meter
           ,ISNULL(last_pm_date_source, '') last_pm_date_source

           ,ISNULL(eq_source, '') eq_source
           ,ISNULL(position_link,'') position_link
           ,ISNULL(LINE_line_id,'') LINE_line_id
           ,ISNULL(COND_condition_id,'') COND_condition_id
           ,ISNULL(total_offset_from, 0) total_offset_from
           ,ISNULL(total_offset_to, 0) total_offset_to

           ,ISNULL(ACCT_cml_acct_code, '') ACCT_cml_acct_code
           ,ISNULL(ACCT_ftk_acct_code, '') ACCT_ftk_acct_code
           ,ISNULL(ACCT_lab_acct_code, '') ACCT_lab_acct_code
           ,ISNULL(ACCT_pts_acct_code, '') ACCT_pts_acct_code
           ,ISNULL(ACCT_usg_acct_code, '') ACCT_usg_acct_code
		   ,ISNULL(REGCLASS_id,'') REGCLASS_id
           ,ISNULL(COUNTY_id, '') COUNTY_id
           ,ISNULL(registration_value, 0) registration_value
           ,ISNULL(postal_code, '') postal_code
           ,ISNULL(VRG_valuecode_id, '') VRG_valuecode_id
           ,ISNULL(WAPROF_assign_profile_id, '') WAPROF_assign_profile_id

           ,ISNULL(license_issue_date, '') license_issue_date
           ,ISNULL(purchase_year, 0) purchase_year
           ,ISNULL(COUNTY_secondary_id, '') COUNTY_secondary_id
           ,ISNULL(SEG_boundary_segment, '') SEG_boundary_segment
           ,ISNULL(COND_auto_condition_id,'') COND_auto_condition_id
           ,ISNULL(last_cond_date, '1900-01-01') last_cond_date
           ,ISNULL(last_autocond_date,'1900-01-01') last_autocond_date
           ,ISNULL(last_cond_source, '') last_cond_source
           ,ISNULL(last_autocond_source, '') last_autocond_source
		   ,ISNULL(USR_cond_lastuser,'') USR_cond_lastuser
           ,ISNULL(USR_autocond_lastuser, '') USR_autocond_lastuser
           ,ISNULL(x_offset_from, 0) x_offset_from
           ,ISNULL(x_offset_to, 0) x_offset_to
           ,ISNULL(y_offset_from, 0) y_offset_from
           ,ISNULL(y_offset_to, 0) y_offset_to
           ,ISNULL(z_offset_from, 0 ) z_offset_from
           ,ISNULL(z_offset_to, 0) z_offset_to
		   ,ISNULL(SHAPE_id, '') SHAPE_id
           ,ISNULL(BILLTYP_billingtype_id, '') BILLTYP_billingtype_id
           ,ISNULL(EMG_class_id, '') EMG_class_id
           ,ISNULL(ADR_address_code, '') ADR_address_code
           ,ISNULL(description_style1,'') description_style1
           ,ISNULL(description_style2,'') description_style2
           ,ISNULL(description_style3,'') description_style3
           ,ISNULL(description_style4, '') description_style4
           ,ISNULL(show_in_work_mgmt,'') show_in_work_mgmt
           ,X_datetime_update
           ,ISNULL(ADR_transferee_code,'') ADR_transferee_code
           ,ISNULL(last_full_charge_meter, 0) last_full_charge_meter
           ,ISNULL(last_full_charge_date,'1900-01-01') last_full_charge_date
           ,ISNULL(electric_asset,'') electric_asset
           ,ISNULL(ACM_run_id, 0) ACM_run_id
           ,ISNULL(ACM_model_unique_id,0) ACM_model_unique_id
           ,ISNULL(ACM_component_id,0) ACM_component_id
           ,ISNULL(ACM_is_compliant,'') ACM_is_compliant
           ,ISNULL(ACM_require_for_service_error,'') ACM_require_for_service_error
           ,ISNULL(ACM_datetime_run,'1900-01-01') ACM_datetime_run
           ,ISNULL(DEPLOYMENT_STATUS_id,'') DEPLOYMENT_STATUS_id
           ,ISNULL(event_id, '') event_id
           ,ISNULL(device_id, '') device_id
           ,ISNULL(loan_amount, 0) loan_amount
           ,ISNULL(loan_duration_months, 0) loan_duration_months
           ,ISNULL(loan_annual_interest_rate, 0) loan_annual_interest_rate
           ,ISNULL(loan_start_date, '1900-01-01') loan_start_date
           ,ISNULL(VEND_last_pm_vendor_no, '') VEND_last_pm_vendor_no
           ,ISNULL(last_pm_cml_unique_id, '') last_pm_cml_unique_id
           ,ISNULL(daily_depreciation_rate, 0) daily_depreciation_rate
           ,ETLProcessActivityID
           --,record_create_date
           --,begin_date
          -- ,end_date
		  , is_updated = 0
		  , processed 
INTO #eam_stg
--SELECT * 
FROM eam.EQ_Main_addl_stage s
WHERE s.ETLProcessActivityID =  @ETLProcessActivityID
AND s.processed = 'N';

--SELECT * FROM #eam_stg

--delete rows to be process for unnecessary update that have no data change
--SELECT *
DELETE s
FROM #eam_stg s
INNER JOIN eam.equipment_main_addl m
ON m.eq_equip_no = s.eq_equip_no
AND m.X_datetime_insert = s.X_datetime_insert
AND m.X_userid_insert = s.X_userid_insert
AND ISNULL(m.DB_ACC,'') = s.DB_ACC
AND m.row_id = s.row_id
AND ISNULL(m.PART_part_no,'')  = s.PART_part_no
AND m.part_suffix = s.part_suffix
AND ISNULL(m.position,'')  = s.position
AND ISNULL(m.mark_marker_from,'')  = s.mark_marker_from
AND ISNULL(m.mark_marker_to,'')  = s.mark_marker_to
AND ISNULL(m.seg_segment_from, '')  = s.seg_segment_from
AND ISNULL(m.seg_segment_to,'')  = s.seg_segment_to
AND ISNULL(m.elevation_from,0) = s.elevation_from
AND ISNULL(m.elevation_to,0) = s.elevation_to
AND ISNULL(m.latitude_from,'')  = s.latitude_from
AND ISNULL(m.latitude_to,'')  = s.latitude_to
AND ISNULL(m.longitude_from,'')  = s.longitude_from
AND ISNULL(m.longitude_to, '')  = s.longitude_to
AND ISNULL(m.repl_model_excl_switch, '') = s.repl_model_excl_switch
AND ISNULL(m.email_pm_sent, '')  = s.email_pm_sent
AND ISNULL(m.LOC_last_order_loc, '')  = s.LOC_last_order_loc
AND ISNULL(m.LAST_order_yr, 0) = s.LAST_order_yr
AND ISNULL(m.LAST_order_no, 0 )= s.LAST_order_no
AND ISNULL(m.TASK_last_pm_service,'') = s.TASK_last_pm_service
AND ISNULL(m.LOC_stock_loc,'')  = s.LOC_stock_loc
AND ISNULL(m.comp_meter_upd,'') = s.comp_meter_upd
AND ISNULL(m.sale_price_net,0)= s.sale_price_net
AND ISNULL(m.sale_expenses,0) = s.sale_expenses
AND ISNULL(m.sale_commission, 0)= s.sale_commission
AND ISNULL(m.last_unique_id, 0) = s.last_unique_id
AND ISNULL(m.lease_expiration_meter, 0) = s. lease_expiration_meter
AND ISNULL(m.last_pm_date_source, '')  = s.last_pm_date_source
AND ISNULL(m.eq_source, '')  = s.eq_source
AND ISNULL(m.position_link,'')  = s.position_link
AND ISNULL(m.LINE_line_id,'')  = s.LINE_line_id
AND ISNULL(m.COND_condition_id,'')  = s.COND_condition_id
AND ISNULL(m.total_offset_from, 0)= s.total_offset_from
AND ISNULL(m.total_offset_to, 0)  = s.total_offset_to
AND ISNULL(m.ACCT_cml_acct_code, '')  = s.ACCT_cml_acct_code
AND ISNULL(m.ACCT_ftk_acct_code, '')  = s.ACCT_ftk_acct_code
AND ISNULL(m.ACCT_lab_acct_code, '')  = s.ACCT_lab_acct_code
AND ISNULL(m.ACCT_pts_acct_code, '')  = s.ACCT_pts_acct_code
AND ISNULL(m.ACCT_usg_acct_code, '')  = s.ACCT_usg_acct_code
AND ISNULL(m.REGCLASS_id,'')  = s.REGCLASS_id
AND ISNULL(m.COUNTY_id, '')  = s.COUNTY_id
AND ISNULL(m.registration_value, 0)  = s.registration_value
AND ISNULL(m.postal_code, '')  = s.postal_code
AND ISNULL(m.VRG_valuecode_id, '')  = s.VRG_valuecode_id
AND ISNULL(m.WAPROF_assign_profile_id, '')  = s.WAPROF_assign_profile_id
AND ISNULL(m.license_issue_date, '')  = s.license_issue_date
AND ISNULL(m.purchase_year, 0) =s.purchase_year
AND ISNULL(m.COUNTY_secondary_id, '')  = s.COUNTY_secondary_id
AND ISNULL(m.SEG_boundary_segment, '')  = s.SEG_boundary_segment
AND ISNULL(m.COND_auto_condition_id,'')  = s.COND_auto_condition_id
AND ISNULL(m.last_cond_date, '1900-01-01') = s.last_cond_date
AND ISNULL(m.last_autocond_date,'1900-01-01') = s.last_autocond_date
AND ISNULL(m.last_cond_source, '')  = s.last_cond_source
AND ISNULL(m.last_autocond_source, '')  = s.last_autocond_source
AND ISNULL(m.USR_cond_lastuser,'')  = s.USR_cond_lastuser
AND ISNULL(m.USR_autocond_lastuser, '')  = s.USR_autocond_lastuser
AND ISNULL(m.x_offset_from, 0) = s.x_offset_from
AND ISNULL(m.x_offset_to, 0)   = s.x_offset_to
AND ISNULL(m.y_offset_from, 0) = s.y_offset_from
AND ISNULL(m.y_offset_to, 0)   = s.y_offset_to
AND ISNULL(m.z_offset_from, 0 ) = s.z_offset_from
AND ISNULL(m.z_offset_to, 0) = s.z_offset_to
AND ISNULL(m.SHAPE_id, '')  = s.SHAPE_id 
AND ISNULL(m.BILLTYP_billingtype_id, '')  = s.BILLTYP_billingtype_id
AND ISNULL(m.EMG_class_id, '')  = s.EMG_class_id
AND ISNULL(m.ADR_address_code, '')  = s.ADR_address_code
AND ISNULL(m.description_style1,'')  = s.description_style1
AND ISNULL(m.description_style2,'')  = s.description_style2
AND ISNULL(m.description_style3,'')  = s.description_style3
AND ISNULL(m.description_style4, '')  = s.description_style4
AND ISNULL(m.show_in_work_mgmt,'')  = s.show_in_work_mgmt
AND m.X_datetime_update = s.X_datetime_update
AND ISNULL(m.ADR_transferee_code,'')  = s.ADR_transferee_code
AND ISNULL(m.last_full_charge_meter, 0) = s.last_full_charge_meter
AND ISNULL(m.last_full_charge_date,'1900-01-01') = s.last_full_charge_date
AND ISNULL(m.electric_asset,'')  = s.electric_asset
AND ISNULL(m.ACM_run_id, 0) = s.ACM_run_id
AND ISNULL(m.ACM_model_unique_id,0) = s.ACM_model_unique_id
AND ISNULL(m.ACM_component_id,0)    = s.ACM_component_id
AND ISNULL(m.ACM_is_compliant,'')  = s.ACM_is_compliant
AND ISNULL(m.ACM_require_for_service_error,'')  = s.ACM_require_for_service_error
AND ISNULL(m.ACM_datetime_run,'1900-01-01') = s.ACM_datetime_run
AND ISNULL(m.DEPLOYMENT_STATUS_id,'')  = s.DEPLOYMENT_STATUS_id
AND ISNULL(m.event_id, '')  = s.event_id
AND ISNULL(m.device_id, '')  = s.device_id
AND ISNULL(m.loan_amount, 0) = s.loan_amount
AND ISNULL(m.loan_duration_months, 0) = s.loan_duration_months
AND ISNULL(m.loan_annual_interest_rate, 0) = s.loan_annual_interest_rate
AND ISNULL(m.loan_start_date, '1900-01-01') = s.loan_start_date
AND ISNULL(m.VEND_last_pm_vendor_no, '')  = s.VEND_last_pm_vendor_no
AND ISNULL(m.last_pm_cml_unique_id, '')  = s.last_pm_cml_unique_id
AND ISNULL(m.daily_depreciation_rate, 0) = s.daily_depreciation_rate
WHERE  m.end_date = '9999-12-31'


--SELECT * FROM #eam_stg
UPDATE	s
SET		s.is_updated = 1	--identify previously known equipment
FROM	eam.equipment_main_addl m
INNER JOIN #eam_stg s
	ON m.eq_equip_no = s.eq_equip_no
WHERE  m.end_date = '9999-12-31'
	AND s.ETLProcessActivityID = @ETLProcessActivityID;

UPDATE	m
SET		m.end_date = DATEADD(DAY, -1,s.X_datetime_update)
FROM	eam.equipment_main_addl m
INNER JOIN #eam_stg s
	ON m.eq_equip_no = s.eq_equip_no
WHERE (m.end_date = '9999-12-31')
	AND s.ETLProcessActivityID = @ETLProcessActivityID;

SET @upd = @@ROWCOUNT



-- insert new equipment

INSERT INTO eam.equipment_main_addl
    (X_datetime_insert
    ,X_userid_insert
    ,DB_ACC
    ,row_id
    ,EQ_equip_no
    ,PART_part_no
    ,part_suffix
    ,position
    ,mark_marker_from
    ,mark_marker_to
    ,seg_segment_from
    ,seg_segment_to
    ,elevation_from
    ,elevation_to
    ,latitude_from
    ,latitude_to
    ,longitude_from
    ,longitude_to
    ,repl_model_excl_switch
    ,email_pm_sent
    ,LOC_last_order_loc
    ,LAST_order_yr
    ,LAST_order_no
    ,TASK_last_pm_service
    ,LOC_stock_loc
    ,comp_meter_upd
    ,sale_price_net
    ,sale_expenses
    ,sale_commission
    ,last_unique_id
    ,lease_expiration_meter
    ,last_pm_date_source
    ,eq_source
    ,position_link
    ,LINE_line_id
    ,COND_condition_id
    ,total_offset_from
    ,total_offset_to
    ,ACCT_cml_acct_code
    ,ACCT_ftk_acct_code
    ,ACCT_lab_acct_code
    ,ACCT_pts_acct_code
    ,ACCT_usg_acct_code
    ,REGCLASS_id
    ,COUNTY_id
    ,registration_value
    ,postal_code
    ,VRG_valuecode_id
    ,WAPROF_assign_profile_id
    ,license_issue_date
    ,purchase_year
    ,COUNTY_secondary_id
    ,SEG_boundary_segment
    ,COND_auto_condition_id
    ,last_cond_date
    ,last_autocond_date
    ,last_cond_source
    ,last_autocond_source
    ,USR_cond_lastuser
    ,USR_autocond_lastuser
    ,x_offset_from
    ,x_offset_to
    ,y_offset_from
    ,y_offset_to
    ,z_offset_from
    ,z_offset_to
    ,SHAPE_id
	,BILLTYP_billingtype_id
	,EMG_class_id
	,ADR_address_code
	,description_style1
	,description_style2
	,description_style3
	,description_style4
	,show_in_work_mgmt
	,X_datetime_update
	,ADR_transferee_code
	,last_full_charge_meter
	,last_full_charge_date
	,electric_asset
	,ACM_run_id
	,ACM_model_unique_id
	,ACM_component_id
	,ACM_is_compliant
	,ACM_require_for_service_error
	,ACM_datetime_run
	,DEPLOYMENT_STATUS_id
	,event_id
	,device_id
	,loan_amount
	,loan_duration_months
	,loan_annual_interest_rate
	,loan_start_date
	,VEND_last_pm_vendor_no
	,last_pm_cml_unique_id
	,daily_depreciation_rate
	,ETLProcessActivityID
	,begin_date
	,end_date )

SELECT	s.X_datetime_insert
    ,s.X_userid_insert
    ,s.DB_ACC
    ,s.row_id
    ,s.EQ_equip_no
    ,s.PART_part_no
    ,s.part_suffix
    ,s.position
    ,s.mark_marker_from
    ,s.mark_marker_to
    ,s.seg_segment_from
    ,s.seg_segment_to
    ,s.elevation_from
    ,s.elevation_to
    ,s.latitude_from
    ,s.latitude_to
    ,s.longitude_from
    ,s.longitude_to
    ,s.repl_model_excl_switch
    ,s.email_pm_sent
    ,s.LOC_last_order_loc
    ,s.LAST_order_yr
    ,s.LAST_order_no
    ,s.TASK_last_pm_service
    ,s.LOC_stock_loc
    ,s.comp_meter_upd
    ,s.sale_price_net
    ,s.sale_expenses
    ,s.sale_commission
    ,s.last_unique_id
    ,s.lease_expiration_meter
    ,s.last_pm_date_source
    ,s.eq_source
    ,s.position_link
    ,s.LINE_line_id
    ,s.COND_condition_id
    ,s.total_offset_from
    ,s.total_offset_to
    ,s.ACCT_cml_acct_code
    ,s.ACCT_ftk_acct_code
    ,s.ACCT_lab_acct_code
    ,s.ACCT_pts_acct_code
    ,s.ACCT_usg_acct_code
    ,s.REGCLASS_id
    ,s.COUNTY_id
    ,s.registration_value
    ,s.postal_code
    ,s.VRG_valuecode_id
    ,s.WAPROF_assign_profile_id
    ,s.license_issue_date
    ,s.purchase_year
    ,s.COUNTY_secondary_id
    ,s.SEG_boundary_segment
    ,s.COND_auto_condition_id
    ,s.last_cond_date
    ,s.last_autocond_date
    ,s.last_cond_source
    ,s.last_autocond_source
    ,s.USR_cond_lastuser
    ,s.USR_autocond_lastuser
    ,s.x_offset_from
    ,s.x_offset_to
    ,s.y_offset_from
    ,s.y_offset_to
    ,s.z_offset_from
    ,s.z_offset_to
    ,s.SHAPE_id
    ,s.BILLTYP_billingtype_id
    ,s.EMG_class_id
    ,s.ADR_address_code
    ,s.description_style1
    ,s.description_style2
    ,s.description_style3
    ,s.description_style4
    ,s.show_in_work_mgmt
    ,s.X_datetime_update
    ,s.ADR_transferee_code
    ,s.last_full_charge_meter
    ,s.last_full_charge_date
    ,s.electric_asset
    ,s.ACM_run_id
    ,s.ACM_model_unique_id
    ,s.ACM_component_id
    ,s.ACM_is_compliant
    ,s.ACM_require_for_service_error
    ,s.ACM_datetime_run
    ,s.DEPLOYMENT_STATUS_id
    ,s.event_id
    ,s.device_id
    ,s.loan_amount
    ,s.loan_duration_months
    ,s.loan_annual_interest_rate
    ,s.loan_start_date
    ,s.VEND_last_pm_vendor_no
    ,s.last_pm_cml_unique_id
    ,s.daily_depreciation_rate
    ,s.ETLProcessActivityID
    ,s.X_datetime_insert
	,'9999-12-31' end_date
FROM #eam_stg s
WHERE s.ETLProcessActivityID = @ETLProcessActivityID
AND s.processed = 'N'
AND s.is_updated = 0;

SET @ins = @@ROWCOUNT

--insert updated equipment

INSERT INTO eam.equipment_main_addl
    (X_datetime_insert
    ,X_userid_insert
    ,DB_ACC
    ,row_id
    ,EQ_equip_no
    ,PART_part_no
    ,part_suffix
    ,position
    ,mark_marker_from
    ,mark_marker_to
    ,seg_segment_from
    ,seg_segment_to
    ,elevation_from
    ,elevation_to
    ,latitude_from
    ,latitude_to
    ,longitude_from
    ,longitude_to
    ,repl_model_excl_switch
    ,email_pm_sent
    ,LOC_last_order_loc
    ,LAST_order_yr
    ,LAST_order_no
    ,TASK_last_pm_service
    ,LOC_stock_loc
    ,comp_meter_upd
    ,sale_price_net
    ,sale_expenses
    ,sale_commission
    ,last_unique_id
    ,lease_expiration_meter
    ,last_pm_date_source
    ,eq_source
    ,position_link
    ,LINE_line_id
    ,COND_condition_id
    ,total_offset_from
    ,total_offset_to
    ,ACCT_cml_acct_code
    ,ACCT_ftk_acct_code
    ,ACCT_lab_acct_code
    ,ACCT_pts_acct_code
    ,ACCT_usg_acct_code
    ,REGCLASS_id
    ,COUNTY_id
    ,registration_value
    ,postal_code
    ,VRG_valuecode_id
    ,WAPROF_assign_profile_id
    ,license_issue_date
    ,purchase_year
    ,COUNTY_secondary_id
    ,SEG_boundary_segment
    ,COND_auto_condition_id
    ,last_cond_date
    ,last_autocond_date
    ,last_cond_source
    ,last_autocond_source
    ,USR_cond_lastuser
    ,USR_autocond_lastuser
    ,x_offset_from
    ,x_offset_to
    ,y_offset_from
    ,y_offset_to
    ,z_offset_from
    ,z_offset_to
    ,SHAPE_id
	,BILLTYP_billingtype_id
	,EMG_class_id
	,ADR_address_code
	,description_style1
	,description_style2
	,description_style3
	,description_style4
	,show_in_work_mgmt
	,X_datetime_update
	,ADR_transferee_code
	,last_full_charge_meter
	,last_full_charge_date
	,electric_asset
	,ACM_run_id
	,ACM_model_unique_id
	,ACM_component_id
	,ACM_is_compliant
	,ACM_require_for_service_error
	,ACM_datetime_run
	,DEPLOYMENT_STATUS_id
	,event_id
	,device_id
	,loan_amount
	,loan_duration_months
	,loan_annual_interest_rate
	,loan_start_date
	,VEND_last_pm_vendor_no
	,last_pm_cml_unique_id
	,daily_depreciation_rate
	,ETLProcessActivityID
	,begin_date
	,end_date )

SELECT	s.X_datetime_insert
    ,s.X_userid_insert
    ,s.DB_ACC
    ,s.row_id
    ,s.EQ_equip_no
    ,s.PART_part_no
    ,s.part_suffix
    ,s.position
    ,s.mark_marker_from
    ,s.mark_marker_to
    ,s.seg_segment_from
    ,s.seg_segment_to
    ,s.elevation_from
    ,s.elevation_to
    ,s.latitude_from
    ,s.latitude_to
    ,s.longitude_from
    ,s.longitude_to
    ,s.repl_model_excl_switch
    ,s.email_pm_sent
    ,s.LOC_last_order_loc
    ,s.LAST_order_yr
    ,s.LAST_order_no
    ,s.TASK_last_pm_service
    ,s.LOC_stock_loc
    ,s.comp_meter_upd
    ,s.sale_price_net
    ,s.sale_expenses
    ,s.sale_commission
    ,s.last_unique_id
    ,s.lease_expiration_meter
    ,s.last_pm_date_source
    ,s.eq_source
    ,s.position_link
    ,s.LINE_line_id
    ,s.COND_condition_id
    ,s.total_offset_from
    ,s.total_offset_to
    ,s.ACCT_cml_acct_code
    ,s.ACCT_ftk_acct_code
    ,s.ACCT_lab_acct_code
    ,s.ACCT_pts_acct_code
    ,s.ACCT_usg_acct_code
    ,s.REGCLASS_id
    ,s.COUNTY_id
    ,s.registration_value
    ,s.postal_code
    ,s.VRG_valuecode_id
    ,s.WAPROF_assign_profile_id
    ,s.license_issue_date
    ,s.purchase_year
    ,s.COUNTY_secondary_id
    ,s.SEG_boundary_segment
    ,s.COND_auto_condition_id
    ,s.last_cond_date
    ,s.last_autocond_date
    ,s.last_cond_source
    ,s.last_autocond_source
    ,s.USR_cond_lastuser
    ,s.USR_autocond_lastuser
    ,s.x_offset_from
    ,s.x_offset_to
    ,s.y_offset_from
    ,s.y_offset_to
    ,s.z_offset_from
    ,s.z_offset_to
    ,s.SHAPE_id
    ,s.BILLTYP_billingtype_id
    ,s.EMG_class_id
    ,s.ADR_address_code
    ,s.description_style1
    ,s.description_style2
    ,s.description_style3
    ,s.description_style4
    ,s.show_in_work_mgmt
    ,s.X_datetime_update
    ,s.ADR_transferee_code
    ,s.last_full_charge_meter
    ,s.last_full_charge_date
    ,s.electric_asset
    ,s.ACM_run_id
    ,s.ACM_model_unique_id
    ,s.ACM_component_id
    ,s.ACM_is_compliant
    ,s.ACM_require_for_service_error
    ,s.ACM_datetime_run
    ,s.DEPLOYMENT_STATUS_id
    ,s.event_id
    ,s.device_id
    ,s.loan_amount
    ,s.loan_duration_months
    ,s.loan_annual_interest_rate
    ,s.loan_start_date
    ,s.VEND_last_pm_vendor_no
    ,s.last_pm_cml_unique_id
    ,s.daily_depreciation_rate
    ,s.ETLProcessActivityID
    ,s.X_datetime_insert
	,'9999-12-31' end_date
FROM #eam_stg s
WHERE s.ETLProcessActivityID = @ETLProcessActivityID
AND s.processed = 'N'
AND s.is_updated = 1;

SET @ins = @ins + @@ROWCOUNT


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
		,'ltd_dw.eam.equipment_main_addl' 
		,'ltd_dw.eam.eq_main_addl_stage'
		,@SPROC  
		,ISNULL(@ins,0) 
		,ISNULL(@upd,0)
		,0
		,@sdt
		,SYSDATETIME()
	

UPDATE s
SET s.processed = 'Y'
FROM  eam.EQ_Main_addl_stage s	
WHERE s.ETLProcessActivityID = @ETLProcessActivityID
	AND Processed = 'N';


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
             ,@sub VARCHAR(255)

       SELECT @error = ERROR_NUMBER()
             ,@errsev = ERROR_SEVERITY()
             ,@message = ERROR_MESSAGE()
             ,@xstate = XACT_STATE()

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
