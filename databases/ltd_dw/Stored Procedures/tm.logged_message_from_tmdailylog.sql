SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE   PROCEDURE [tm].[logged_message_from_tmdailylog]
@getHours int
AS

/*****************LTD_GLOSSARY*************
CREATED ON	: 20240307
CREATED BY	: B. Eichberger
PURPOSE		: for report conversions 'fueling sheet' from crystal reports - keeps only a couple of days
USE			: exec [tm].[logged_message_from_tmdailylog] 8 


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


declare @startHours INT = -@getHours -- a small window - run sproc every hour with plenty of overlap
declare @thirtyDays INT = (SELECT [dbo].[F_DATE_TO_CALENDAR_ID](DATEADD(DAY,-32,GETDATE())) ) -- a small window - run sproc every hour with plenty of overlap

DELETE FROM ltd_dw.tm.logged_messages WHERE [local_timestamp] < DATEADD(DAY,-32,GETDATE())

SELECT [calendar_id]            = lm.calendar_id
      ,[local_timestamp]        = lm.local_timestamp
      ,[calendar_date]          = sc.calendar_date
      ,[day_type]               = lsdtpc.service_type 
      ,[veh]                    = v.PROPERTY_TAG
      --,[fleet]                  = v.fleet
      ,[bus_class]              = v.ltd_bus_class
      ,[artic]                  = v.artic
      ,[emx_bus]                = v.emx_bus
      ,[message_type_id]        = lm.message_type_id
      ,[message_type_text]      = CASE WHEN lm.message_type_id = 48 THEN 'On Route'
                                       WHEN lm.message_type_id =  1 THEN 'MDT Started: ' + CASE lm.cat_6 WHEN 65 THEN 'Cold Start' WHEN 64 THEN 'Warm Reboot' ELSE '??' END
                                       WHEN lm.message_type_id =  9 THEN 'Driver Log ' + CASE lm.cat_6 WHEN 0 THEN 'Off' WHEN 1 THEN 'On' ELSE '??' END + CASE WHEN lm.cat_8 = 1 OR cat_9 = 1 THEN ' (Forced)' ELSE '' END
                                       WHEN lm.message_type_id = 32 THEN 'Logon Verification: ' + CASE lm.cat_6 WHEN 0 THEN 'Denied' WHEN 1 THEN 'Accepted' ELSE '??' END
                                       WHEN lm.message_type_id =  3 THEN 'Init Vehicle Rte: ' 
										+ tm.convert_route_file_version_to_ttv_id_plus_minor_version(lm.route_version) 
										+ ' Msg: ' + CAST(lm.messages_version AS VARCHAR(9))
                                       WHEN lm.message_type_id = 20 THEN '' + CASE WHEN lm.flag32 & POWER(2,3) = POWER(2,3) THEN 'Off Route' 
                                                                                   WHEN lm.flag32 & POWER(2,2) = POWER(2,2) THEN 'WC not cycled' 
                                                                                   WHEN lm.flag32 & POWER(2,1) = POWER(2,1) THEN 'No Logon' 
                                                                                   WHEN lm.flag32 & POWER(2,4) = POWER(2,4) THEN 'Resynch' 
                                                                                   WHEN lm.flag32 & POWER(2,6) = POWER(2,6) THEN 'Stopped too long'
                                                                                                                            ELSE mt.message_type_text 
                                                                              END
                                       WHEN lm.message_type_id = 26 THEN 'Subsystem: ' + CASE WHEN flag32 = 0 THEN 'Ok'
                                                                                              WHEN flag32 & POWER(2,6)  = POWER(2,6) AND flag32 & POWER(2,3) = POWER(2,3) THEN 'J1708 and PCM'
                                                                                              WHEN flag32 & POWER(2,1)  = POWER(2,1)  THEN 'Odometer'
                                                                                              WHEN flag32 & POWER(2,2)  = POWER(2,2)  THEN 'EEPROM'
                                                                                              WHEN flag32 & POWER(2,6)  = POWER(2,6) AND flag32 & POWER(2,3) = POWER(2,3) THEN 'J1708 and PCM'
                                                                                              WHEN flag32 & POWER(2,3)  = POWER(2,3)  THEN 'PC Module'
                                                                                              WHEN flag32 & POWER(2,6)  = POWER(2,6)  THEN 'J1708'
                                                                                              WHEN flag32 & POWER(2,7)  = POWER(2,7)  THEN 'WLAN'
                                                                                              WHEN flag32 & POWER(2,8)  = POWER(2,8)  THEN 'MDT'
                                                                                              WHEN flag32 & POWER(2,10) = POWER(2,10) THEN 'Internal Sign'
                                                                                              WHEN flag32 & POWER(2,11) = POWER(2,11) THEN 'External Sign'
                                                                                                                                      ELSE mt.message_type_text
                                                                                         END          
                                       WHEN lm.message_type_id = 79 THEN 'MCC: ' + CASE lm.cat_3 WHEN 1 THEN 'add' 
                                                                                                 WHEN 2 THEN 'remove' 
                                                                                                 WHEN 3 THEN 'too quiet' 
                                                                                                 WHEN 4 THEN 'uncoord channel switch' 
                                                                                                        ELSE 'unknown' 
                                                                                   END + ' (' + CASE lm.flag32 WHEN 1 THEN 'bln' WHEN 2 THEN 'cbg' ELSE '' END + ')'
                                       WHEN lm.message_type_id = 35 THEN message_type_text + CASE WHEN lm.route_version = 0 THEN '' ELSE ' Rte: ' + tm.convert_route_file_version_to_ttv_id_plus_minor_version(lm.route_version) END + CASE WHEN lm.messages_version = 0 THEN '' ELSE ' Msg: ' + CAST(lm.messages_version AS VARCHAR(9)) END
                                       WHEN lm.message_type_id = 17 THEN 'Canned Msg Inbound (cat_4): ' + CAST(lm.cat_4 AS VARCHAR(4))
									                                ELSE mt.message_type_text
	                              END 
      ,[via_wlan]               = CASE WHEN lm.message_type_id IN(16,20,24,26,37,48,49) THEN cat_7
                                       WHEN lm.message_type_id = 59                     THEN msg_group
                                                                                        ELSE NULL
                                  END 
      ,[odometer]               = CAST((lm.odometer / 100.0) AS NUMERIC(7,2)) 
      ,[mdt_hhmmss]             = tm.convert_spm_to_hh_mm_ss(lm.mdt_timestamp) 
      ,[mdt_spm]                = lm.mdt_timestamp 
      ,[route]                  = r.route_abbr
      ,[block]                  = b.block_abbr
      ,[stop_no]                = gn.geo_node_abbr
      ,[stop_name]              = gn.geo_node_name
      ,[dir]                    = LEFT(rd.route_direction_name, 1) 
      ,[tp_id]                  = CASE WHEN lm.message_type_id = 16 THEN tp.time_point_abbr ELSE NULL END 
      ,[tp_name]                = CASE WHEN lm.message_type_id = 16 THEN tp.time_pt_name ELSE NULL END
      ,[operator]               = o.last_name + ', ' + o.first_name
      ,[latitude]               = lm.latitude
      ,[longitude]              = lm.longitude
      ,[adherence]              = lm.adherence
      ,[validity]               = lm.validity
      ,[FOM]                    = (lm.validity & POWER(2,0)) + (lm.validity & POWER(2,1)) + (lm.validity & POWER(2,2)) + (lm.validity & POWER(2,3)) 
      ,[receiving_dgps]         = CASE WHEN lm.validity & POWER(2,4) = POWER(2,4) THEN 1 ELSE 0 END 
      ,[valid_odometer]         = CASE WHEN lm.validity & POWER(2,5) = POWER(2,5) THEN 1 ELSE 0 END 
      ,[valid_adherence]        = CASE WHEN lm.validity & POWER(2,6) = POWER(2,6) THEN 1 ELSE 0 END 
      ,[valid_position]         = CASE WHEN lm.validity & POWER(2,7) = POWER(2,7) THEN 1 ELSE 0 END 
      ,[sp_place]               = tm.special_service_places(lm.latitude,lm.longitude) 
      ,[east_west_zone]         = CASE WHEN lm.longitude >= -1230400001 THEN 'east' ELSE 'west' END 
      ,[north_south_zone]       = CASE WHEN lm.latitude >= 440489000 THEN 'north' ELSE 'south' END 
      ,[flag32]                 = lm.flag32
      ,[route_version]          = lm.route_version
      ,[messages_version]       = lm.messages_version
      ,[route_offset]           = lm.route_offset
      ,[effective_service]      = lm.effective_service
      ,[direction]              = lm.direction
      ,[time_point_offset]      = lm.time_point_offset
      ,[stop_offset]            = lm.stop_offset
      ,[ons]                    = CASE WHEN lm.message_type_id <> 59 THEN NULL ELSE passenger_count_on END 
      ,[offs]                   = CASE WHEN lm.message_type_id <> 59 THEN NULL ELSE passenger_count_off END 
      ,[msg_group]              = lm.msg_group
      ,[cat_1]                  = cat_1
      ,[cat_2]                  = cat_2
      ,[cat_3]                  = cat_3
      ,[cat_4]                  = cat_4
      ,[cat_5]                  = cat_5
      ,[cat_6]                  = cat_6
      ,[cat_7]                  = cat_7
      ,[cat_8]                  = cat_8
      ,[cat_9]                  = cat_9
      ,[cat_10]                 = cat_10
      ,[lower32]                = lm.lower32
      ,[upper32]                = lm.upper32
	  ,[long_field_2]           = lm.long_field_2
      ,[current_driver]         = lm.current_driver
      ,[free_text_msg]          = LEFT(LOWER(lm.free_text_msg), 255)
      ,[mdt_block_id]           = lm.mdt_block_id
	  ,[blk_id]                 = b.block_id
      ,[transmitted_message_id] = lm.transmitted_message_id
INTO #tempLoggMess
  FROM [LTD-TMDATA].tmdailylog.dbo.logged_message                       lm WITH (NOLOCK)
 INNER JOIN [LTD-TMDATA].tmmain.dbo.service_calendar                     sc WITH (NOLOCK)     ON sc.calendar_id        = lm.calendar_id
 INNER JOIN tm.service_day_type_per_calendar_id lsdtpc WITH (NOLOCK) ON lsdtpc.calendar_id    = lm.calendar_id
 INNER JOIN [LTD-TMDATA].tmmain.dbo.time_table_version                   ttv WITH (NOLOCK)    ON sc.calendar_date BETWEEN ttv.activation_date AND ttv.deactivation_date
 INNER JOIN [LTD-TMDATA].tmmain.dbo.message_type                         mt WITH (NOLOCK)     ON mt.message_type_id    = lm.message_type_id
  LEFT JOIN [LTD-TMDATA].tmmain.dbo.mdt_route                            mdtr WITH (NOLOCK)   ON mdtr.route_offset_id  = lm.route_offset AND mdtr.time_table_version_id = ttv.time_table_version_id
  LEFT JOIN [LTD-TMDATA].tmmain.dbo.[route]                              r  WITH (NOLOCK)     ON r.route_id            = mdtr.route_id
  LEFT JOIN [LTD-TMDATA].tmmain.dbo.route_direction                      rd WITH (NOLOCK)     ON rd.route_direction_id = lm.direction
  LEFT JOIN [LTD-TMDATA].tmmain.dbo.[block]                               b WITH (NOLOCK)      ON b.mdt_block_id        = lm.mdt_block_id AND b.time_table_version_id = ttv.time_table_version_id
  LEFT JOIN [LTD-TMDATA].tmmain.dbo.mdt_node                             mdtn WITH (NOLOCK)   ON mdtn.node_offset_id   = lm.time_point_offset
  LEFT JOIN [LTD-TMDATA].tmmain.dbo.geo_node                             gn WITH (NOLOCK)     ON gn.geo_node_id        = mdtn.geo_node_id
  LEFT JOIN [LTD-TMDATA].tmmain.dbo.time_point                           tp WITH (NOLOCK)     ON tp.time_point_id      = mdtn.time_point_id
  LEFT JOIN [LTD-TMDATA].tmmain.dbo.operator                             o WITH (NOLOCK)      ON o.onboard_logon_id    = lm.current_driver
  LEFT JOIN ltd_dw.[model].[Vehicle_v]					    v      ON v.rnet_address        = CASE WHEN lm.source_host > 512 THEN lm.source_host ELSE lm.destination_host END
 WHERE 1=1
 AND CAST([local_timestamp] AS DATETIME) between DATEADD(HOUR,@startHours,GETDATE()) AND DATEADD(MINUTE,-1,GETDATE())   
 AND lm.CALENDAR_ID >= @thirtyDays



--PRINT @startHours
INSERT ltd_dw.tm.logged_messages(
[calendar_id]
           ,[local_timestamp]
           ,[calendar_date]
           ,[day_type]
           ,[veh]
           ,[bus_class]
           ,[artic]
           ,[emx_bus]
           ,[message_type_id]
           ,[message_type_text]
           ,[via_wlan]
           ,[odometer]
           ,[mdt_hhmmss]
           ,[mdt_spm]
           ,[route]
           ,[block]
           ,[stop_no]
           ,[stop_name]
           ,[dir]
           ,[tp_id]
           ,[tp_name]
           ,[operator]
           ,[latitude]
           ,[longitude]
           ,[adherence]
           ,[validity]
           ,[FOM]
           ,[receiving_dgps]
           ,[valid_odometer]
           ,[valid_adherence]
           ,[valid_position]
           ,[sp_place]
           ,[east_west_zone]
           ,[north_south_zone]
           ,[flag32]
           ,[route_version]
           ,[messages_version]
           ,[route_offset]
           ,[effective_service]
           ,[direction]
           ,[time_point_offset]
           ,[stop_offset]
           ,[ons]
           ,[offs]
           ,[msg_group]
           ,[cat_1]
           ,[cat_2]
           ,[cat_3]
           ,[cat_4]
           ,[cat_5]
           ,[cat_6]
           ,[cat_7]
           ,[cat_8]
           ,[cat_9]
           ,[cat_10]
           ,[lower32]
           ,[upper32]
           ,[long_field_2]
           ,[current_driver]
           ,[free_text_msg]
           ,[mdt_block_id]
           ,[blk_id]
           ,[transmitted_message_id])
SELECT 
[calendar_id]
           ,[local_timestamp]
           ,[calendar_date]
           ,[day_type]
           ,[veh]
           ,[bus_class]
           ,[artic]
           ,[emx_bus]
           ,[message_type_id]
           ,[message_type_text]
           ,[via_wlan]
           ,[odometer]
           ,[mdt_hhmmss]
           ,[mdt_spm]
           ,[route]
           ,[block]
           ,[stop_no]
           ,[stop_name]
           ,[dir]
           ,[tp_id]
           ,[tp_name]
           ,[operator]
           ,[latitude]
           ,[longitude]
           ,[adherence]
           ,[validity]
           ,[FOM]
           ,[receiving_dgps]
           ,[valid_odometer]
           ,[valid_adherence]
           ,[valid_position]
           ,[sp_place]
           ,[east_west_zone]
           ,[north_south_zone]
           ,[flag32]
           ,[route_version]
           ,[messages_version]
           ,[route_offset]
           ,[effective_service]
           ,[direction]
           ,[time_point_offset]
           ,[stop_offset]
           ,[ons]
           ,[offs]
           ,[msg_group]
           ,[cat_1]
           ,[cat_2]
           ,[cat_3]
           ,[cat_4]
           ,[cat_5]
           ,[cat_6]
           ,[cat_7]
           ,[cat_8]
           ,[cat_9]
           ,[cat_10]
           ,[lower32]
           ,[upper32]
           ,[long_field_2]
           ,[current_driver]
           ,[free_text_msg]
           ,[mdt_block_id]
           ,[blk_id]
           ,[transmitted_message_id] FROM #tempLoggMess lm
 WHERE NOT EXISTS (SELECT 1 FROM tm.logged_messages WHERE [transmitted_message_id] = lm.[transmitted_message_id])
GO
