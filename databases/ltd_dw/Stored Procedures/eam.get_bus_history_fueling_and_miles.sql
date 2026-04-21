SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   PROCEDURE [eam].[get_bus_history_fueling_and_miles]
as

/************LTD_GLOSSARY*********

CREATED ON	: 20240723rger
Purpose		: Support reporting on bus type fuel type with history to 2005

USE			: exec eam.get_bus_history_fueling_and_miles

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

DECLARE @lastdt DATE = (SELECT DATEADD(DAY,-3,ISNULL(MAX(TransactionDate),'1/3/2005')) FROM eam.bus_history_fueling_and_miles);
WITH tangleFuel AS (
SELECT [EQ_equip_no]
      ,[description], f.fuel_type
  FROM [LTD-EAM].[proto].[emsdba].[EQ_FUELTYPE] T1
  JOIN [LTD-EAM].[proto].[emsdba].[FUE_TYPES] f ON f.fuel_type = T1.Fuel_Type
  WHERE T1.[delete_row] = 'N' AND ISNUMERIC(T1.EQ_equip_no) = 1
  --AND T1.fuel_type IN ('ULS','UNL','kWH','DEF') 
  )
, dsc AS (
SELECT g.EQ_equip_no, REPLACE(REPLACE(REPLACE(g.Fuel_Type_Description,'</fuel_type>',''),'fuel_type>, ',''),'<',', ') Fuel_Type_Description from (
SELECT distinct [EQ_equip_no]
,ltrim( STUFF((SELECT ', '+description fuel_type
FROM tangleFuel T1
WHERE T1.[EQ_equip_no] = T2.[EQ_equip_no]
FOR XML PATH('')),1,1,'')) AS Fuel_Type_Description
FROM tangleFuel T2
) g
GROUP BY g.EQ_equip_no, REPLACE(REPLACE(REPLACE(g.Fuel_Type_Description,'</fuel_type>',''),'fuel_type>, ',''),'<',', ') )
,abbr AS (

select g.EQ_equip_no, REPLACE(REPLACE(REPLACE(g.Fuel_Type_Abbr,'</fuel_type>',''),'fuel_type>, ',''),'<',', ') fuel_type from (
SELECT distinct [EQ_equip_no]
,ltrim( STUFF((SELECT ', '+fuel_type fuel_type
FROM tangleFuel T1
WHERE T1.[EQ_equip_no] = T2.[EQ_equip_no]
FOR XML PATH('')),1,1,'')) AS Fuel_Type_Abbr
FROM tangleFuel T2
) g
--WHERE g.EQ_equip_no = '1101'
GROUP BY g.EQ_equip_no, REPLACE(REPLACE(REPLACE(g.Fuel_Type_Abbr,'</fuel_type>',''),'fuel_type>, ',''),'<',', ') 
)
,bus_fuel_type AS (
SELECT d.EQ_equip_no, d.Fuel_Type_Description, a.fuel_type Fuel_Type_Abbr FROM dsc d
FULL OUTER JOIN abbr a ON a.EQ_equip_no = d.EQ_equip_no)

INSERT [eam].[bus_history_fueling_and_miles](
[TransactionDate]
,[EquipmentID]
,[bus_fuel_type_abbr]
,[bus_fuel_type_desc]
,[TransactionCalId]
,[FuelOrfluidType]
,[fuel_description]
,[fuel_fluid_description]
,[ghg_fuel_type]
,[MEA_unit_measure]
,[posting_type]
,[Qty]
,[Meter1Reading]
,[MilesAtLastFueling]
,[MilesSinceLastFueling]
,[HoursSinceLastFueling]
,[estimatedMPG]
,[kwh_gallon_equiv]
,[all_fuel_gallon]
,[EmployeeOroperatorID]
,[SiteID]
,[PumpID]
,[AccountID]
,[FuelOrfluidUnitPrice]
,[FuelOrfluidValue]
,[ltd_bus_class]
,[EQ_equip_no]
,[VEHICLE TYPE]
,[bus_text_class]
,[VEHICLE YEAR]
,[UnitAgeDays]
,[VEHICLE MANUFACTURER]
,[VEHICLE MODEL]
,[VEHICLE DESC]
,[artic]
,[emx_bus]
,[hybrid]
,[electric]
,[SHOP STATUS]
,[WORK ORDER STATUS]
,[FUEL CARD NUMBER]
,[FIXED MONTHLY COST]
,[OPEN WORK ORDERS]
,[MONTHS IN OPERATION]
,[DEPRECIATION MONTHS LIFE]
,[DEPRECIATION MONTHS REMAINING]
,[LAST METER READING]
,[LIFE TOTAL MILES]
,[is_retired_or_sold]
,[is_retired_or_sold_count]
,[original_cost]
,[VEHICLE LENGTH FLEET]
,[art_text]
,[emx_text]
,[hyb_text]
,[ele_text]
,[ltd_class_sort]
,[FLEET_TEXT]
,[PROPERTY_TAG]
,[MFG_MODEL_TEXT]
,[VEHICLE_TYPE_TEXT]
,[RNET_ADDRESS]
,[MODEL_YEAR]
,[DECOMMISSION]
,[TOTAL_CAPACITY]
,[FLEET_ID]
,[SEATING_CAPACITY]
,[VEHICLE_MFG_TEXT]
,[license_no]
,[sla_status]
,[bus_kind]
)
SELECT f.TransactionDate
,f.EquipmentID
,b.Fuel_Type_Abbr bus_fuel_type_abbr, b.Fuel_Type_Description bus_fuel_type_desc
,CAST(CONVERT(VARCHAR(32), f.TransactionDate, 112) AS INT) + 100000000 TransactionCalId
--,f.TankID
,f.FuelOrfluidType
,t.[description] fuel_description
,c.[description] fuel_fluid_description
,t.[ghg_fuel_type]
,t.MEA_unit_measure
,ISNULL(t.posting_type, f.FuelOrfluidType) posting_type
,f.Qty
,f.Meter1Reading
,LAG(f.Meter1Reading) OVER (PARTITION BY f.FuelOrfluidType
						   ,f.EquipmentID
							ORDER BY CAST(f.TransactionDate AS DATETIME2)
						   ) MilesAtLastFueling
,f.Meter1Reading - LAG(f.Meter1Reading) OVER (PARTITION BY f.FuelOrfluidType
						   ,f.EquipmentID
							ORDER BY CAST(f.TransactionDate AS DATETIME2)
						   ) MilesSinceLastFueling
,DATEDIFF(MINUTE
		,LAG(f.TransactionDate) OVER (PARTITION BY f.FuelOrfluidType
									 ,f.EquipmentID
									  ORDER BY CAST(f.TransactionDate AS DATETIME2)
									 )
		,CAST(f.TransactionDate AS DATETIME2)
		 ) / 60.0 AS HoursSinceLastFueling
,estimatedMPG = (f.Meter1Reading - LAG(f.Meter1Reading) OVER (PARTITION BY f.EquipmentID
															 ,f.FuelOrfluidType
															  ORDER BY f.TransactionDate
															 )
				) / CASE WHEN f.FuelOrfluidType = 'KwH' THEN f.Qty * 0.029931063 ELSE f.Qty END
,CASE WHEN f.FuelOrfluidType = 'KwH' THEN f.Qty * 0.029931063 END AS kwh_gallon_equiv
,CASE WHEN f.FuelOrfluidType = 'KwH' THEN f.Qty * 0.029931063 ELSE f.Qty END AS all_fuel_gallon
,f.EmployeeOroperatorID
,f.SiteID
,f.PumpID
,ISNULL(f.AccountID, 'GENERAL FUND') AccountID
,f.FuelOrfluidUnitPrice
,f.FuelOrfluidValue
,v.ltd_bus_class
,v.EQ_equip_no
,v.[VEHICLE TYPE]
,v.bus_text_class
,v.[VEHICLE YEAR]
,v.UnitAgeDays
,v.[VEHICLE MANUFACTURER]
,v.[VEHICLE MODEL]
,v.[VEHICLE DESC]
,v.artic
,v.emx_bus
,v.hybrid
,v.electric
,v.[SHOP STATUS]
,v.[WORK ORDER STATUS]
,v.[FUEL CARD NUMBER]
,v.[FIXED MONTHLY COST]
,v.[OPEN WORK ORDERS]
,v.[MONTHS IN OPERATION]
,v.[DEPRECIATION MONTHS LIFE]
,v.[DEPRECIATION MONTHS REMAINING]
,v.[LAST METER READING]
,v.[LIFE TOTAL MILES]
,v.is_retired_or_sold
,v.is_retired_or_sold_count
,v.original_cost
,v.[VEHICLE LENGTH FLEET]
,v.art_text
,v.emx_text
,v.hyb_text
,v.ele_text
,v.ltd_class_sort
,v.FLEET_TEXT
,v.PROPERTY_TAG
,v.MFG_MODEL_TEXT
,v.VEHICLE_TYPE_TEXT
,v.RNET_ADDRESS
,v.MODEL_YEAR
,v.DECOMMISSION
,v.TOTAL_CAPACITY
,v.FLEET_ID
,v.SEATING_CAPACITY
,v.VEHICLE_MFG_TEXT
,v.license_no
,v.sla_status
,v.bus_kind
FROM [LTD-EAM].proto.[emsdba].[QFuelTicket] f WITH (NOLOCK)
LEFT JOIN bus_fuel_type b ON b.EQ_equip_no = f.EquipmentID
	 LEFT JOIN [LTD-EAM].proto.[emsdba].[FUE_TYPES] t WITH (NOLOCK) ON t.fuel_type = f.FuelOrfluidType
	 LEFT JOIN [LTD-EAM].proto.emsdba.fuel_fluid_clist c WITH (NOLOCK) ON c.fuel_fluid_no = f.FuelOrfluidType
	 LEFT JOIN ltd_dw.[model].[Vehicle_and_Equipment_v] v ON v.EQ_equip_no = f.EquipmentID COLLATE SQL_Latin1_General_CP850_CI_AS
WHERE f.TransactionDate >= @lastdt
AND f.Reversal = 'N'
	  AND YEAR(f.TransactionDate) > 2004
	  AND (NOT (
				   f.FuelOrfluidType IS NULL
				   OR CAST(f.FuelOrfluidType AS NVARCHAR) = ''
			   )
		  )
AND NOT EXISTS (SELECT 1 FROM eam.bus_history_fueling_and_miles i WHERE i.TransactionDate = f.TransactionDate
		AND i.EquipmentID = f.EquipmentID COLLATE SQL_Latin1_General_CP850_CI_AS AND i.qty = f.Qty );

		


END TRY
BEGIN CATCH

	DECLARE @profile VARCHAR(255) =
			(SELECT name FROM msdb .dbo.sysmail_profile)  ;
	DECLARE @errormsg VARCHAR(MAX)
		   ,@error INT
		   ,@message VARCHAR(MAX)
		   ,@xstate INT
		   ,@errsev INT
		   ,@sub VARCHAR(255) ;

	SELECT	@error = ERROR_NUMBER()
		   ,@errsev = ERROR_SEVERITY()
		   ,@message = ERROR_MESSAGE()
		   ,@xstate = XACT_STATE() ;

	SELECT	@errormsg = 'Error in ' + ISNULL(@SPROC, '') + ': ' + CAST(ISNULL(@error, '') AS NVARCHAR(32)) + '|' + COALESCE(@message, '') + '|' + CAST(ISNULL(@xstate, '') AS NVARCHAR(32)) + '|' + CAST(ISNULL(@errsev, '') AS NVARCHAR(32)) ;

	SELECT	@sub = 'ERROR: ' + @SPROC ;

	EXEC msdb.dbo.sp_send_dbmail @profile_name = @profile
								,@recipients = 'barb.eichberger@ltd.org'
								,@subject = @sub
								,@body = @errormsg ;

	RAISERROR(@errormsg, @errsev, 1) ;
END CATCH ;


GO
