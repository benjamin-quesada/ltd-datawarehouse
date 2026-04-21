SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- test declare and range
CREATE   PROCEDURE [rpt].[Get_VOMS_DAILY_HOURLY_RS_byVehicle]
@stDate INT,
@toDate INT
as

/*
CREATED:   20190829
AUTHOR :   B EICHBERGER
PURPOSE:   To produce hourly data reporting the maximum number of services provided per hour
		   with the goal of bringing the maximum rides per hour, day and eventually day and month
		   for NTD reporting.

		   Specific to Ridesource ***Internal Fleet***

		   -- FOR TEST -- truncate table rpt.[VOMS_DAILY_HOURLY_RS_byVehicle]
CHANGEDON: 9/1/2020
 CHANGEBY: b eichberger
   CHANGE: Used copy of VOMS for external Ridesource providers original.

CHANGEDON: 8/16/2022
 CHANGEBY: b eichberger
   CHANGE: Changed location of source data to ltd-dw2.


EXEC EXAMPLE: exec rpt.Get_VOMS_DAILY_HOURLY_RS_byVehicle 20190101, 20200831

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

---- test declare
--declare @stDate INT
--declare @toDate INT

--select @stDate = 20190321
--select @toDate = 20190331
---- end test


create table #RSOutputTbl9940 (ActionName varchar(32))


declare @workstartdt datetime = sysdatetime()


-- clean up merge log in case some previous processing did not complete
update ltd_dw.[process].[MergeLogs]
SET [recInsert] = 0
,recDelete = 0
,recUpdate = 0 
,MergeEndDatetime = @workstartdt
where [MergeBeginDatetime] is not null 
and MergeEndDatetime is null 
and MergeCode = 'VOMS'
and [ObjectDestination] = 'ltd_dw.rpt.VOMS_DAILY_HOURLY_RS_byVehicle'

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
	  'VOMS', 'ltd_dw.rpt.VOMS_DAILY_HOURLY_RS_byVehicle','NOVUS','ltd_dw.rpt.Get_VOMS_DAILY_HOURLY_RS_byVehicle',0, 0, 0, @workstartdt)

IF OBJECT_ID('tempdb..#RSVOMSData') IS NOT NULL
	DROP TABLE #RSVOMSData;

IF OBJECT_ID('tempdb..#RSTimeTableCTE') IS NOT NULL
	DROP TABLE #RSTimeTableCTE;

IF OBJECT_ID('tempdb..#RSseconds') IS NOT NULL
	DROP TABLE #RSseconds;

IF OBJECT_ID('tempdb..#RSseconds') IS NOT NULL
	DROP TABLE #RSsecdays;

SELECT TOP (86400) n = CONVERT(INT, ROW_NUMBER() OVER (ORDER BY s1.[object_id]))
INTO #RSseconds
FROM sys.all_objects AS s1 CROSS JOIN sys.all_objects AS s2
OPTION (MAXDOP 1);


select * 
into #RSsecdays from #RSseconds s
cross join (select distinct ldate from [LTD-DW2].[Novus_PROD].dbo.PassBooking WITH (NOLOCK) 
where ldate between @stDate and @toDate) b
order by ldate,n

CREATE NONCLUSTERED INDEX [ix_temp_SECDAY] On tempdb.#RSsecdays ([ldate],[n])

select * 
into #RSpassbk from [LTD-DW2].[Novus_PROD].dbo.PassBooking pb WITH (NOLOCK)
where  pb.scheduleStatus = 10
and pb.providerId = 13 -- Ridesource Internal Fleet	
AND pb.ldate IS NOT NULL
AND pb.ldate > 0
AND pb.recordStatus = 'A'
AND pb.ldate BETWEEN @stDate AND @toDate 

CREATE NONCLUSTERED INDEX [ix_temp_SECDAYPASSBK] ON #RSpassbk ([bookingId],[clientId]) INCLUDE ([recordStatus],[ldate],[scheduleStatus])

SELECT a.bookingId,MAX(activityId) activityId 
into #RSpba
FROM [LTD-DW2].[Novus_PROD].dbo.PassBookingActivity a WITH (NOLOCK)
join #RSpassbk p on p.bookingid = a.bookingID
GROUP BY a.bookingId



CREATE TABLE #RSVOMSData (
	runId INT
	,vehicleId INT
	,ldate INT
	,passengersOn INT
	,pickUpTime INT
	,dropOffTime INT
	,FundingProgram VARCHAR(2048)
	,Providers VARCHAR(2048)
	);
INSERT INTO #RSVOMSData  
SELECT pr.runId
	,isnull(pr.vehicleId,0) vehicleId
	,pb.ldate
    ,sum(len(peo.passengeronoff) - len(replace(peo.passengeronoff,'+',''))) passengersOn
	,ISNULL(peo.actualArrive, peo.estimatedArrive) pickUpTime
	,ISNULL(ped.actualDepart, ped.estimatedDepart) dropOffTime
	,pfp.name FundingProgram
	,cou.name Providers
FROM #RSpassbk pb WITH (NOLOCK)
INNER JOIN #RSpba
	pba ON pb.bookingId = pba.bookingId
INNER JOIN [LTD-DW2].[Novus_PROD].dbo.PassEvent peo WITH (NOLOCK)
	ON pb.bookingId = peo.bookingId
	AND peo.clientId = pb.clientId
	AND peo.eventActivity = 0
LEFT JOIN [LTD-DW2].[Novus_PROD].dbo.PassEvent ped WITH (NOLOCK) ON pb.bookingId = ped.bookingId
	AND ped.clientId = pb.clientId
	AND ped.eventActivity = 1
INNER JOIN [LTD-DW2].[Novus_PROD].dbo.PassRun pr WITH (NOLOCK) ON pr.runId = peo.runId
	AND ped.runId = pr.runId
	AND pr.recordStatus = 'A'
LEFT JOIN [LTD-DW2].[Novus_PROD].dbo.PassBookingFundingProgram pbfp WITH (NOLOCK) ON pbfp.activityId = pba.activityId
	AND pbfp.isEnabled = 1
LEFT JOIN [LTD-DW2].[Novus_PROD].dbo.PassFundingProgram pfp WITH (NOLOCK) ON pbfp.programId = pfp.programId
LEFT JOIN [LTD-DW2].[Novus_PROD].dbo.CmnOrgUnit cou WITH (NOLOCK) ON pr.providerId = cou.orgUnitId
WHERE pb.scheduleStatus = 10
	AND pb.recordStatus = 'A'
group by 
pr.runId
	,pr.vehicleId
	,pb.ldate
	,ISNULL(peo.actualArrive, peo.estimatedArrive) 
	,ISNULL(ped.actualDepart, ped.estimatedDepart) 
	,pfp.name 
	,cou.name



select ldate,left(HHMMSS,2) HH,max(current_runs) current_runs 
into #RSvomssource
from (	
select ldate,n,
left(CAST(DATEADD(SECOND,n,0) AS TIME),8) HHMMSS,
 count(distinct vehicleId) current_runs 
, sum(passengersOn) current_riders 
from (
select s.n , z.*
FROM #RSVOMSData z
 JOIN #RSsecdays s on s.ldate = z.ldate
and s.n >= pickUpTime 
and s.n <= dropOffTime 
) z2
 group by ldate,n ) y
 group by ldate,left(HHMMSS,2)
 order by ldate,left(HHMMSS,2), current_runs desc

 MERGE [rpt].[VOMS_DAILY_HOURLY_RS_byVehicle] t
 USING #RSvomssource s
 ON t.[ldate] = s.[ldate]
and t.[HH] = s.[HH]
WHEN NOT MATCHED THEN INSERT
           ([ldate]
           ,[HH]
           ,[current_runs] )
     VALUES (
            s.[ldate]
           ,s.[HH]
           ,s.[current_runs] ) 
WHEN MATCHED and
	s.[current_runs] <> t.[current_runs]
THEN UPDATE
	set t.[current_runs] = s.[current_runs]
OUTPUT $action into #RSOutputTbl9940;

declare @n int = (select isnull(count(*),0) from #RSOutputTbl9940 WITH (NOLOCK) where ActionName = 'Insert' group by ActionName )
declare @u int = (select isnull(count(*),0) from #RSOutputTbl9940 WITH (NOLOCK) where ActionName = 'Update' group by ActionName )
declare @d int = (select isnull(count(*),0) from #RSOutputTbl9940 WITH (NOLOCK) where ActionName = 'Delete' group by ActionName )


update ltd_dw.[process].[MergeLogs] 
set recInsert = isnull( @n, 0 )
,recUpdate = isnull(@u, 0)
,recDelete = isnull(@d, 0)
,[MergeEndDatetime] = sysdatetime()
   where mergecode = 'VOMS'
     and [ObjectDestination] = 'ltd_dw.rpt.VOMS_DAILY_HOURLY_RS_byVehicle'
	 AND [ObjectSource] = 'NOVUS'
	 AND [ObjectProgram] = 'ltd_dw.rpt.Get_VOMS_DAILY_HOURLY_RS_byVehicle'
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
