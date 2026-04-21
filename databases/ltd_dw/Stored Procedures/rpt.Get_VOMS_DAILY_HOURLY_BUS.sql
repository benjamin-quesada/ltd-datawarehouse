SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- test declare and range
CREATE   PROCEDURE [rpt].[Get_VOMS_DAILY_HOURLY_BUS]
@stDate INT,
@toDate INT,
@busType VARCHAR(12)
as

/*
CREATED:   20200902
AUTHOR :   B EICHBERGER
PURPOSE:   To produce hourly data reporting the maximum number of services provided per hour
		   with the goal of bringing the maximum rides per hour, day and eventually day and month
		   for NTD reporting.

		   Specific to LTD Internal Fleet and EMX

EXEC EXAMPLE: exec rpt.Get_VOMS_DAILY_HOURLY_BUS 20200901, 20200930, 'emx'

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

-- test declare
--declare @stDate INT
--declare @toDate INT

--select @stDate = 20190330
--select @toDate = 20190331
---- end test


create table #LTDOutputTbl9940 (ActionName varchar(32))


declare @workstartdt datetime = sysdatetime()


 --clean up merge log in case some previous processing did not complete
update ltd_dw.[process].[MergeLogs]
SET [recInsert] = 0
,recDelete = 0
,recUpdate = 0 
,MergeEndDatetime = @workstartdt
where [MergeBeginDatetime] is not null 
and MergeEndDatetime is null 
and MergeCode = 'VOMS'
and [ObjectDestination] = 'ltd_dw.rpt.VOMS_DAILY_HOURLY_BUS'

insert ltd_dw.[process].[MergeLogs] (
	   [MergeCode]
      ,[ObjectDestination]
      ,[ObjectSource]
      ,[ObjectProgram]
      ,[recInsert]
      ,[recUpdate]
      ,[recDelete]
      ,[MergeBeginDatetime])
	  Values(
	  'VOMS', 'ltd_dw.rpt.VOMS_DAILY_HOURLY_BUS','NOVUS','ltd_dw.rpt.Get_VOMS_DAILY_HOURLY_BUS',0, 0, 0, @workstartdt)

IF OBJECT_ID('tempdb..#LTDVOMSData') IS NOT NULL
	DROP TABLE #LTDVOMSData;

IF OBJECT_ID('tempdb..#LTDTimeTableCTE') IS NOT NULL
	DROP TABLE #LTDTimeTableCTE;

IF OBJECT_ID('tempdb..#LTDseconds') IS NOT NULL
	DROP TABLE #LTDseconds;

IF OBJECT_ID('tempdb..#LTDseconds') IS NOT NULL
	DROP TABLE #LTDsecdays;

SELECT TOP (86400) n = CONVERT(INT, ROW_NUMBER() OVER (ORDER BY s1.[object_id]))
INTO #LTDseconds
FROM sys.all_objects AS s1 CROSS JOIN sys.all_objects AS s2
OPTION (MAXDOP 1);

declare @calstart INT
declare @calEnd INT
select @calStart = (select @stDate + 100000000)
select @calEnd = (select @toDate + 100000000)

select s.n, b.CALENDAR_ID
into #LTDsecdays 
from #LTDseconds s
cross join (select distinct calendar_id from [ltd-tmdata].tmdatamart.dbo.adherence WITH (NOLOCK) 
		where calendar_id between @calStart and @calEnd) b
--order by calendar_id,n
-- select * from #LTDsecdays
CREATE NONCLUSTERED INDEX [ix_temp_SECDAY] On tempdb.#LTDsecdays (calendar_id,[n])

select a.calendar_id, a.vehicle_id, trip_id, a.block_id, a.service_type_id
, actual_arrival_time, actual_departure_time
--,[bus] = v.property_tag
,[emx] = case when substring(right('000' + b.block_abbr, 4), 2, 1) = '9' then 1 else 0 end 
into #LTDActiveBus
 from [ltd-tmdata].tmdatamart.dbo.adherence a WITH (NOLOCK)
inner join #LTDsecdays l on l.calendar_id = a.calendar_id
INNER JOIN [ltd-tmdata].tmdatamart.dbo.vehicle v WITH (NOLOCK) on v.vehicle_id = a.vehicle_id
INNER JOIN [ltd-tmdata].tmdatamart.dbo.[block] b WITH (NOLOCK) on b.block_id = a.block_id and b.time_table_version_id = a.time_table_version_id
where a.revenue_id <> 'D' and a.vehicle_id is not null
GROUP BY a.calendar_id, a.vehicle_id, trip_id, a.block_id, a.service_type_id
, actual_arrival_time, actual_departure_time,v.property_tag
,case when substring(right('000' + b.block_abbr, 4), 2, 1) = '9' then 1 else 0 end 


CREATE TABLE #LTDVOMSData (
	trip_id INT
	,block_id INT
	,calendar_id INT
	,busType varchar(12)
	,vehicle_id INT
	,firstArriveTime INT
	,lastDropOffTime INT
	);

if @busType = 'emx'
BEGIN

INSERT INTO -- select * from 
 #LTDVOMSData  
SELECT trip_id, block_id, calendar_id, 'emx' as busType, vehicle_id
,min(actual_arrival_time) firstArriveTime
,max(actual_departure_time) lastDropOffTime 
FROM #LTDActiveBus pb WITH (NOLOCK)
where emx = 1
AND pb.ACTUAL_ARRIVAL_TIME IS NOT NULL AND pb.ACTUAL_DEPARTURE_TIME IS NOT NULL 
group by trip_id, block_id, calendar_id, vehicle_id

END

if @busType <> 'emx'
BEGIN
INSERT INTO -- select * from 
 #LTDVOMSData  
SELECT trip_id, block_id, calendar_id, 'bus' as busType, vehicle_id
,min(actual_arrival_time) firstArriveTime
,max(actual_departure_time) lastDropOffTime 
FROM #LTDActiveBus pb WITH (NOLOCK)
where emx = 0
AND pb.ACTUAL_ARRIVAL_TIME IS NOT NULL AND pb.ACTUAL_DEPARTURE_TIME IS NOT NULL 
group by trip_id, block_id, calendar_id, vehicle_id

END

select calendar_id,left(HHMMSS,2) HH,max(ISNULL(current_runs,0)) current_runs 
into #LTDvomssource
from (	
select calendar_id,n,
left(CAST(DATEADD(SECOND,n,0) AS TIME),8) HHMMSS,
 ISNULL(COUNT(distinct trip_id),0) current_runs 
--, sum(passengersOn) current_riders 
from (
select s.n , z.*
FROM #LTDVOMSData z
 JOIN #LTDsecdays s on s.calendar_id = z.calendar_id
and s.n >= firstArriveTime 
and s.n <= lastDropOffTime 
) z2
 group by calendar_id,n ) y
 group by calendar_id,left(HHMMSS,2)
 order by calendar_id,left(HHMMSS,2), current_runs desc

 MERGE [rpt].[VOMS_DAILY_HOURLY_BUS] t
 USING #LTDvomssource s
 ON t.[calendar_id] = s.[calendar_id]
and t.[HH] = s.[HH]
and t.busType = @busType
WHEN NOT MATCHED THEN INSERT
           ([calendar_id]
		   ,[busType]
           ,[HH]
           ,[current_runs] )
     VALUES (
            s.[calendar_id]-100000000
			, @busType
           ,s.[HH]
           ,s.[current_runs] ) 
WHEN MATCHED and
	ISNULL(s.[current_runs],0) <> ISNULL(t.[current_runs],0)
THEN UPDATE
	set t.[current_runs] = ISNULL(s.[current_runs],0)
OUTPUT $action into #LTDOutputTbl9940;

declare @n int = (select isnull(count(*),0) from #LTDOutputTbl9940 WITH (NOLOCK) where ActionName = 'Insert' group by ActionName )
declare @u int = (select isnull(count(*),0) from #LTDOutputTbl9940 WITH (NOLOCK) where ActionName = 'Update' group by ActionName )
declare @d int = (select isnull(count(*),0) from #LTDOutputTbl9940 WITH (NOLOCK) where ActionName = 'Delete' group by ActionName )


update ltd_dw.[process].[MergeLogs] 
set recInsert = isnull( @n, 0 )
,recUpdate = isnull(@u, 0)
,recDelete = isnull(@d, 0)
,[MergeEndDatetime] = sysdatetime()
   where mergecode = 'VOMS'
     and [ObjectDestination] = 'ltd_dw.rpt.VOMS_DAILY_HOURLY_BUS'
	 AND [ObjectSource] = 'NOVUS'
	 AND [ObjectProgram] = 'ltd_dw.rpt.Get_VOMS_DAILY_HOURLY_BUS'
	 AND [MergeBeginDatetime] = @workstartdt
	 AND [MergeEndDatetime] is null
	 AND (recInsert = 0 or recUpdate = 0 or recDelete = 0)

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
