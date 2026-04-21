SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   PROCEDURE [dim].[GetVehicle]
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

BEGIN TRY
;

WITH vSource AS (
SELECT DISTINCT [ltd_bus_class] 
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
      ,[bus_kind]
  FROM [ltd_dw].[model].[Vehicle_v]
  WHERE vehicle_id <> 299)

MERGE model.Vehicle t 
USING vSource s ON 
t.EQ_equip_no = s.EQ_equip_no
WHEN NOT MATCHED THEN
INSERT 
([ltd_bus_class] 
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
      ,[bus_kind])
VALUES (
s.[ltd_bus_class] 
      ,s.[EQ_equip_no] 
      ,s.[VEHICLE TYPE]
      ,s.[bus_text_class]
      ,s.[VEHICLE YEAR]
      ,s.[UnitAgeDays]
      ,s.[VEHICLE MANUFACTURER]
      ,s.[VEHICLE MODEL]
      ,s.[VEHICLE DESC]
      ,s.[artic]
      ,s.[emx_bus]
      ,s.[hybrid]
      ,s.[electric]
      ,s.[SHOP STATUS]
      ,s.[WORK ORDER STATUS]
      ,s.[FUEL CARD NUMBER]
      ,s.[FIXED MONTHLY COST]
      ,s.[OPEN WORK ORDERS]
      ,s.[MONTHS IN OPERATION]
      ,s.[DEPRECIATION MONTHS LIFE]
      ,s.[DEPRECIATION MONTHS REMAINING]
      ,s.[LAST METER READING]
      ,s.[LIFE TOTAL MILES]
      ,s.[is_retired_or_sold]
      ,s.[is_retired_or_sold_count]
      ,s.[original_cost]
      ,s.[VEHICLE LENGTH FLEET]
      ,s.[art_text]
      ,s.[emx_text]
      ,s.[hyb_text]
      ,s.[ele_text]
      ,s.[ltd_class_sort]
      ,s.[FLEET_TEXT]
      ,s.[PROPERTY_TAG]
      ,s.[MFG_MODEL_TEXT]
      ,s.[VEHICLE_TYPE_TEXT]
      ,s.[RNET_ADDRESS]
      ,s.[MODEL_YEAR]
      ,s.[DECOMMISSION]
      ,s.[TOTAL_CAPACITY]
      ,s.[FLEET_ID]
      ,s.[SEATING_CAPACITY]
      ,s.[VEHICLE_MFG_TEXT]
      ,s.[license_no]
      ,s.[bus_kind])
