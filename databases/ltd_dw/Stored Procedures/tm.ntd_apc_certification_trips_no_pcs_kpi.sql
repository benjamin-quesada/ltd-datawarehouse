SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE procedure [tm].[ntd_apc_certification_trips_no_pcs_kpi]
as
/****************************
CREATED ON	: 20241022
CREATED BY	: B Eichberger
PURPOSE		: NTD Required KPI summarizing number of trips that likely had APC problems
			  - defined by adherence having been collected by passenger count remaining
			    null for the entire trip
USE			: call from power bi report exec dbo.ntd_apc_certification_trips_no_pcs_kpi
			  This takes some time to run so it should be a scheduled refresh Power BI
			  exec tm.ntd_apc_certification_trips_no_pcs_kpi 

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

DECLARE @sdt DATETIME2 = SYSDATETIME()
DECLARE @outputTbl TABLE (actionNm VARCHAR(32));

declare @startcal int = (select isnull(max(calendar_id),120200701)-3 from ltd_dw.tm.ntd_apc_certification_trips_no_pcs_dtl)


DROP TABLE IF EXISTS #trips_pcs
SELECT CALENDAR_ID, a.VEHICLE_ID, a.TRIP_ID, t.TRIP_END_TIME, BOARD=SUM(a.BOARD), ALIGHT=SUM(a.ALIGHT)
INTO #trips_pcs
FROM [LTD-TMDATA].tmdatamart.dbo.PASSENGER_COUNT a
     JOIN [LTD-TMDATA].tmdatamart.dbo.TRIP t ON t.TRIP_ID=a.TRIP_ID
     JOIN [LTD-TMDATA].tmdatamart.dbo.[ROUTE] r ON r.ROUTE_ID=a.ROUTE_ID
WHERE a.TRIP_ID IS NOT NULL 
AND a.OVERLOAD_ID = 0
and a.VEHICLE_ID is not null 
AND a.CALENDAR_ID >= @startcal
AND ROUTE_ABBR NOT IN ('25', 'swap','flt')
GROUP BY CALENDAR_ID, a.VEHICLE_ID, a.TRIP_ID, t.TRIP_END_TIME;


DROP TABLE IF EXISTS #trips
SELECT CALENDAR_ID, a.VEHICLE_ID, a.TRIP_ID, t.TRIP_END_TIME
INTO #trips
FROM [LTD-TMDATA].tmdatamart.dbo.ADHERENCE a
     JOIN [LTD-TMDATA].tmdatamart.dbo.TRIP t ON t.TRIP_ID=a.TRIP_ID
     JOIN [LTD-TMDATA].tmdatamart.dbo.[ROUTE] r ON r.ROUTE_ID=a.ROUTE_ID
WHERE a.TRIP_ID IS NOT NULL 
AND ADHERENCE IS NOT NULL  
AND a.OVERLOAD_ID = 0
and a.VEHICLE_ID is not null 
AND a.CALENDAR_ID >= @startcal
AND ROUTE_ABBR NOT IN ('25', 'swap','flt')
GROUP BY CALENDAR_ID, a.VEHICLE_ID, a.TRIP_ID, t.TRIP_END_TIME;


 -- prep output
drop table if exists #pcsCombo
select FiscalYear, [Fiscal Year Name], calendar_id
,vehicle_id, trip_id, TRIP_END_TIME,PROPERTY_TAG
,board, alight  
into #pcsCombo
from (
SELECT r.FiscalYear, r.[Fiscal Year Name], a.calendar_id
,a.vehicle_id, a.trip_id, a.TRIP_END_TIME,v.PROPERTY_TAG
,p.board, p.alight 
FROM tm.DW_CALENDAR r
left join #trips a on a.calendar_id = r.calendar_id 
LEFT JOIN #trips_pcs p ON p.calendar_id = a.calendar_id
	AND p.TRIP_ID = a.TRIP_ID
	AND p.TRIP_END_TIME = a.TRIP_END_TIME
	AND p.VEHICLE_ID = a.VEHICLE_ID
LEFT JOIN [LTD-TMDATA].tmdatamart.dbo.VEHICLE v ON v.VEHICLE_ID = a.vehicle_id) x

-- save detail table -- truncate table ltd_dw.tm.ntd_apc_certification_trips_no_pcs_dtl
MERGE ltd_dw.tm.ntd_apc_certification_trips_no_pcs_dtl t
USING #pcsCombo s
on t.FiscalYear = s.FiscalYear
and t.calendar_id = s.calendar_id
and t.vehicle_id = s.vehicle_id
and t.trip_id = s.trip_id
and t.TRIP_END_TIME = s.trip_end_time
WHEN MATCHED AND
isnull(t.board,999) <> isnull(s.board,999)
or isnull(t.alight,999) <> isnull(s.alight,999)
THEN UPDATE
set t.board = s.board
,t.alight = s.alight
,t.record_updated_date = sysdatetime()
WHEN NOT MATCHED THEN INSERT
(FiscalYear, [Fiscal Year Name], calendar_id
,vehicle_id, trip_id, TRIP_END_TIME,PROPERTY_TAG
,board, alight )
VALUES
(s.FiscalYear, s.[Fiscal Year Name], s.calendar_id
,s.vehicle_id, s.trip_id, s.TRIP_END_TIME,s.PROPERTY_TAG
,s.board, s.alight)
OUTPUT $action INTO @outputTbl
;


---- report layer query for summary
--SELECT FiscalYear, [Fiscal Year Name] 
--	 , trips_count = COUNT(CAST(trip_id AS VARCHAR(12)) + '-' + CAST(TRIP_END_TIME AS VARCHAR(12))) 
--     , trips_no_pc = SUM( CASE WHEN board IS NULL AND alight IS NULL THEN 1 ELSE 0 END) 
--     , perc_trip_no_pc= case when (COUNT(CAST(trip_id AS VARCHAR(12)) + '-' + CAST(TRIP_END_TIME AS VARCHAR(12))) * 1.0) > 0
--			then (SUM( CASE WHEN board IS NULL AND alight IS NULL THEN 1 ELSE 0 END) * 1.0) 
--					/ (COUNT(CAST(trip_id AS VARCHAR(12)) + '-' + CAST(TRIP_END_TIME AS VARCHAR(12))) * 1.0) 
--					else null end 
--FROM ltd_dw.tm.ntd_apc_certification_trips_no_pcs_dtl i
-- GROUP BY i.FiscalYear, i.[Fiscal Year Name]
-- ORDER BY i.FiscalYear

				  
DECLARE @ins INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'INSERT')
DECLARE @upd INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'UPDATE')
DECLARE @del INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'DELETE')
DECLARE @prg varchar(90) = @@SERVERNAME + '.ltd_dw.tm.ntd_apc_certification_trips_no_pcs_kpi'

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
select 'APC',
'ltd_dw.tm.ntd_apc_certification_trips_no_pcs_dtl',
'TM',
@prg,
isnull(@ins,0) ,0,0,
@sdt,
sysdatetime()


 
DROP TABLE IF exists #trips_pcs
DROP TABLE IF EXISTS #trips





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
