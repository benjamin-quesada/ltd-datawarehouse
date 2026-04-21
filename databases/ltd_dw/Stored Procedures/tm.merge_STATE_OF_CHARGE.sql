SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [tm].[merge_STATE_OF_CHARGE]
AS

/*-----------LTD_GLOSSARY---------------
 created by	:  B. Eichberger
 created dt	:  2024-12-20
 purpose	:  merge state of charge for electric vehicles
			   to maintain a record to aid planning
 use		:  exec tm.merge_state_of_charge

*/

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

DECLARE @startDt DATETIME = (SELECT DATEADD(HOUR, -6,ISNULL(MAX(START_TIME),'12/12/2024')) FROM tm.state_of_charge)
DECLARE @calStartDt INT = (SELECT [dbo].[F_DATE_TO_CALENDAR_ID](@startDt))
DECLARE @sdt DATETIME2 = SYSDATETIME()
DECLARE @outputTbl TABLE (actionNm VARCHAR(32));

DROP TABLE IF EXISTS #sched
DROP TABLE IF EXISTS #moving
DROP TABLE IF EXISTS #servTy
DROP TABLE IF EXISTS #mergeSource

SELECT sc.CALENDAR_ID
,sc.BLOCK_ID
,sc.ROUTE_ID
,sc.ROUTE_DIRECTION_ID
,sc.TRIP_ID
,sc.VEHICLE_ID
,sc.SERVICE_TYPE_ID
,sc.REVENUE_ID
,DATEADD(ss, MIN(ACTUAL_ARRIVAL_TIME), dbo.F_CALENDAR_ID_TO_DATE(sc.CALENDAR_ID)) AS START_TIME
,DATEADD(ss, MAX(sc.ACTUAL_DEPARTURE_TIME), dbo.F_CALENDAR_ID_TO_DATE(sc.CALENDAR_ID)) AS END_TIME
INTO #sched 
FROM [ltd-tmdata].tmdatamart.dbo.ADHERENCE_BY_STOP sc WITH (NOLOCK)
WHERE sc.CALENDAR_ID >= @calStartDt
AND ACTUAL_ARRIVAL_TIME IS NOT NULL 
GROUP BY sc.CALENDAR_ID
,sc.BLOCK_ID
,sc.ROUTE_ID
,sc.ROUTE_DIRECTION_ID
,sc.TRIP_ID
,sc.VEHICLE_ID
,sc.SERVICE_TYPE_ID
,sc.REVENUE_ID

SELECT m.CALENDAR_ID
	  ,m.VEHICLE_ID
	  ,m.PROPERTY_TAG
	  ,m.LOCAL_TIMESTAMP
	  ,m.StateOfCharge
	  ,m.LastStateofCharge
	  ,m.ChargeRecovery
	  ,m.SecondsToEmpty
	  ,m.MilesToEmpty 
INTO #moving
FROM tm.logged_messages_moving_electric m -- THIS IS A VIEW IN LTD_DW - LIMITED TO IsCharging <> 1
WHERE m.LOCAL_TIMESTAMP >= @startDt

SELECT DISTINCT * INTO #servTy FROM [LTD-TMDATA].tmdatamart.dbo.SERVICE_TYPE WITH (NOLOCK)

CREATE INDEX ix_moving_LOCAL_TIMESTAMP ON #moving (LOCAL_TIMESTAMP)
CREATE INDEX ix_sched_timestamp ON #sched (START_TIME, END_TIME) 
CREATE INDEX ix_sched_service ON #sched (SERVICE_TYPE_ID) 

SELECT m.CALENDAR_ID
,m.LOCAL_TIMESTAMP
,m.StateOfCharge
,m.LastStateofCharge
,m.ChargeRecovery
,m.SecondsToEmpty
,MinutesToEmpty = [dbo].[F_getHHMM_from_SPM](m.SecondsToEmpty)
,m.MilesToEmpty
,s.BLOCK_ID
,s.ROUTE_ID
,s.ROUTE_DIRECTION_ID
,s.TRIP_ID
,s.VEHICLE_ID
,t.SERVICE_ABBR
,s.REVENUE_ID
,m.PROPERTY_TAG
,s.START_TIME
,s.END_TIME
, maxSOC = MAX(m.StateOfCharge) OVER (PARTITION BY s.BLOCK_ID
,s.ROUTE_ID
,s.ROUTE_DIRECTION_ID
,s.TRIP_ID
,s.VEHICLE_ID ORDER BY m.LOCAL_TIMESTAMP)
,minSOC = min(m.StateOfCharge) OVER (PARTITION BY s.BLOCK_ID
,s.ROUTE_ID
,s.ROUTE_DIRECTION_ID
,s.TRIP_ID
,s.VEHICLE_ID ORDER BY m.LOCAL_TIMESTAMP)
INTO #mergeSource
FROM #moving m
	 LEFT JOIN #sched s ON m.LOCAL_TIMESTAMP BETWEEN s.START_TIME AND s.END_TIME
	 LEFT JOIN #servTy t ON t.SERVICE_TYPE_ID = s.SERVICE_TYPE_ID
	 AND s.CALENDAR_ID = m.CALENDAR_ID;

