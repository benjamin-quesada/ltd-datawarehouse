SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






CREATE      PROCEDURE  [eam].[eq_main_addl_data_stage]
AS

/*-----------LTD_GLOSSARY---------------
CREATED BY:	Sopheap Suy
UPDATED DT: 10/07/2025 
purpose	:	pull data from eam EQ_MAIN_ADDL to eam.EQ_MAIN_ADDL_stage
use		:	exec eam.eq_main_addl_data_stage

purpose	 :  Add object activities on who, what, when call this object
			write this data to aud.object_activity table everytime it's called 

			
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

	SET @ETLProcessID =(SELECT ETLProcessID FROM Staging.dbo.ETLProcess WHERE ProcessName = 'eq_main_addl_stage' )


	--find previouly staged date time for this data
	SET @previous_start_time = (SELECT ISNULL(MAX(EndTime), '1950-01-01' ) FROM Staging.dbo.ETLProcessActivity WHERE ETLProcessID = @ETLProcessID )

	--SELECT @previous_start_time 

	--insert into dbo.ETLProcessActivity for record keeping
	EXEC Staging.dbo.ETLProcessActivity_insert @ETLProcessID --eq_main_addl_data_stage
 
	SET @ETLProcessActivityID = (SELECT MAX(ETLProcessActivityID ) FROM Staging.dbo.ETLProcessActivity WHERE ETLProcessID = @ETLProcessID )
	SELECT @ETLProcessActivityID


	INSERT INTO eam.EQ_MAIN_ADDL_stage
           (X_datetime_insert
           ,X_userid_insert
           ,DB_ACC
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
          -- ,WAPROF_assign_profile_id
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
		   ,row_id)

	SELECT X_datetime_insert
           ,X_userid_insert
           ,DB_ACC
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
           --,WAPROF_assign_profile_id -- this column no longer exists after eam upgrade
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
		   , @ETLProcessActivityID
		   , row_id
FROM [LTD-EAM].proto.emsdba.EQ_MAIN_ADDL
	WHERE (COALESCE(X_datetime_insert, GETDATE()) >= CAST(@previous_start_time AS DATE)
	OR COALESCE(X_datetime_update,GETDATE())  >= CAST(@previous_start_time AS DATE))

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
