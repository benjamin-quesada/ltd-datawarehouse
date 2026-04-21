SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE   PROCEDURE [eam].[NTD_Equipment_Snapshot_stage]
AS

/*-----------LTD_GLOSSARY---------------
CREATED BY:	Sopheap Suy
UPDATED DT: 10/10/2025 
purpose	:	pull data from eam RPT_NTD_Equipment to eam.NTD_Equipment_Snapshot
use		:	exec eam.NTD_Equipment_Snapshot_stage
		:	This querry is a portion of the view RPT_NTD_Equipment
			we want to keep monthly snapshot of this data to see data changes over time

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
			--@previous_start_time DATETIME,
			@cnt INT

	SET @ETLProcessID =(SELECT ETLProcessID FROM Staging.dbo.ETLProcess WHERE ProcessName = 'NTD_Equipment_Snapshot_stage' )

	--find previouly staged date time for this data
--	SET @previous_start_time = (SELECT ISNULL(MAX(EndTime), '1950-01-01' ) FROM Staging.dbo.ETLProcessActivity WHERE ETLProcessID = @ETLProcessID )

	--SELECT @previous_start_time 

	--insert into dbo.ETLProcessActivity for record keeping
	EXEC Staging.dbo.ETLProcessActivity_insert @ETLProcessID --eq_main_stage
 
	SET @ETLProcessActivityID = (SELECT MAX(ETLProcessActivityID ) FROM Staging.dbo.ETLProcessActivity WHERE ETLProcessID = @ETLProcessID )
	SELECT @ETLProcessActivityID

	--ALTER TABLE eam.eq_main_stage
	--ADD life_total_meter_1 int

INSERT INTO [eam].[NTD_Equipment_Snapshot]
           ([eq_equip_no]
           ,[CLA_MAIN_Meter]
           ,[CLA_MAIN_Maint]
           ,[CLA_MAIN_PM]
           ,[CLA_MAIN_Rental]
           ,[CLA_MAIN_Shop_Sch]
           ,[CLA_MAIN_STDS]
           ,[DPT_MAIN_department_name]
           ,[ECA_MAIN_category_Desc]
           ,[LOC_MAIN_current]
           ,[LOC_MAIN_Assigned_PM]
           ,[LOC_MAIN_Station]
           ,[LOC_MAIN_Stored]
           ,[LOC_MAIN_Repair]
           ,[eq_subsys_detail_manufacturer]
           ,[eq_subsys_detail_model]
           ,[PRI_MAIN_priority_rank]
           ,[PRS_MAIN_unit_is_active]
           ,[eq_capital_exp_life_months]
           ,[eq_subsys_detail_ID]
           ,[eq_subsys_detail_RV_ID]
           ,[eq_subsys_detail_Agency_Fleet_ID]
           ,[eq_subsys_detail_Mod_TOS]
           ,[eq_subsys_detail_Dedicated_Fleet]
           ,[eq_subsys_detail_Vehicle_Type_Svc]
           ,[eq_subsys_detail_Vehicle_Type]
           ,[eq_subsys_detail_Vehicle_Length]
           ,[eq_subsys_detail_Ownership]
           ,[eq_subsys_detail_ADA_Accessible]
           ,[eq_subsys_detail_Funding_Source]
           ,[eq_subsys_detail_Year_of_Manufacture]
           ,[eq_subsys_detail_Year_of_rebuild]
           ,[eq_subsys_detail_Emerg_Contigency_veh]
           ,[eq_subsys_detail_Meter_1_usage]
           ,[eq_subsys_detail_Meter_2_usage]
           ,[eq_subsys_detail_Seating_Capacity]
           ,[eq_subsys_detail_Standing_Capacity]
           ,[eq_subsys_detail_Multi_Modal]
           ,[eq_subsys_detail_Fleet_name]
           ,[eq_subsys_detail_Primary_Mode]
           ,[eq_subsys_detail_Primary_Mode_Rev]
           ,[eq_subsys_detail_Primary_Service]
           ,[eq_subsys_detail_Estimated_Cost]
           ,[eq_subsys_detail_Transit_Agency_Cap_Resp]
           ,[eq_subsys_detail_Year_Dollars_of_Est_Cost]
           ,[eq_subsys_detail_Fuel_Type]
           ,[eq_subsys_detail_Dual_Fuel_Type]
           ,[subsys_subsystem]
           ,[CALENDAR_ID]
           ,[CALENDAR_DATE]
           ,[record_create_date]
           ,[ETLProcessActivityID])
	SELECT m.EQ_equip_no AS "Equipment ID",
		--GETDATE() ,
       (
           SELECT ISNULL(description,'')
           FROM [LTD-EAM].proto.emsdba.CLA_MAIN c
           WHERE m.CLASS_class_meter = c.CLASS_class_code
       ) AS "Class Desc - Meter",
       (
           SELECT ISNULL(description,'')
           FROM [LTD-EAM].proto.emsdba.CLA_MAIN c
           WHERE m.CLASS_class_maint = c.CLASS_class_code
       ) AS "Class Desc - Maint",
       (
           SELECT ISNULL(description,'')
           FROM [LTD-EAM].proto.emsdba.CLA_MAIN c
           WHERE m.CLASS_class_pm = c.CLASS_class_code
       ) AS "Class Desc - PM",
       (
           SELECT ISNULL(description,'')
           FROM [LTD-EAM].proto.emsdba.CLA_MAIN c
           WHERE m.CLASS_class_rental = c.CLASS_class_code
       ) AS "Class Desc - Rental",
       (
           SELECT ISNULL(description,'')
           FROM [LTD-EAM].proto.emsdba.CLA_MAIN c
           WHERE m.CLASS_class_shop_sch = c.CLASS_class_code
       ) AS "Class Desc - Shop Sch",
       (
           SELECT ISNULL(description,'')
           FROM [LTD-EAM].proto.emsdba.CLA_MAIN c
           WHERE m.CLASS_class_stds = c.CLASS_class_code
       ) AS "Class Desc - STDS",
       (
           SELECT ISNULL(name,'')
           FROM [LTD-EAM].proto.emsdba.DPT_MAIN d
           WHERE m.DEPT_dept_code = d.DEPT_dept_code
       ) AS "Department Name",
       (
           SELECT ISNULL(name,'')
           FROM [LTD-EAM].proto.emsdba.ECA_MAIN e
           WHERE e.EQCAT_equip_category = m.EQCAT_equip_category
       ) AS "Category Desc",
       (
           SELECT ISNULL(name,'')
           FROM [LTD-EAM].proto.emsdba.LOC_MAIN l
           WHERE m.LOC_current_loc = l.LOC_loc_code
       ) AS "Location Name - Current",
       (
           SELECT ISNULL(name,'')
           FROM [LTD-EAM].proto.emsdba.LOC_MAIN l
           WHERE m.LOC_assign_pm_loc = l.LOC_loc_code
       ) AS "Location Name - ASsigned PM",
       (
           SELECT ISNULL(name,'')
           FROM [LTD-EAM].proto.emsdba.LOC_MAIN l
           WHERE m.LOC_station_loc = l.LOC_loc_code
       ) AS "Location Name - Station",
       (
           SELECT ISNULL(name,'')
           FROM [LTD-EAM].proto.emsdba.LOC_MAIN l
           WHERE m.LOC_stored_loc = l.LOC_loc_code
       ) AS "Location Name - Stored",
       (
           SELECT ISNULL(name,'')
           FROM [LTD-EAM].proto.emsdba.LOC_MAIN l
           WHERE m.LOC_assign_repr_loc = l.LOC_loc_code
       ) AS "Location Name - Repair",
       (
           SELECT ISNULL(d.text_value,'')
           FROM [LTD-EAM].proto.emsdba.eq_subsys_detail d
           WHERE d.EQ_equip_no = m.EQ_equip_no
                 AND subsys_subsystem = 'NTD REVENUE VEHICLE'
                 AND SUBPROP_SUBSYS_PROP = 'MANUFACTURER'
       ) AS "Manufacturer",
       (
           SELECT ISNULL(d.text_value,'')
           FROM [LTD-EAM].proto.emsdba.eq_subsys_detail d
           WHERE d.EQ_equip_no = m.EQ_equip_no
                 AND subsys_subsystem = 'NTD REVENUE VEHICLE'
                 AND SUBPROP_SUBSYS_PROP = 'MODEL NUMBER'
       ) AS "Model",
       (
           SELECT ISNULL(priority_rank, 0)
           FROM [LTD-EAM].proto.emsdba.PRI_MAIN p
           WHERE m.PRI_shop_priority = p.PRI_priority_code
       ) AS "Priority Rank",
       (
           SELECT ISNULL(unit_is_active,'')
           FROM [LTD-EAM].proto.emsdba.PRS_MAIN p
           WHERE m.PROCST_proc_status = p.PROCST_proc_status
       ) AS "Unit Is Active",
       (
           SELECT ISNULL(exp_life_months,0)
           FROM [LTD-EAM].proto.emsdba.eq_capital c
           WHERE m.EQ_equip_no = c.EQ_equip_no
       ) AS "Expected Life Months",
       (
           SELECT ISNULL(d.text_value,'')
           FROM [LTD-EAM].proto.emsdba.eq_subsys_detail d
           WHERE d.EQ_equip_no = m.EQ_equip_no
                 AND subsys_subsystem = 'NTD SERVICE VEHICLE'
                 AND SUBPROP_SUBSYS_PROP = 'ID'
       ) AS "ID",
       (
           SELECT ISNULL(d.text_value,'')
           FROM [LTD-EAM].proto.emsdba.eq_subsys_detail d
           WHERE d.EQ_equip_no = m.EQ_equip_no
                 AND subsys_subsystem = 'NTD REVENUE VEHICLE'
                 AND SUBPROP_SUBSYS_PROP = 'RVID'
       ) AS "RV ID",
       (
           SELECT ISNULL(d.text_value,'')
           FROM [LTD-EAM].proto.emsdba.eq_subsys_detail d
           WHERE d.EQ_equip_no = m.EQ_equip_no
                 AND subsys_subsystem IN ( 'NTD REVENUE VEHICLE', 'NTD SERVICE VEHICLE' )
                 AND SUBPROP_SUBSYS_PROP = 'AGENCY FLEET ID'
       ) AS "Agency Fleet Id",
       (
           SELECT ISNULL(d.text_value,'')
           FROM [LTD-EAM].proto.emsdba.eq_subsys_detail d
           WHERE d.EQ_equip_no = m.EQ_equip_no
                 AND subsys_subsystem = 'NTD REVENUE VEHICLE'
                 AND subprop_subsys_prop = 'MODE/TOS'
       ) AS "Mode/TOS",
       (
           SELECT ISNULL(d.text_value,'')
           FROM [LTD-EAM].proto.emsdba.eq_subsys_detail d
           WHERE d.EQ_equip_no = m.EQ_equip_no
                 AND subsys_subsystem = 'NTD REVENUE VEHICLE'
                 AND SUBPROP_SUBSYS_PROP = 'DEDICATED FLEET'
       ) AS "Dedicated Fleet",
       (
           SELECT ISNULL(d.text_value,'')
           FROM [LTD-EAM].proto.emsdba.eq_subsys_detail d
           WHERE d.EQ_equip_no = m.EQ_equip_no
                 AND subsys_subsystem = 'NTD SERVICE VEHICLE'
                 AND SUBPROP_SUBSYS_PROP = 'VEHICLE TYPE'
       ) AS "Vehicle Type Svc",
       (
           SELECT ISNULL(d.text_value,'')
           FROM [LTD-EAM].proto.emsdba.eq_subsys_detail d
           WHERE d.EQ_equip_no = m.EQ_equip_no
                 AND subsys_subsystem = 'NTD REVENUE VEHICLE'
                 AND SUBPROP_SUBSYS_PROP = 'VEHICLE TYPE'
       ) AS "Vehicle Type",
       (
           SELECT ISNULL(d.numeric_value,0)
           FROM [LTD-EAM].proto.emsdba.eq_subsys_detail d
           WHERE d.EQ_equip_no = m.EQ_equip_no
                 AND subsys_subsystem = 'NTD REVENUE VEHICLE'
                 AND SUBPROP_SUBSYS_PROP = 'VEHICLE LENGTH'
       ) AS "Vehicle Length",
       (
           SELECT ISNULL(d.text_value,'')
           FROM [LTD-EAM].proto.emsdba.eq_subsys_detail d
           WHERE d.EQ_equip_no = m.EQ_equip_no
                 AND subsys_subsystem = 'NTD REVENUE VEHICLE'
                 AND SUBPROP_SUBSYS_PROP = 'OWNERSHIP'
       ) AS "Ownership",
       (
           SELECT ISNULL(d.text_value,'')
           FROM [LTD-EAM].proto.emsdba.eq_subsys_detail d
           WHERE d.EQ_equip_no = m.EQ_equip_no
                 AND subsys_subsystem = 'NTD REVENUE VEHICLE'
                 AND SUBPROP_SUBSYS_PROP = 'ADA ACCESSIBLE'
       ) AS "ADA Accessible",
       (
           SELECT ISNULL(d.text_value,'')
           FROM [LTD-EAM].proto.emsdba.eq_subsys_detail d
           WHERE d.EQ_equip_no = m.EQ_equip_no
                 AND subsys_subsystem = 'NTD REVENUE VEHICLE'
                 AND SUBPROP_SUBSYS_PROP = 'FUNDING SOURCE'
       ) AS "Funding Source",
       (
           SELECT ISNULL(d.text_value,'')
           FROM [LTD-EAM].proto.emsdba.eq_subsys_detail d
           WHERE d.EQ_equip_no = m.EQ_equip_no
                 AND subsys_subsystem = 'NTD REVENUE VEHICLE'
                 AND SUBPROP_SUBSYS_PROP = 'YEAR OF MANUFACTURER'
       ) AS "Year of Manufacture",
       (
           SELECT ISNULL(d.text_value,'')
           FROM [LTD-EAM].proto.emsdba.eq_subsys_detail d
           WHERE d.EQ_equip_no = m.EQ_equip_no
                 AND subsys_subsystem = 'NTD REVENUE VEHICLE'
                 AND SUBPROP_SUBSYS_PROP = 'YEAR OF REBUILD'
       ) AS "Year of Rebuild",
       (
           SELECT ISNULL(d.text_value,'')
           FROM [LTD-EAM].proto.emsdba.eq_subsys_detail d
           WHERE d.EQ_equip_no = m.EQ_equip_no
                 AND subsys_subsystem = 'NTD REVENUE VEHICLE'
                 AND SUBPROP_SUBSYS_PROP = 'EMERGENCY CONTINGENCY VEHICLE'
       ) AS "Emerg Contingency Veh",
       (
           SELECT ISNULL(SUM(d.meter_1_usage),0)
           FROM [LTD-EAM].proto.emsdba.eq_cost_data d
           WHERE d.EQ_equip_no = m.EQ_equip_no
                 AND ((Cost_year * 100) + Cost_Month) >= (YEAR(GETDATE() - 365) * 100) + MONTH(GETDATE())
       ) AS "Meter 1 Usage",
       (
           SELECT ISNULL(SUM(d.meter_2_usage),0)
           FROM [LTD-EAM].proto.emsdba.eq_cost_data d
           WHERE d.EQ_equip_no = m.EQ_equip_no
                 AND ((Cost_year * 100) + Cost_Month) >= (YEAR(GETDATE() - 365) * 100) + MONTH(GETDATE())
       ) AS "Meter 2 Usage",
       (
           SELECT ISNULL(d.numeric_value,0)
           FROM [LTD-EAM].proto.emsdba.eq_subsys_detail d
           WHERE d.EQ_equip_no = m.EQ_equip_no
                 AND subsys_subsystem = 'NTD REVENUE VEHICLE'
                 AND SUBPROP_SUBSYS_PROP = 'SEATING CAPACITY'
       ) AS "Seating Capacity",
       (
           SELECT ISNULL(d.numeric_value,0)
           FROM [LTD-EAM].proto.emsdba.eq_subsys_detail d
           WHERE d.EQ_equip_no = m.EQ_equip_no
                 AND subsys_subsystem = 'NTD REVENUE VEHICLE'
                 AND SUBPROP_SUBSYS_PROP = 'STANDING CAPACITY'
       ) AS "Standing Capacity",
       (
           SELECT COUNT(*)
           FROM [LTD-EAM].proto.emsdba.eq_subsys_detail d
           WHERE d.EQ_equip_no = m.EQ_equip_no
                 AND subsys_subsystem = 'NTD REVENUE VEHICLE'
                 AND subprop_subsys_prop = 'MODE/TOS'
       ) AS "MultiModal",
       (
           SELECT ISNULL(d.text_value,'')
           FROM [LTD-EAM].proto.emsdba.eq_subsys_detail d
           WHERE d.EQ_equip_no = m.EQ_equip_no
                 AND subsys_subsystem = 'NTD SERVICE VEHICLE'
                 AND SUBPROP_SUBSYS_PROP = 'FLEET NAME'
       ) AS "Fleet Name",
       (
           SELECT ISNULL(d.text_value,'')
           FROM [LTD-EAM].proto.emsdba.eq_subsys_detail d
           WHERE d.EQ_equip_no = m.EQ_equip_no
                 AND subsys_subsystem = 'NTD SERVICE VEHICLE'
                 AND SUBPROP_SUBSYS_PROP = 'PRIMARY MODE'
       ) AS "Primary Mode",
       (
           SELECT ISNULL(d.text_value,'')
           FROM [LTD-EAM].proto.emsdba.eq_subsys_detail d
           WHERE d.EQ_equip_no = m.EQ_equip_no
                 AND subsys_subsystem = 'NTD REVENUE VEHICLE'
                 AND SUBPROP_SUBSYS_PROP = 'PRIMARY MODE'
       ) AS "Primary Mode Rev",
       (
           SELECT ISNULL(d.text_value,'')
           FROM [LTD-EAM].proto.emsdba.eq_subsys_detail d
           WHERE d.EQ_equip_no = m.EQ_equip_no
                 AND subsys_subsystem = 'NTD REVENUE VEHICLE'
                 AND SUBPROP_SUBSYS_PROP = 'PRIMARY SERVICE'
       ) AS "Primary Service",
       (
           SELECT ISNULL(d.text_value,'')
           FROM [LTD-EAM].proto.emsdba.eq_subsys_detail d
           WHERE d.EQ_equip_no = m.EQ_equip_no
                 AND subsys_subsystem = 'NTD SERVICE VEHICLE'
                 AND SUBPROP_SUBSYS_PROP = 'ESTIMATED COST'
       ) AS "Estimated Cost",
       (
           SELECT ISNULL(d.numeric_value,0)
           FROM [LTD-EAM].proto.emsdba.eq_subsys_detail d
           WHERE d.EQ_equip_no = m.EQ_equip_no
                 AND subsys_subsystem = 'NTD SERVICE VEHICLE'
                 AND SUBPROP_SUBSYS_PROP = 'CAPITAL RESPONSIBILITY (PCT)'
       ) AS "Transit Agency Cap Resp %",
       (
           SELECT ISNULL(d.text_value,'')
           FROM [LTD-EAM].proto.emsdba.eq_subsys_detail d
           WHERE d.EQ_equip_no = m.EQ_equip_no
                 AND subsys_subsystem = 'NTD SERVICE VEHICLE'
                 AND SUBPROP_SUBSYS_PROP = 'YEAR OF ESTIMATED COST'
       ) AS "Year Dollars of Est Cost",
       (
           SELECT ISNULL(d.text_value,'')
           FROM [LTD-EAM].proto.emsdba.eq_subsys_detail d
           WHERE d.EQ_equip_no = m.EQ_equip_no
                 AND subsys_subsystem = 'NTD REVENUE VEHICLE'
                 AND SUBPROP_SUBSYS_PROP = 'FUEL TYPE'
       ) AS "Fuel Type",
       (
           SELECT ISNULL(d.text_value,'')
           FROM [LTD-EAM].proto.emsdba.eq_subsys_detail d
           WHERE d.EQ_equip_no = m.EQ_equip_no
                 AND subsys_subsystem = 'NTD REVENUE VEHICLE'
                 AND SUBPROP_SUBSYS_PROP = 'DUAL FUEL TYPE'
       ) AS "Dual Fuel Type",
       s.subsys_subsystem AS "Subsystem",
	   c.calendar_id,
	   c.CALENDAR_DATE
	   , GETDATE() record_create_date
	   , @ETLProcessActivityID ETLProcessActivityID
	FROM [LTD-EAM].proto.emsdba.EQ_MAIN m
	INNER JOIN [LTD-EAM].proto.emsdba.EQ_SUBSYS s
		ON m.EQ_equip_no = s.EQ_equip_no
		  AND s.subsys_subsystem IN ( 'NTD REVENUE VEHICLE', 'NTD SERVICE VEHICLE' )
	INNER JOIN tm.DW_CALENDAR c
	ON c.CALENDAR_DATE = CAST(GETDATE() AS DATE)
		


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