MERGE [tm].[state_of_charge] AS t
USING #mergeSource AS s
ON (
    t.calendar_id = s.calendar_id
AND t.local_timestamp = s.local_timestamp
AND t.start_time = s.start_time
AND t.end_time = s.end_time
AND t.property_tag = s.property_tag
AND t.service_type_abbr = s.SERVICE_ABBR
AND t.revenue_id = s.REVENUE_ID
)
WHEN MATCHED AND (
   ISNULL(t.StateOfCharge, 0) <> ISNULL(s.StateOfCharge, 0)
OR ISNULL(t.LastStateofCharge, 0) <> ISNULL(s.LastStateofCharge, 0)
OR ISNULL(t.ChargeRecovery, 0) <> ISNULL(s.ChargeRecovery, 0)
OR ISNULL(t.SecondsToEmpty, 0) <> ISNULL(s.SecondsToEmpty, 0)
OR ISNULL(t.MinutesToEmpty, 0) <> ISNULL(s.MinutesToEmpty, 0)
OR ISNULL(t.MilesToEmpty, 0) <> ISNULL(s.MilesToEmpty, '')
OR ISNULL(t.BLOCK_ID, 0) <> ISNULL(s.BLOCK_ID, 0)
OR ISNULL(t.ROUTE_ID, 0) <> ISNULL(s.ROUTE_ID, 0)
OR ISNULL(t.ROUTE_DIRECTION_ID, 0) <> ISNULL(s.ROUTE_DIRECTION_ID, 0)
OR ISNULL(t.TRIP_ID, 0) <> ISNULL(s.TRIP_ID, 0)
OR ISNULL(t.VEHICLE_ID, 0) <> ISNULL(s.VEHICLE_ID, 0)
OR ISNULL(t.maxSOC, 0) <> ISNULL(s.maxSOC, 0)
OR ISNULL(t.minSOC, 0) <> ISNULL(s.minSOC, 0)
)
THEN UPDATE 
SET t.StateOfCharge = s.StateOfCharge
,t.LastStateofCharge = s.LastStateofCharge
,t.ChargeRecovery = s.ChargeRecovery
,t.SecondsToEmpty = s.SecondsToEmpty
,t.MinutesToEmpty = s.MinutesToEmpty
,t.MilesToEmpty = s.MilesToEmpty
,t.BLOCK_ID = s.BLOCK_ID
,t.ROUTE_ID = s.ROUTE_ID
,t.ROUTE_DIRECTION_ID = s.ROUTE_DIRECTION_ID
,t.TRIP_ID = s.TRIP_ID
,t.VEHICLE_ID = s.VEHICLE_ID
,t.maxSOC = s.maxSOC
,t.minSOC = s.minSOC
,t.record_updated_date = SYSDATETIME()
WHEN NOT MATCHED BY TARGET
THEN INSERT
(
CALENDAR_ID
,LOCAL_TIMESTAMP
,START_TIME
,END_TIME
,StateOfCharge
,LastStateofCharge
,ChargeRecovery
,SecondsToEmpty
,MinutesToEmpty
,MilesToEmpty
,BLOCK_ID
,ROUTE_ID
,ROUTE_DIRECTION_ID
,TRIP_ID
,VEHICLE_ID
,SERVICE_TYPE_ABBR
,REVENUE_ID
,PROPERTY_TAG
,maxSOC
,minSOC
)
VALUES
(s.CALENDAR_ID, s.LOCAL_TIMESTAMP, s.START_TIME, s.END_TIME, s.StateOfCharge, s.LastStateofCharge, s.ChargeRecovery, s.SecondsToEmpty, s.MinutesToEmpty, s.MilesToEmpty, s.BLOCK_ID, s.ROUTE_ID, s.ROUTE_DIRECTION_ID, s.TRIP_ID, s.VEHICLE_ID,s.SERVICE_ABBR,s.REVENUE_ID, s.PROPERTY_TAG, s.maxSOC, s.minSOC
)
OUTPUT $action INTO @outputTbl;


DECLARE @ins INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'INSERT')
DECLARE @upd INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'UPDATE')
DECLARE @del INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'DELETE')
DECLARE @prg varchar(90) = @@SERVERNAME + '.ltd_dw.tm.merge_state_of_charge'

insert process.mergeLogs
(		[MergeCode]
           ,[ObjectDestination]
           ,[ObjectSource]
           ,[ObjectProgram]
           ,[recInsert]
           ,[recUpdate]
           ,[recDelete]
           ,[MergeBeginDatetime]
           ,[MergeEndDatetime])
select 'TMSOC',
'ltd_dw.tm.state_of_charge',
'TM',
@prg,
isnull(@ins,0) ,ISNULL(@upd,0),ISNULL(@del,0),
@sdt,
sysdatetime()



END TRY	  

BEGIN CATCH

       DECLARE @profile VARCHAR(255) = (
                    SELECT [NAME]
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

       SELECT @errormsg = 'Error in ' + ISNULL(@SPROC, '') + ': ' + CAST(ISNULL(@error, '') AS NVARCHAR(32)) + '|' + COALESCE(@message, '') + '|' + CAST(ISNULL(@xstate, '') AS NVARCHAR(32)) + '|' +CAST(ISNULL(@errsev, '') AS NVARCHAR(32))

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
