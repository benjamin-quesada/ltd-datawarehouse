SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   PROCEDURE [tm].[apc_route_date_selections]
AS
/*
Use me to generate routes as possible selections for APC Certification Testing

Goes into MS Access Database dedicated to APC Certification

Author:		B EIchberger
Created:	7/3/2023

exec tm.apc_route_date_selections
*/

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


DROP TABLE IF EXISTS #apcdays 
CREATE TABLE #apcdays (rn INT, apcday INT)
DECLARE @StartDate AS DATE = (SELECT DATEADD(MONTH,-4,GETDATE()))
DECLARE @EndDate AS DATE = (SELECT GETDATE()-2)

DECLARE @i INT = 1
DECLARE @r INT = 25
DECLARE @currDate INT 

WHILE @i <= @r
BEGIN

INSERT #apcdays (apcday)
SELECT CAST(CONVERT(VARCHAR(42),DATEADD(DAY, RAND(CHECKSUM(NEWID()))*(1+DATEDIFF(DAY, @StartDate, @EndDate)),@StartDate), 112) AS INT)+100000000

SELECT @i = @i + 1

IF @i > @r
BREAK
	ELSE CONTINUE
END


INSERT INTO [apc].[route_block_vehicle_survey_options]
           ([CALENDAR_ID]
           ,[TIME_TABLE_VERSION_NAME]
           ,[SCHEDULED_TIME]
           ,[SCHED_DIST_FROM_LAST_GEO_NODE]
           ,[SCHEDULED_TRAVEL_TIME_SECONDS]
           ,[SCHEDULED_TRAVEL_TIME_MINUTES]
           ,[BLOCK_ABBR]
           ,[ROUTE_ABBR]
           ,[ROUTE_NAME]
           ,[ROUTE_DIRECTION]
           ,[ROUTE_DIRECTION_NAME]
           ,[GEO_NODE_ABBR]
           ,[GEO_NODE_NAME]
           ,[TRIP_ID]
           ,[TRIP_END_TIME]
           ,[VEHICLE]
           ,[SERVICE_ABBR]
           ,[PATTERN_GEO_NODE_SEQ]
           ,[BLOCK_STOP_ORDER]
           ,[ROUTE_STOP_SEQUENCE]
           ,[BADGE])
SELECT 
e.CALENDAR_ID
,ttv.TIME_TABLE_VERSION_NAME
,[dbo].[F_getHHMM_from_SPM](e.SCHEDULED_TIME) SCHEDULED_TIME
,e.SCHED_DIST_FROM_LAST_GEO_NODE
,e.SCHEDULED_TRAVEL_TIME SCHEDULED_TRAVEL_TIME_SECONDS
,e.SCHEDULED_TRAVEL_TIME/60.0 SCHEDULED_TRAVEL_TIME_MINUTES
,b.BLOCK_ABBR
,r.ROUTE_ABBR
,r.ROUTE_NAME
,LEFT(rd.ROUTE_DIRECTION_ABBR,1) ROUTE_DIRECTION
,rd.ROUTE_DIRECTION_NAME
,g.GEO_NODE_ABBR
,g.GEO_NODE_NAME
,e.TRIP_ID
,[dbo].[F_getHHMM_from_SPM](t.TRIP_END_TIME) TRIP_END_TIME
,h.PROPERTY_TAG AS VEHICLE
,v.SERVICE_ABBR
,e.PATTERN_GEO_NODE_SEQ
,e.BLOCK_STOP_ORDER
,e.ROUTE_STOP_SEQUENCE
,o.BADGE 
FROM [ltd-tmdata].tmdatamart.dbo.ADHERENCE e WITH (NOLOCK) 
JOIN #apcdays d ON d.apcday = e.calendar_id
JOIN [ltd-tmdata].tmdatamart.dbo.ROUTE r ON r.ROUTE_ID = e.ROUTE_ID
JOIN [ltd-tmdata].tmdatamart.dbo.ROUTE_DIRECTION rd ON rd.ROUTE_DIRECTION_ID = e.ROUTE_DIRECTION_ID
JOIN [ltd-tmdata].tmdatamart.dbo.GEO_NODE g ON g.GEO_NODE_ID = e.GEO_NODE_ID 
JOIN [ltd-tmdata].tmdatamart.dbo.TRIP t ON t.TRIP_ID = e.TRIP_ID
JOIN [ltd-tmdata].tmdatamart.dbo.SERVICE_TYPE v ON v.SERVICE_TYPE_ID = e.SERVICE_TYPE_ID
JOIN [ltd-tmdata].tmdatamart.dbo.OPERATOR o ON o.OPERATOR_ID = e.OPERATOR_ID
JOIN [ltd-tmdata].tmdatamart.dbo.[BLOCK] B ON B.block_id = E.block_id
join [ltd-tmdata].tmdatamart.dbo.[time_table_version] ttv on e.TIME_TABLE_VERSION_ID = ttv.TIME_TABLE_VERSION_ID
JOIN [ltd-tmdata].tmdatamart.dbo.[vehicle] h ON h.VEHICLE_ID = e.VEHICLE_ID
WHERE e.CALENDAR_ID >= 120230101
and e.overload_id = 0
and e.trip_id is not null
AND e.EARLY_COUNT = 0
AND e.ONTIME_COUNT = 0
AND e.LATE_COUNT = 0
AND r.ROUTE_ABBR <> 'FLT'
AND v.SERVICE_ABBR = 'Weekday'
ORDER BY trip_id
GO