WHEN MATCHED AND 
(ISNULL(t.[ltd_bus_class],'') <> ISNULL(s.[ltd_bus_class],'') COLLATE SQL_Latin1_General_CP850_CI_AS
OR ISNULL(t.[VEHICLE TYPE],'') <> ISNULL(s.[VEHICLE TYPE],'') COLLATE SQL_Latin1_General_CP850_CI_AS
OR ISNULL(t.[bus_text_class],'') <> ISNULL(s.[bus_text_class],'') COLLATE SQL_Latin1_General_CP850_CI_AS
OR ISNULL(t.[VEHICLE YEAR],0) <> ISNULL(s.[VEHICLE YEAR],0)
OR ISNULL(t.[UnitAgeDays],0) <> ISNULL(s.[UnitAgeDays],0)
OR ISNULL(t.[VEHICLE MANUFACTURER],'') <> ISNULL(s.[VEHICLE MANUFACTURER],'') COLLATE SQL_Latin1_General_CP850_CI_AS
OR ISNULL(t.[VEHICLE MODEL],'') <> ISNULL(s.[VEHICLE MODEL],'') COLLATE SQL_Latin1_General_CP850_CI_AS
OR ISNULL(t.[VEHICLE DESC],'') <> ISNULL(s.[VEHICLE DESC],'') COLLATE SQL_Latin1_General_CP850_CI_AS
OR ISNULL(t.[artic],0) <> ISNULL(s.[artic],0)
OR ISNULL(t.[emx_bus],0) <> ISNULL(s.[emx_bus],0)
OR ISNULL(t.[hybrid],0) <> ISNULL(s.[hybrid],0)
OR ISNULL(t.[electric],0) <> ISNULL(s.[electric],0) 
OR ISNULL(t.[SHOP STATUS],'') <> ISNULL(s.[SHOP STATUS],'') COLLATE SQL_Latin1_General_CP850_CI_AS
OR ISNULL(t.[WORK ORDER STATUS],'') <> ISNULL(s.[WORK ORDER STATUS],'') COLLATE SQL_Latin1_General_CP850_CI_AS
OR ISNULL(t.[FUEL CARD NUMBER],0) <> ISNULL(s.[FUEL CARD NUMBER],0) 
OR ISNULL(t.[FIXED MONTHLY COST],0) <> ISNULL(s.[FIXED MONTHLY COST],0) 
OR ISNULL(t.[OPEN WORK ORDERS],0) <> ISNULL(s.[OPEN WORK ORDERS],0) 
OR ISNULL(t.[MONTHS IN OPERATION],0) <> ISNULL(s.[MONTHS IN OPERATION],0)
OR ISNULL(t.[DEPRECIATION MONTHS LIFE],0) <> ISNULL(s.[DEPRECIATION MONTHS LIFE],0)
OR ISNULL(t.[DEPRECIATION MONTHS REMAINING],0) <> ISNULL(s.[DEPRECIATION MONTHS REMAINING],0)
OR ISNULL(t.[LAST METER READING],0) <> ISNULL(s.[LAST METER READING],0)
OR ISNULL(t.[LIFE TOTAL MILES],0) <> ISNULL(s.[LIFE TOTAL MILES],0)
OR ISNULL(t.[is_retired_or_sold],0) <> ISNULL(s.[is_retired_or_sold],0)
OR ISNULL(t.[is_retired_or_sold_count],0) <> ISNULL(s.[is_retired_or_sold_count],0)
OR ISNULL(t.[original_cost],0) <> ISNULL(s.[original_cost],0)
OR ISNULL(t.[VEHICLE LENGTH FLEET],'') <> ISNULL(s.[VEHICLE LENGTH FLEET],'') COLLATE SQL_Latin1_General_CP850_CI_AS
OR ISNULL(t.[art_text],'') <> ISNULL(s.[art_text],'') COLLATE SQL_Latin1_General_CP850_CI_AS
OR ISNULL(t.[emx_text],'') <> ISNULL(s.[emx_text],'') COLLATE SQL_Latin1_General_CP850_CI_AS
OR ISNULL(t.[hyb_text],'') <> ISNULL(s.[hyb_text],'') COLLATE SQL_Latin1_General_CP850_CI_AS
OR ISNULL(t.[ele_text],'') <> ISNULL(s.[ele_text],'') COLLATE SQL_Latin1_General_CP850_CI_AS
OR ISNULL(t.[ltd_class_sort],0) <> ISNULL(s.[ltd_class_sort],0)
OR ISNULL(t.[FLEET_TEXT],'') <> ISNULL(s.[FLEET_TEXT],'') COLLATE SQL_Latin1_General_CP850_CI_AS
OR ISNULL(t.[PROPERTY_TAG],'') <> ISNULL(s.[PROPERTY_TAG],'') COLLATE SQL_Latin1_General_CP850_CI_AS
OR ISNULL(t.[MFG_MODEL_TEXT],'') <> ISNULL(s.[MFG_MODEL_TEXT],'') COLLATE SQL_Latin1_General_CP850_CI_AS
OR ISNULL(t.[VEHICLE_TYPE_TEXT],'') <> ISNULL(s.[VEHICLE_TYPE_TEXT],'') COLLATE SQL_Latin1_General_CP850_CI_AS
OR ISNULL(t.[RNET_ADDRESS],0) <> ISNULL(s.[RNET_ADDRESS],0)
OR ISNULL(t.[MODEL_YEAR],0) <> ISNULL(s.[MODEL_YEAR],0)
OR ISNULL(t.[DECOMMISSION],0) <> ISNULL(s.[DECOMMISSION],0)
OR ISNULL(t.[TOTAL_CAPACITY],0) <> ISNULL(s.[TOTAL_CAPACITY],0)
OR ISNULL(t.[FLEET_ID],0) <> ISNULL(s.[FLEET_ID],0)
OR ISNULL(t.[SEATING_CAPACITY],0) <> ISNULL(s.[SEATING_CAPACITY],0)
OR ISNULL(t.[VEHICLE_MFG_TEXT],'') <> ISNULL(s.[VEHICLE_MFG_TEXT],'') COLLATE SQL_Latin1_General_CP850_CI_AS
OR ISNULL(t.[license_no],'') <> ISNULL(s.[license_no],'') COLLATE SQL_Latin1_General_CP850_CI_AS
OR ISNULL(t.[bus_kind],'') <> ISNULL(s.[bus_kind],'') COLLATE SQL_Latin1_General_CP850_CI_AS
)
THEN UPDATE 
SET 
 t.[ltd_bus_class] = ISNULL(s.[ltd_bus_class],'')
