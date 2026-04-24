SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [eam].[get_eq_cost_data]
AS
/*

CREATED 20220225
AUTHOR  B. EICHBERGER
PURPOSE To collect incremental changes to EQ Cost Data every 6 hours
		Build a DW Copy of Cost Data for reporting/SBP/Etc.
USE		exec eam.get_eq_cost_data

------------------LTD_GLOSSARY---------------
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

BEGIN TRY

DECLARE @OutputTbl TABLE (ActionName varchar(32))
DECLARE @startdt datetime = sysdatetime()




CREATE TABLE #EAM_COST_STAGE (
CALENDAR_ID [INT] NULL,
[TIME_SPM] [INT] NOT NULL,
[DATETIME_INSERTED_EAM] [DATETIME2](7) NULL,
[EQ_EQUIP_NO] [VARCHAR](20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[COST_YEAR] [INT] NULL,
[COST_MONTH] [INT] NULL,
[METER_1_USAGE] [INT] NULL,
[METER_2_USAGE] [INT] NULL,
[FUEL_QTY] [NUMERIC](14, 3) NULL,
[FUEL_COST] [NUMERIC](12, 2) NULL,
[CNG_QTY] [NUMERIC](12, 1) NULL,
[CNG_COST] [NUMERIC](12, 2) NULL,
[OIL_QTY] [NUMERIC](12, 1) NULL,
[OIL_COST] [NUMERIC](12, 2) NULL,
[MISC_COST] [NUMERIC](12, 2) NULL,
[MISC_PARTS_COST] [NUMERIC](12, 2) NULL,
[REPAIR_LABOR_HRS] [NUMERIC](13, 2) NULL,
[REPAIR_LABOR_COST] [NUMERIC](12, 2) NULL,
[REPAIR_PARTS_COST] [NUMERIC](12, 2) NULL,
[REPAIR_TASKS] [INT] NULL,
[PM_LABOR_HRS] [NUMERIC](13, 2) NULL,
[PM_LABOR_COST] [NUMERIC](12, 2) NULL,
[PM_PARTS_COST] [NUMERIC](12, 2) NULL,
[PM_SERVICES] [INT] NULL,
[DEPREC_COST] [NUMERIC](12, 2) NULL,
[RENTAL_REVENUE] [NUMERIC](12, 2) NULL,
[LEASE_COST] [NUMERIC](12, 2) NULL,
[DOWNTIME_HRS_DEPT] [NUMERIC](13, 2) NULL,
[DOWNTIME_HRS_SHOP] [NUMERIC](13, 2) NULL,
[DELAY_HRS] [NUMERIC](13, 2) NULL,
[WARRANTY_COST_RECOV] [NUMERIC](12, 2) NULL,
[CAPITAL_COST] [NUMERIC](12, 2) NULL,
[FIXED_MONTHLY_COST] [NUMERIC](12, 2) NULL,
[FIXED_INSURANCE_COST] [NUMERIC](12, 2) NULL,
[FIXED_REPLACE_COST] [NUMERIC](12, 2) NULL,
[FIXED_LICENSING_COST] [NUMERIC](12, 2) NULL,
[FIXED_COST_1] [NUMERIC](12, 2) NULL,
[FIXED_COST_2] [NUMERIC](12, 2) NULL,
[FIXED_COST_3] [NUMERIC](12, 2) NULL,
[FEE] [NUMERIC](12, 2) NULL,
[LICENSE] [NUMERIC](12, 2) NULL,
[USER_REPR_LABOR_HRS] [NUMERIC](12, 1) NULL,
[USER_REPR_LABOR_COST] [NUMERIC](12, 2) NULL,
[USER_REPR_PARTS_COST] [NUMERIC](12, 2) NULL,
[USER_REPR_TASKS] [INT] NULL,
[USER_CAUS_DOWNT_DEPT] [NUMERIC](12, 1) NULL,
[USER_CAUS_DOWNT_SHOP] [NUMERIC](12, 1) NULL,
[INSURANCE_RECOVERY] [NUMERIC](12, 2) NULL,
[AUTO_TRANS_FL_QTY] [NUMERIC](12, 1) NULL,
[AUTO_TRANS_FL_COST] [NUMERIC](12, 2) NULL,
[ANTIFREEZE_FL_QTY] [NUMERIC](12, 1) NULL,
[ANTIFREEZE_FL_COST] [NUMERIC](12, 2) NULL,
[HYDRAULIC_FL_QTY] [NUMERIC](12, 1) NULL,
[HYDRAULIC_FL_COST] [NUMERIC](12, 2) NULL,
[BRAKE_FL_QTY] [NUMERIC](12, 1) NULL,
[BRAKE_FL_COST] [NUMERIC](12, 2) NULL,
[GEAR_OIL_QTY] [NUMERIC](12, 1) NULL,
[GEAR_OIL_COST] [NUMERIC](12, 2) NULL,
[AIR_COND_FL_QTY] [NUMERIC](12, 1) NULL,
[AIR_COND_FL_COST] [NUMERIC](12, 2) NULL,
[TIRE_COST] [NUMERIC](12, 2) NULL,
[METER_1_EOM] [INT] NULL,
[METER_2_EOM] [INT] NULL,
[EOM_RUN_DATE] [DATETIME] NULL,
[METER_POSTING_FLAG] [CHAR](1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[USAGE_TICKET_FLAG] [CHAR](1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TRIGGER_MODE] [VARCHAR](9) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CORE_COST_RECOV] [NUMERIC](12, 2) NULL,
[LOC_LOC_CODE] [VARCHAR](10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DEPT_DEPT_CODE] [VARCHAR](10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[EQ_MAIN_EQUIP_NO] [VARCHAR](20) NULL,
[METER_1_TYPE] [VARCHAR](10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[METER_2_TYPE] [VARCHAR](10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[REPAIR_CML_LABOR_COST] [NUMERIC](12, 2) NULL,
[REPAIR_CML_PARTS_COST] [NUMERIC](12, 2) NULL,
[PM_CML_LABOR_COST] [NUMERIC](12, 2) NULL,
[PM_CML_PARTS_COST] [NUMERIC](12, 2) NULL,
[USER_REPR_CML_LABOR_COST] [NUMERIC](12, 2) NULL,
[USER_REPR_CML_PARTS_COST] [NUMERIC](12, 2) NULL,
[ACCT_EOM_ACCT_CODE] [VARCHAR](30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[REPAIR_EQUIP_COST] [NUMERIC](12, 2) NULL,
[PM_EQUIP_COST] [NUMERIC](12, 2) NULL,
[USER_REPR_EQUIP_COST] [NUMERIC](12, 2) NULL,
[ELECTRIC_QTY] [NUMERIC](14, 3) NULL,
[ELECTRIC_COST] [NUMERIC](12, 2) NULL);
INSERT #EAM_COST_STAGE (CALENDAR_ID,
	TIME_SPM,
	DATETIME_INSERTED_EAM,
	EQ_EQUIP_NO,
	COST_YEAR,
	COST_MONTH,
	METER_1_USAGE,
	METER_2_USAGE,
	FUEL_QTY,
	FUEL_COST,
	CNG_QTY,
	CNG_COST,
	OIL_QTY,
	OIL_COST,
	MISC_COST,
	MISC_PARTS_COST,
	REPAIR_LABOR_HRS,
	REPAIR_LABOR_COST,
	REPAIR_PARTS_COST,
	REPAIR_TASKS,
	PM_LABOR_HRS,
	PM_LABOR_COST,
	PM_PARTS_COST,
	PM_SERVICES,
	DEPREC_COST,
	RENTAL_REVENUE,
	LEASE_COST,
	DOWNTIME_HRS_DEPT,
	DOWNTIME_HRS_SHOP,
	DELAY_HRS,
	WARRANTY_COST_RECOV,
	CAPITAL_COST,
	FIXED_MONTHLY_COST,
	FIXED_INSURANCE_COST,
	FIXED_REPLACE_COST,
	FIXED_LICENSING_COST,
	FIXED_COST_1,
	FIXED_COST_2,
	FIXED_COST_3,
	FEE,
	LICENSE,
	USER_REPR_LABOR_HRS,
	USER_REPR_LABOR_COST,
	USER_REPR_PARTS_COST,
	USER_REPR_TASKS,
	USER_CAUS_DOWNT_DEPT,
	USER_CAUS_DOWNT_SHOP,
	INSURANCE_RECOVERY,
	AUTO_TRANS_FL_QTY,
	AUTO_TRANS_FL_COST,
	ANTIFREEZE_FL_QTY,
	ANTIFREEZE_FL_COST,
	HYDRAULIC_FL_QTY,
	HYDRAULIC_FL_COST,
	BRAKE_FL_QTY,
	BRAKE_FL_COST,
	GEAR_OIL_QTY,
	GEAR_OIL_COST,
	AIR_COND_FL_QTY,
	AIR_COND_FL_COST,
	TIRE_COST,
	METER_1_EOM,
	METER_2_EOM,
	EOM_RUN_DATE,
	METER_POSTING_FLAG,
	USAGE_TICKET_FLAG,
	TRIGGER_MODE,
	CORE_COST_RECOV,
	LOC_LOC_CODE,
	DEPT_DEPT_CODE,
	EQ_MAIN_EQUIP_NO,
	METER_1_TYPE,
	METER_2_TYPE,
	REPAIR_CML_LABOR_COST,
	REPAIR_CML_PARTS_COST,
	PM_CML_LABOR_COST,
	PM_CML_PARTS_COST,
	USER_REPR_CML_LABOR_COST,
	USER_REPR_CML_PARTS_COST,
	ACCT_EOM_ACCT_CODE,
	REPAIR_EQUIP_COST,
	PM_EQUIP_COST,
	USER_REPR_EQUIP_COST,
	ELECTRIC_QTY,
	ELECTRIC_COST)
SELECT CAST(CONVERT(VARCHAR(32), v.X_DATETIME_INSERT, 112) AS INT) + 100000000 AS CALENDAR_ID,
       [dbo].[F_DATE_TO_SEC_SINCE_MIDNITE](v.X_DATETIME_INSERT) TIME_SPM,
       v.X_DATETIME_INSERT,
       v.[EQ_EQUIP_NO],
       v.[COST_YEAR],
       v.[COST_MONTH],
       v.[METER_1_USAGE],
       v.[METER_2_USAGE],
       v.[FUEL_QTY],
       v.[FUEL_COST],
       v.[CNG_QTY],
       v.[CNG_COST],
       v.[OIL_QTY],
       v.[OIL_COST],
       v.[MISC_COST],
       v.[MISC_PARTS_COST],
       v.[REPAIR_LABOR_HRS],
       v.[REPAIR_LABOR_COST],
       v.[REPAIR_PARTS_COST],
       v.[REPAIR_TASKS],
       v.[PM_LABOR_HRS],
       v.[PM_LABOR_COST],
       v.[PM_PARTS_COST],
       v.[PM_SERVICES],
       v.[DEPREC_COST],
       v.[RENTAL_REVENUE],
       v.[LEASE_COST],
       v.[DOWNTIME_HRS_DEPT],
       v.[DOWNTIME_HRS_SHOP],
       v.[DELAY_HRS],
       v.[WARRANTY_COST_RECOV],
       v.[CAPITAL_COST],
       v.[FIXED_MONTHLY_COST],
       v.[FIXED_INSURANCE_COST],
       v.[FIXED_REPLACE_COST],
       v.[FIXED_LICENSING_COST],
       v.[FIXED_COST_1],
       v.[FIXED_COST_2],
       v.[FIXED_COST_3],
       v.[FEE],
       v.[LICENSE],
       v.[USER_REPR_LABOR_HRS],
       v.[USER_REPR_LABOR_COST],
       v.[USER_REPR_PARTS_COST],
       v.[USER_REPR_TASKS],
       v.[USER_CAUS_DOWNT_DEPT],
       v.[USER_CAUS_DOWNT_SHOP],
       v.[INSURANCE_RECOVERY],
       v.[AUTO_TRANS_FL_QTY],
       v.[AUTO_TRANS_FL_COST],
       v.[ANTIFREEZE_FL_QTY],
       v.[ANTIFREEZE_FL_COST],
       v.[HYDRAULIC_FL_QTY],
       v.[HYDRAULIC_FL_COST],
       v.[BRAKE_FL_QTY],
       v.[BRAKE_FL_COST],
       v.[GEAR_OIL_QTY],
       v.[GEAR_OIL_COST],
       v.[AIR_COND_FL_QTY],
       v.[AIR_COND_FL_COST],
       v.[TIRE_COST],
       v.[METER_1_EOM],
       v.[METER_2_EOM],
       v.[EOM_RUN_DATE],
       v.[METER_POSTING_FLAG],
       v.[USAGE_TICKET_FLAG],
       v.[TRIGGER_MODE],
       v.[CORE_COST_RECOV],
       v.[LOC_LOC_CODE],
       v.[DEPT_DEPT_CODE],
       v.[EQ_MAIN_EQUIP_NO],
       v.[METER_1_TYPE],
       v.[METER_2_TYPE],
       v.[REPAIR_CML_LABOR_COST],
       v.[REPAIR_CML_PARTS_COST],
       v.[PM_CML_LABOR_COST],
       v.[PM_CML_PARTS_COST],
       v.[USER_REPR_CML_LABOR_COST],
       v.[USER_REPR_CML_PARTS_COST],
       v.[ACCT_EOM_ACCT_CODE],
       v.[REPAIR_EQUIP_COST],
       v.[PM_EQUIP_COST],
       v.[USER_REPR_EQUIP_COST],
       v.[ELECTRIC_QTY],
       v.[ELECTRIC_COST]
  FROM [LTD-EAM].[proto].[emsdba].[EQ_COST_DATA_VIEW] v;


MERGE -- truncate table 
eam.EQ_COST_DATA t
USING #EAM_COST_STAGE s
   ON s.EQ_EQUIP_NO COLLATE SQL_Latin1_General_CP1_CI_AS = t.EQ_EQUIP_NO COLLATE SQL_Latin1_General_CP1_CI_AS
  AND s.CALENDAR_ID = t.CALENDAR_ID
  AND s.[DATETIME_INSERTED_EAM] = t.[DATETIME_INSERTED_EAM]
  AND s.COST_YEAR = t.COST_YEAR
  AND s.COST_MONTH = t.COST_MONTH
 WHEN NOT MATCHED BY TARGET THEN
    INSERT ([CALENDAR_ID],
            TIME_SPM,
            [DATETIME_INSERTED_EAM],
            [EQ_EQUIP_NO],
            [COST_YEAR],
            [COST_MONTH],
            [METER_1_USAGE],
            [METER_2_USAGE],
            [FUEL_QTY],
            [FUEL_COST],
            [CNG_QTY],
            [CNG_COST],
            [OIL_QTY],
            [OIL_COST],
            [MISC_COST],
            [MISC_PARTS_COST],
            [REPAIR_LABOR_HRS],
            [REPAIR_LABOR_COST],
            [REPAIR_PARTS_COST],
            [REPAIR_TASKS],
            [PM_LABOR_HRS],
            [PM_LABOR_COST],
            [PM_PARTS_COST],
            [PM_SERVICES],
            [DEPREC_COST],
            [RENTAL_REVENUE],
            [LEASE_COST],
            [DOWNTIME_HRS_DEPT],
            [DOWNTIME_HRS_SHOP],
            [DELAY_HRS],
            [WARRANTY_COST_RECOV],
            [CAPITAL_COST],
            [FIXED_MONTHLY_COST],
            [FIXED_INSURANCE_COST],
            [FIXED_REPLACE_COST],
            [FIXED_LICENSING_COST],
            [FIXED_COST_1],
            [FIXED_COST_2],
            [FIXED_COST_3],
            [FEE],
            [LICENSE],
            [USER_REPR_LABOR_HRS],
            [USER_REPR_LABOR_COST],
            [USER_REPR_PARTS_COST],
            [USER_REPR_TASKS],
            [USER_CAUS_DOWNT_DEPT],
            [USER_CAUS_DOWNT_SHOP],
            [INSURANCE_RECOVERY],
            [AUTO_TRANS_FL_QTY],
            [AUTO_TRANS_FL_COST],
            [ANTIFREEZE_FL_QTY],
            [ANTIFREEZE_FL_COST],
            [HYDRAULIC_FL_QTY],
            [HYDRAULIC_FL_COST],
            [BRAKE_FL_QTY],
            [BRAKE_FL_COST],
            [GEAR_OIL_QTY],
            [GEAR_OIL_COST],
            [AIR_COND_FL_QTY],
            [AIR_COND_FL_COST],
            [TIRE_COST],
            [METER_1_EOM],
            [METER_2_EOM],
            [EOM_RUN_DATE],
            [METER_POSTING_FLAG],
            [USAGE_TICKET_FLAG],
            [TRIGGER_MODE],
            [CORE_COST_RECOV],
            [LOC_LOC_CODE],
            [DEPT_DEPT_CODE],
            [EQ_MAIN_EQUIP_NO],
            [METER_1_TYPE],
            [METER_2_TYPE],
            [REPAIR_CML_LABOR_COST],
            [REPAIR_CML_PARTS_COST],
            [PM_CML_LABOR_COST],
            [PM_CML_PARTS_COST],
            [USER_REPR_CML_LABOR_COST],
            [USER_REPR_CML_PARTS_COST],
            [ACCT_EOM_ACCT_CODE],
            [REPAIR_EQUIP_COST],
            [PM_EQUIP_COST],
            [USER_REPR_EQUIP_COST],
            [ELECTRIC_QTY],
            [ELECTRIC_COST])
    VALUES (s.[CALENDAR_ID], s.[TIME_SPM], s.[DATETIME_INSERTED_EAM]
		  , s.[EQ_EQUIP_NO] COLLATE SQL_Latin1_General_CP1_CI_AS, s.[COST_YEAR], s.[COST_MONTH],
            s.[METER_1_USAGE], s.[METER_2_USAGE], s.[FUEL_QTY], s.[FUEL_COST], s.[CNG_QTY], s.[CNG_COST], s.[OIL_QTY],
            s.[OIL_COST], s.[MISC_COST], s.[MISC_PARTS_COST], s.[REPAIR_LABOR_HRS], s.[REPAIR_LABOR_COST],
            s.[REPAIR_PARTS_COST], s.[REPAIR_TASKS], s.[PM_LABOR_HRS], s.[PM_LABOR_COST], s.[PM_PARTS_COST],
            s.[PM_SERVICES], s.[DEPREC_COST], s.[RENTAL_REVENUE], s.[LEASE_COST], s.[DOWNTIME_HRS_DEPT],
            s.[DOWNTIME_HRS_SHOP], s.[DELAY_HRS], s.[WARRANTY_COST_RECOV], s.[CAPITAL_COST], s.[FIXED_MONTHLY_COST],
            s.[FIXED_INSURANCE_COST], s.[FIXED_REPLACE_COST], s.[FIXED_LICENSING_COST], s.[FIXED_COST_1],
            s.[FIXED_COST_2], s.[FIXED_COST_3], s.[FEE], s.[LICENSE], s.[USER_REPR_LABOR_HRS],
            s.[USER_REPR_LABOR_COST], s.[USER_REPR_PARTS_COST], s.[USER_REPR_TASKS], s.[USER_CAUS_DOWNT_DEPT],
            s.[USER_CAUS_DOWNT_SHOP], s.[INSURANCE_RECOVERY], s.[AUTO_TRANS_FL_QTY], s.[AUTO_TRANS_FL_COST],
            s.[ANTIFREEZE_FL_QTY], s.[ANTIFREEZE_FL_COST], s.[HYDRAULIC_FL_QTY], s.[HYDRAULIC_FL_COST],
            s.[BRAKE_FL_QTY], s.[BRAKE_FL_COST], s.[GEAR_OIL_QTY], s.[GEAR_OIL_COST], s.[AIR_COND_FL_QTY],
            s.[AIR_COND_FL_COST], s.[TIRE_COST], s.[METER_1_EOM], s.[METER_2_EOM], s.[EOM_RUN_DATE],
            s.[METER_POSTING_FLAG] COLLATE SQL_Latin1_General_CP1_CI_AS
			, s.[USAGE_TICKET_FLAG] COLLATE SQL_Latin1_General_CP1_CI_AS
			, s.[TRIGGER_MODE] COLLATE SQL_Latin1_General_CP1_CI_AS
			, s.[CORE_COST_RECOV], s.[LOC_LOC_CODE] COLLATE SQL_Latin1_General_CP1_CI_AS,
            s.[DEPT_DEPT_CODE] COLLATE SQL_Latin1_General_CP1_CI_AS
			, s.[EQ_MAIN_EQUIP_NO] COLLATE SQL_Latin1_General_CP1_CI_AS
			, s.[METER_1_TYPE] COLLATE SQL_Latin1_General_CP1_CI_AS
			, s.[METER_2_TYPE] COLLATE SQL_Latin1_General_CP1_CI_AS
			, s.[REPAIR_CML_LABOR_COST],
            s.[REPAIR_CML_PARTS_COST], s.[PM_CML_LABOR_COST], s.[PM_CML_PARTS_COST], s.[USER_REPR_CML_LABOR_COST],
            s.[USER_REPR_CML_PARTS_COST], s.[ACCT_EOM_ACCT_CODE] COLLATE SQL_Latin1_General_CP1_CI_AS, s.[REPAIR_EQUIP_COST], s.[PM_EQUIP_COST],
            s.[USER_REPR_EQUIP_COST], s.[ELECTRIC_QTY], s.[ELECTRIC_COST])
 WHEN MATCHED AND (   t.[METER_1_USAGE] <> ISNULL(s.[METER_1_USAGE], 0)
                 OR   t.[METER_2_USAGE] <> ISNULL(s.[METER_2_USAGE], 0)
                 OR   t.[FUEL_QTY] <> ISNULL(s.[FUEL_QTY], 0)
                 OR   t.[FUEL_COST] <> ISNULL(s.[FUEL_COST], 0)
                 OR   t.[CNG_QTY] <> ISNULL(s.[CNG_QTY], 0)
                 OR   t.[CNG_COST] <> ISNULL(s.[CNG_COST], 0)
                 OR   t.[OIL_QTY] <> ISNULL(s.[OIL_QTY], 0)
                 OR   t.[OIL_COST] <> ISNULL(s.[OIL_COST], 0)
                 OR   t.[MISC_COST] <> ISNULL(s.[MISC_COST], 0)
                 OR   t.[MISC_PARTS_COST] <> ISNULL(s.[MISC_PARTS_COST], 0)
                 OR   t.[REPAIR_LABOR_HRS] <> ISNULL(s.[REPAIR_LABOR_HRS], 0)
                 OR   t.[REPAIR_LABOR_COST] <> ISNULL(s.[REPAIR_LABOR_COST], 0)
                 OR   t.[REPAIR_PARTS_COST] <> ISNULL(s.[REPAIR_PARTS_COST], 0)
                 OR   t.[REPAIR_TASKS] <> ISNULL(s.[REPAIR_TASKS], 0)
                 OR   t.[PM_LABOR_HRS] <> ISNULL(s.[PM_LABOR_HRS], 0)
                 OR   t.[PM_LABOR_COST] <> ISNULL(s.[PM_LABOR_COST], 0)
                 OR   t.[PM_PARTS_COST] <> ISNULL(s.[PM_PARTS_COST], 0)
                 OR   t.[PM_SERVICES] <> ISNULL(s.[PM_SERVICES], 0)
                 OR   t.[DEPREC_COST] <> ISNULL(s.[DEPREC_COST], 0)
                 OR   t.[RENTAL_REVENUE] <> ISNULL(s.[RENTAL_REVENUE], 0)
                 OR   t.[LEASE_COST] <> ISNULL(s.[LEASE_COST], 0)
                 OR   t.[DOWNTIME_HRS_DEPT] <> ISNULL(s.[DOWNTIME_HRS_DEPT], 0)
                 OR   t.[DOWNTIME_HRS_SHOP] <> ISNULL(s.[DOWNTIME_HRS_SHOP], 0)
                 OR   t.[DELAY_HRS] <> ISNULL(s.[DELAY_HRS], 0)
                 OR   t.[WARRANTY_COST_RECOV] <> ISNULL(s.[WARRANTY_COST_RECOV], 0)
                 OR   t.[CAPITAL_COST] <> ISNULL(s.[CAPITAL_COST], 0)
                 OR   t.[FIXED_MONTHLY_COST] <> ISNULL(s.[FIXED_MONTHLY_COST], 0)
                 OR   t.[FIXED_INSURANCE_COST] <> ISNULL(s.[FIXED_INSURANCE_COST], 0)
                 OR   t.[FIXED_REPLACE_COST] <> ISNULL(s.[FIXED_REPLACE_COST], 0)
                 OR   t.[FIXED_LICENSING_COST] <> ISNULL(s.[FIXED_LICENSING_COST], 0)
                 OR   t.[FIXED_COST_1] <> ISNULL(s.[FIXED_COST_1], 0)
                 OR   t.[FIXED_COST_2] <> ISNULL(s.[FIXED_COST_2], 0)
                 OR   t.[FIXED_COST_3] <> ISNULL(s.[FIXED_COST_3], 0)
                 OR   t.[FEE] <> ISNULL(s.[FEE], 0)
                 OR   t.[LICENSE] <> ISNULL(s.[LICENSE], 0)
                 OR   t.[USER_REPR_LABOR_HRS] <> ISNULL(s.[USER_REPR_LABOR_HRS], 0)
                 OR   t.[USER_REPR_LABOR_COST] <> ISNULL(s.[USER_REPR_LABOR_COST], 0)
                 OR   t.[USER_REPR_PARTS_COST] <> ISNULL(s.[USER_REPR_PARTS_COST], 0)
                 OR   t.[USER_REPR_TASKS] <> ISNULL(s.[USER_REPR_TASKS], 0)
                 OR   t.[USER_CAUS_DOWNT_DEPT] <> ISNULL(s.[USER_CAUS_DOWNT_DEPT], 0)
                 OR   t.[USER_CAUS_DOWNT_SHOP] <> ISNULL(s.[USER_CAUS_DOWNT_SHOP], 0)
                 OR   t.[INSURANCE_RECOVERY] <> ISNULL(s.[INSURANCE_RECOVERY], 0)
                 OR   t.[AUTO_TRANS_FL_QTY] <> ISNULL(s.[AUTO_TRANS_FL_QTY], 0)
                 OR   t.[AUTO_TRANS_FL_COST] <> ISNULL(s.[AUTO_TRANS_FL_COST], 0)
                 OR   t.[ANTIFREEZE_FL_QTY] <> ISNULL(s.[ANTIFREEZE_FL_QTY], 0)
                 OR   t.[ANTIFREEZE_FL_COST] <> ISNULL(s.[ANTIFREEZE_FL_COST], 0)
                 OR   t.[HYDRAULIC_FL_QTY] <> ISNULL(s.[HYDRAULIC_FL_QTY], 0)
                 OR   t.[HYDRAULIC_FL_COST] <> ISNULL(s.[HYDRAULIC_FL_COST], 0)
                 OR   t.[BRAKE_FL_QTY] <> ISNULL(s.[BRAKE_FL_QTY], 0)
                 OR   t.[BRAKE_FL_COST] <> ISNULL(s.[BRAKE_FL_COST], 0)
                 OR   t.[GEAR_OIL_QTY] <> ISNULL(s.[GEAR_OIL_QTY], 0)
                 OR   t.[GEAR_OIL_COST] <> ISNULL(s.[GEAR_OIL_COST], 0)
                 OR   t.[AIR_COND_FL_QTY] <> ISNULL(s.[AIR_COND_FL_QTY], 0)
                 OR   t.[AIR_COND_FL_COST] <> ISNULL(s.[AIR_COND_FL_COST], 0)
                 OR   t.[TIRE_COST] <> ISNULL(s.[TIRE_COST], 0)
                 OR   t.[METER_1_EOM] <> ISNULL(s.[METER_1_EOM], 0)
                 OR   t.[METER_2_EOM] <> ISNULL(s.[METER_2_EOM], 0)
                 OR   ISNULL(t.[EOM_RUN_DATE], '1/1/1900') <> ISNULL(s.[EOM_RUN_DATE], '1/1/1900')
                 OR   t.[METER_POSTING_FLAG] <> ISNULL(s.[METER_POSTING_FLAG], '') COLLATE SQL_Latin1_General_CP1_CI_AS
                 OR   t.[USAGE_TICKET_FLAG] <> ISNULL(s.[USAGE_TICKET_FLAG], '') COLLATE SQL_Latin1_General_CP1_CI_AS
                 OR   t.[TRIGGER_MODE] <> ISNULL(s.[TRIGGER_MODE], '') COLLATE SQL_Latin1_General_CP1_CI_AS
                 OR   t.[CORE_COST_RECOV] <> ISNULL(s.[CORE_COST_RECOV], 0)
                 OR   t.[LOC_LOC_CODE] <> ISNULL(s.[LOC_LOC_CODE], '') COLLATE SQL_Latin1_General_CP1_CI_AS
                 OR   t.[DEPT_DEPT_CODE] <> ISNULL(s.[DEPT_DEPT_CODE], '') COLLATE SQL_Latin1_General_CP1_CI_AS
                 OR   t.[EQ_MAIN_EQUIP_NO] <> ISNULL(s.[EQ_MAIN_EQUIP_NO], '') COLLATE SQL_Latin1_General_CP1_CI_AS
                 OR   t.[METER_1_TYPE] <> ISNULL(s.[METER_1_TYPE], '') COLLATE SQL_Latin1_General_CP1_CI_AS
                 OR   t.[METER_2_TYPE] <> ISNULL(s.[METER_2_TYPE], '') COLLATE SQL_Latin1_General_CP1_CI_AS
                 OR   t.[REPAIR_CML_LABOR_COST] <> ISNULL(s.[REPAIR_CML_LABOR_COST], 0)
                 OR   t.[REPAIR_CML_PARTS_COST] <> ISNULL(s.[REPAIR_CML_PARTS_COST], 0)
                 OR   t.[PM_CML_LABOR_COST] <> ISNULL(s.[PM_CML_LABOR_COST], 0)
                 OR   t.[PM_CML_PARTS_COST] <> ISNULL(s.[PM_CML_PARTS_COST], 0)
                 OR   t.[USER_REPR_CML_LABOR_COST] <> ISNULL(s.[USER_REPR_CML_LABOR_COST], 0)
                 OR   t.[USER_REPR_CML_PARTS_COST] <> ISNULL(s.[USER_REPR_CML_PARTS_COST], 0)
                 OR   t.[ACCT_EOM_ACCT_CODE] <> ISNULL(s.[ACCT_EOM_ACCT_CODE], '') COLLATE SQL_Latin1_General_CP1_CI_AS
                 OR   t.[REPAIR_EQUIP_COST] <> ISNULL(s.[REPAIR_EQUIP_COST], 0)
                 OR   t.[PM_EQUIP_COST] <> ISNULL(s.[PM_EQUIP_COST], 0)
                 OR   t.[USER_REPR_EQUIP_COST] <> ISNULL(s.[USER_REPR_EQUIP_COST], 0)
                 OR   t.[ELECTRIC_QTY] <> ISNULL(s.[ELECTRIC_QTY], 0)
                 OR   t.[ELECTRIC_COST] <> ISNULL(s.[ELECTRIC_COST], 0)) THEN
    UPDATE SET t.[METER_1_USAGE] = ISNULL(s.[METER_1_USAGE], 0),
               t.[METER_2_USAGE] = ISNULL(s.[METER_2_USAGE], 0),
               t.[FUEL_QTY] = ISNULL(s.[FUEL_QTY], 0),
               t.[FUEL_COST] = ISNULL(s.[FUEL_COST], 0),
               t.[CNG_QTY] = ISNULL(s.[CNG_QTY], 0),
               t.[CNG_COST] = ISNULL(s.[CNG_COST], 0),
               t.[OIL_QTY] = ISNULL(s.[OIL_QTY], 0),
               t.[OIL_COST] = ISNULL(s.[OIL_COST], 0),
               t.[MISC_COST] = ISNULL(s.[MISC_COST], 0),
               t.[MISC_PARTS_COST] = ISNULL(s.[MISC_PARTS_COST], 0),
               t.[REPAIR_LABOR_HRS] = ISNULL(s.[REPAIR_LABOR_HRS], 0),
               t.[REPAIR_LABOR_COST] = ISNULL(s.[REPAIR_LABOR_COST], 0),
               t.[REPAIR_PARTS_COST] = ISNULL(s.[REPAIR_PARTS_COST], 0),
               t.[REPAIR_TASKS] = ISNULL(s.[REPAIR_TASKS], 0),
               t.[PM_LABOR_HRS] = ISNULL(s.[PM_LABOR_HRS], 0),
               t.[PM_LABOR_COST] = ISNULL(s.[PM_LABOR_COST], 0),
               t.[PM_PARTS_COST] = ISNULL(s.[PM_PARTS_COST], 0),
               t.[PM_SERVICES] = ISNULL(s.[PM_SERVICES], 0),
               t.[DEPREC_COST] = ISNULL(s.[DEPREC_COST], 0),
               t.[RENTAL_REVENUE] = ISNULL(s.[RENTAL_REVENUE], 0),
               t.[LEASE_COST] = ISNULL(s.[LEASE_COST], 0),
               t.[DOWNTIME_HRS_DEPT] = ISNULL(s.[DOWNTIME_HRS_DEPT], 0),
               t.[DOWNTIME_HRS_SHOP] = ISNULL(s.[DOWNTIME_HRS_SHOP], 0),
               t.[DELAY_HRS] = ISNULL(s.[DELAY_HRS], 0),
               t.[WARRANTY_COST_RECOV] = ISNULL(s.[WARRANTY_COST_RECOV], 0),
               t.[CAPITAL_COST] = ISNULL(s.[CAPITAL_COST], 0),
               t.[FIXED_MONTHLY_COST] = ISNULL(s.[FIXED_MONTHLY_COST], 0),
               t.[FIXED_INSURANCE_COST] = ISNULL(s.[FIXED_INSURANCE_COST], 0),
               t.[FIXED_REPLACE_COST] = ISNULL(s.[FIXED_REPLACE_COST], 0),
               t.[FIXED_LICENSING_COST] = ISNULL(s.[FIXED_LICENSING_COST], 0),
               t.[FIXED_COST_1] = ISNULL(s.[FIXED_COST_1], 0),
               t.[FIXED_COST_2] = ISNULL(s.[FIXED_COST_2], 0),
               t.[FIXED_COST_3] = ISNULL(s.[FIXED_COST_3], 0),
               t.[FEE] = ISNULL(s.[FEE], 0),
               t.[LICENSE] = ISNULL(s.[LICENSE], 0),
               t.[USER_REPR_LABOR_HRS] = ISNULL(s.[USER_REPR_LABOR_HRS], 0),
               t.[USER_REPR_LABOR_COST] = ISNULL(s.[USER_REPR_LABOR_COST], 0),
               t.[USER_REPR_PARTS_COST] = ISNULL(s.[USER_REPR_PARTS_COST], 0),
               t.[USER_REPR_TASKS] = ISNULL(s.[USER_REPR_TASKS], 0),
               t.[USER_CAUS_DOWNT_DEPT] = ISNULL(s.[USER_CAUS_DOWNT_DEPT], 0),
               t.[USER_CAUS_DOWNT_SHOP] = ISNULL(s.[USER_CAUS_DOWNT_SHOP], 0),
               t.[INSURANCE_RECOVERY] = ISNULL(s.[INSURANCE_RECOVERY], 0),
               t.[AUTO_TRANS_FL_QTY] = ISNULL(s.[AUTO_TRANS_FL_QTY], 0),
               t.[AUTO_TRANS_FL_COST] = ISNULL(s.[AUTO_TRANS_FL_COST], 0),
               t.[ANTIFREEZE_FL_QTY] = ISNULL(s.[ANTIFREEZE_FL_QTY], 0),
               t.[ANTIFREEZE_FL_COST] = ISNULL(s.[ANTIFREEZE_FL_COST], 0),
               t.[HYDRAULIC_FL_QTY] = ISNULL(s.[HYDRAULIC_FL_QTY], 0),
               t.[HYDRAULIC_FL_COST] = ISNULL(s.[HYDRAULIC_FL_COST], 0),
               t.[BRAKE_FL_QTY] = ISNULL(s.[BRAKE_FL_QTY], 0),
               t.[BRAKE_FL_COST] = ISNULL(s.[BRAKE_FL_COST], 0),
               t.[GEAR_OIL_QTY] = ISNULL(s.[GEAR_OIL_QTY], 0),
               t.[GEAR_OIL_COST] = ISNULL(s.[GEAR_OIL_COST], 0),
               t.[AIR_COND_FL_QTY] = ISNULL(s.[AIR_COND_FL_QTY], 0),
               t.[AIR_COND_FL_COST] = ISNULL(s.[AIR_COND_FL_COST], 0),
               t.[TIRE_COST] = ISNULL(s.[TIRE_COST], 0),
               t.[METER_1_EOM] = ISNULL(s.[METER_1_EOM], 0),
               t.[METER_2_EOM] = ISNULL(s.[METER_2_EOM], 0),
               t.[EOM_RUN_DATE] = ISNULL(s.[EOM_RUN_DATE], '1/1/1900'),
               t.[METER_POSTING_FLAG] = ISNULL(s.[METER_POSTING_FLAG], '') COLLATE SQL_Latin1_General_CP1_CI_AS,
               t.[USAGE_TICKET_FLAG] = ISNULL(s.[USAGE_TICKET_FLAG], '') COLLATE SQL_Latin1_General_CP1_CI_AS,
               t.[TRIGGER_MODE] = ISNULL(s.[TRIGGER_MODE], '') COLLATE SQL_Latin1_General_CP1_CI_AS,
               t.[CORE_COST_RECOV] = ISNULL(s.[CORE_COST_RECOV], 0),
               t.[LOC_LOC_CODE] = ISNULL(s.[LOC_LOC_CODE], '') COLLATE SQL_Latin1_General_CP1_CI_AS,
               t.[DEPT_DEPT_CODE] = ISNULL(s.[DEPT_DEPT_CODE], '') COLLATE SQL_Latin1_General_CP1_CI_AS,
               t.[EQ_MAIN_EQUIP_NO] = ISNULL(s.[EQ_MAIN_EQUIP_NO], '') COLLATE SQL_Latin1_General_CP1_CI_AS,
               t.[METER_1_TYPE] = ISNULL(s.[METER_1_TYPE], '') COLLATE SQL_Latin1_General_CP1_CI_AS,
               t.[METER_2_TYPE] = ISNULL(s.[METER_2_TYPE], '') COLLATE SQL_Latin1_General_CP1_CI_AS,
               t.[REPAIR_CML_LABOR_COST] = ISNULL(s.[REPAIR_CML_LABOR_COST], 0),
               t.[REPAIR_CML_PARTS_COST] = ISNULL(s.[REPAIR_CML_PARTS_COST], 0),
               t.[PM_CML_LABOR_COST] = ISNULL(s.[PM_CML_LABOR_COST], 0),
               t.[PM_CML_PARTS_COST] = ISNULL(s.[PM_CML_PARTS_COST], 0),
               t.[USER_REPR_CML_LABOR_COST] = ISNULL(s.[USER_REPR_CML_LABOR_COST], 0),
               t.[USER_REPR_CML_PARTS_COST] = ISNULL(s.[USER_REPR_CML_PARTS_COST], 0),
               t.[ACCT_EOM_ACCT_CODE] = ISNULL(s.[ACCT_EOM_ACCT_CODE], '') COLLATE SQL_Latin1_General_CP1_CI_AS,
               t.[REPAIR_EQUIP_COST] = ISNULL(s.[REPAIR_EQUIP_COST], 0),
               t.[PM_EQUIP_COST] = ISNULL(s.[PM_EQUIP_COST], 0),
               t.[USER_REPR_EQUIP_COST] = ISNULL(s.[USER_REPR_EQUIP_COST], 0),
               t.[ELECTRIC_QTY] = ISNULL(s.[ELECTRIC_QTY], 0),
               t.[ELECTRIC_COST] = ISNULL(s.[ELECTRIC_COST], 0),
			   t.record_updated_date = SYSDATETIME()
 WHEN NOT MATCHED BY SOURCE THEN DELETE
OUTPUT $action into @OutputTbl;

 

declare @i int = (select isnull(count(*),0) from @OutputTbl where ActionName = 'Insert' group by ActionName )
declare @u int = (select isnull(count(*),0) from @OutputTbl where ActionName = 'Update' group by ActionName )
declare @d int = (select isnull(count(*),0) from @OutputTbl where ActionName = 'Delete' group by ActionName )



update [process].[MergeLogs] 
set recInsert =  isnull(@i,0)
,recUpdate = isnull(@u,0)
,recDelete = isnull(@d,0)
,[MergeEndDatetime] = sysdatetime()
   where mergecode = 'COST'
     and [ObjectDestination] = 'LTD_DW.eam.EQ_COST_DATA'
	 AND [ObjectSource] = 'EAM'
	 AND [ObjectProgram] = 'LTD_DW.eam.Get_EQ_COST_DATA'
	 AND [MergeEndDatetime] is null
	 AND (recInsert <> 0 or recUpdate <> 0 or recDelete <> 0)
	 AND MergeBeginDatetime = @startdt

 
END TRY	  

BEGIN CATCH

       DECLARE @profile VARCHAR(255) = (
                    SELECT [NAME]
                    FROM msdb.dbo.sysmail_profile
                    )
       DECLARE @errormsg VARCHAR(max)
             ,@error INT
             ,@message VARCHAR(max)
             ,@xstate INT
             ,@errsev INT
             ,@sub VARCHAR(255);

       SELECT @error = ERROR_NUMBER()
             ,@errsev = ERROR_SEVERITY()
             ,@message = ERROR_MESSAGE()
             ,@xstate = XACT_STATE();

       SELECT @errormsg = 'Error in ' + isnull(@SPROC, '') + ': ' + cast(isnull(@error, '') AS NVARCHAR(32)) + '|' + coalesce(@message, '') + '|' + cast(isnull(@xstate, '') AS NVARCHAR(32)) + '|' +cast(isnull(@errsev, '') AS NVARCHAR(32))

       SELECT @sub = 'ERROR: ' + @SPROC

       EXEC msdb.dbo.sp_send_dbmail @profile_name = @profile
             ,@recipients = 'barb.eichberger@ltd.org' 
             ,@subject = @sub
             ,@body = @errormsg;

       RAISERROR (
                    @errormsg
                    ,@errsev
                    ,1
                    )
END CATCH

GO