,t.[EQ_equip_no] = ISNULL(s.[EQ_equip_no],'')
,t.[VEHICLE TYPE] = ISNULL(s.[VEHICLE TYPE],'')
,t.[bus_text_class] = ISNULL(s.[bus_text_class],'')
,t.[VEHICLE YEAR] = ISNULL(s.[VEHICLE YEAR],0)
,t.[UnitAgeDays] = ISNULL(s.[UnitAgeDays],0)
,t.[VEHICLE MANUFACTURER] = ISNULL(s.[VEHICLE MANUFACTURER],'')
,t.[VEHICLE MODEL] = ISNULL(s.[VEHICLE MODEL],'')
,t.[VEHICLE DESC] = ISNULL(s.[VEHICLE DESC],'')
,t.[artic] = ISNULL(s.[artic],0)
,t.[emx_bus] = ISNULL(s.[emx_bus],0)
,t.[hybrid] = ISNULL(s.[hybrid],0)
,t.[electric] = ISNULL(s.[electric],0)
,t.[SHOP STATUS] = ISNULL(s.[SHOP STATUS],'')
,t.[WORK ORDER STATUS] = ISNULL(s.[WORK ORDER STATUS],'')
,t.[FUEL CARD NUMBER] = ISNULL(s.[FUEL CARD NUMBER],0)
,t.[FIXED MONTHLY COST] = ISNULL(s.[FIXED MONTHLY COST],0)
,t.[OPEN WORK ORDERS] = ISNULL(s.[OPEN WORK ORDERS],0)
,t.[MONTHS IN OPERATION] = ISNULL(s.[MONTHS IN OPERATION],0)
,t.[DEPRECIATION MONTHS LIFE] = ISNULL(s.[DEPRECIATION MONTHS LIFE],0)
,t.[DEPRECIATION MONTHS REMAINING] = ISNULL(s.[DEPRECIATION MONTHS REMAINING],0)
,t.[LAST METER READING] = ISNULL(s.[LAST METER READING],0)
,t.[LIFE TOTAL MILES] = ISNULL(s.[LIFE TOTAL MILES],0)
,t.[is_retired_or_sold] = ISNULL(s.[is_retired_or_sold],0)
,t.[is_retired_or_sold_count] = ISNULL(s.[is_retired_or_sold_count],0)
,t.[original_cost] = ISNULL(s.[original_cost],0)
,t.[VEHICLE LENGTH FLEET] = ISNULL(s.[VEHICLE LENGTH FLEET],'')
,t.[art_text] = ISNULL(s.[art_text],'')
,t.[emx_text] = ISNULL(s.[emx_text],'')
,t.[hyb_text] = ISNULL(s.[hyb_text],'')
,t.[ele_text] = ISNULL(s.[ele_text],'')
,t.[ltd_class_sort] = ISNULL(s.[ltd_class_sort],'')
,t.[FLEET_TEXT] = ISNULL(s.[FLEET_TEXT],'')
,t.[PROPERTY_TAG] = ISNULL(s.[PROPERTY_TAG],'')
,t.[MFG_MODEL_TEXT] = ISNULL(s.[MFG_MODEL_TEXT],'')
,t.[VEHICLE_TYPE_TEXT] = ISNULL(s.[VEHICLE_TYPE_TEXT],'')
,t.[RNET_ADDRESS] = ISNULL(s.[RNET_ADDRESS],0)
,t.[MODEL_YEAR] = ISNULL(s.[MODEL_YEAR],0)
,t.[DECOMMISSION] = ISNULL(s.[DECOMMISSION],0)
,t.[TOTAL_CAPACITY] = ISNULL(s.[TOTAL_CAPACITY],0)
,t.[FLEET_ID] = ISNULL(s.[FLEET_ID],0)
,t.[SEATING_CAPACITY] = ISNULL(s.[SEATING_CAPACITY],0)
,t.[VEHICLE_MFG_TEXT] = ISNULL(s.[VEHICLE_MFG_TEXT],'')
,t.[license_no] = ISNULL(s.[license_no],'')
,t.[bus_kind] = ISNULL(s.[bus_kind],'')
,t.record_updated_date = SYSDATETIME()
;


END TRY	  


BEGIN CATCH

       DECLARE @profile VARCHAR(255) = (
                    SELECT NAME
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
             ,@recipients = 'barb.eichberger@ltd.org'--;servicedesk@ltd.org' 
             ,@subject = @sub
             ,@body = @errormsg;

       RAISERROR (
                    @errormsg
                    ,@errsev
                    ,1
                    )
END CATCH
GO
