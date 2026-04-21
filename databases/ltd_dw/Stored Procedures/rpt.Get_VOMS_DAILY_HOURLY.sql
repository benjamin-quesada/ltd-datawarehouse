SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- test declare and range
CREATE   PROCEDURE [rpt].[Get_VOMS_DAILY_HOURLY]
@stDate INT,
@toDate INT
AS

/*
--------------LTD_GLOSSARY--------------------

CREATED:   20190829
AUTHOR :   B EICHBERGER
PURPOSE:   To produce hourly data reporting the maximum number of services provided per hour
		   with the goal of bringing the maximum rides per hour, day and eventually day and month
		   for NTD reporting.

		   Specific to Ridesource ***External Fleet***

CHANGEDON: 1/21/2020
 CHANGEBY: b eichberger
   CHANGE: Added error handling.
  
CHANGEDON: 8/16/2022
 CHANGEBY: b eichberger
   CHANGE: Just reconfirming that the links all were pointed to ltd-dw2 (was complete in June'22).

EXEC EXAMPLE: exec rpt.Get_VOMS_DAILY_HOURLY 20260210, 20260325

CHANGEDON: 3/25/2026
 CHANGEBY: b eichberger
   CHANGE: Updated syntax for drop tables, added temp table drop statements where missing
		   while reviewing for VOMS report and data issues. Rerunning this sproc for the period
		   in question (2/10/2026 to present, 20260210, 20260325) has repaired the data
		   inaccuracies.
  

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

--select @stDate = 20260209
--select @toDate = 20260210
---- end test


drop table if exists #OutputTbl9940
create table #OutputTbl9940 (ActionName varchar(32))

declare @workstartdt datetime = sysdatetime()

DROP table if exists #VOMSData;
DROP TABLE if exists #TimeTableCTE;
DROP TABLE if exists #seconds;
DROP TABLE if exists #secdays;
DROP TABLE if exists #passbk
drop table if exists #pba
drop table if exists #vomssource

SELECT TOP (86400) n = CONVERT(INT, ROW_NUMBER() OVER (ORDER BY s1.[object_id]))
INTO #seconds
FROM sys.all_objects AS s1 CROSS JOIN sys.all_objects AS s2
OPTION (MAXDOP 1);


select * 
into #secdays from #seconds s
cross join (select distinct ldate from [LTD-DW2].[Novus_PROD].dbo.PassBooking WITH (NOLOCK) where ldate between @stDate and @toDate) b
order by ldate,n

CREATE NONCLUSTERED INDEX [ix_temp_SECDAY] On tempdb.#secdays ([ldate],[n])

select * 
into #passbk from [LTD-DW2].[Novus_PROD].dbo.PassBooking pb WITH (NOLOCK)
where  pb.scheduleStatus = 10
AND pb.ldate IS NOT NULL
AND pb.ldate > 0
AND pb.recordStatus = 'A'
AND pb.ldate BETWEEN @stDate AND @toDate 

CREATE NONCLUSTERED INDEX [ix_temp_SECDAYPASSBK] ON #passbk ([bookingId],[clientId]) INCLUDE ([recordStatus],[ldate],[scheduleStatus])

SELECT a.bookingId,MAX(activityId) activityId 
into #pba
FROM [LTD-DW2].[Novus_PROD].dbo.PassBookingActivity a WITH (NOLOCK)
join #passbk p on p.bookingid = a.bookingID
GROUP BY a.bookingId


CREATE TABLE #VOMSData (
	runId INT
	,bookingId INT
	,ldate INT
	,passengersOn INT
	,pickUpTime INT
	,dropOffTime INT
	,FundingProgram VARCHAR(2048)
	,Providers VARCHAR(2048)
	);
INSERT INTO #VOMSData  
	SELECT pr.runId
	,pb.bookingId
	,pb.ldate
    ,sum(len(peo.passengeronoff) - len(replace(peo.passengeronoff,'+',''))) passengersOn
	,ISNULL(peo.actualArrive, peo.estimatedArrive) pickUpTime
	,ISNULL(ped.actualDepart, ped.estimatedDepart) dropOffTime
	,pfp.name FundingProgram
	,cou.name Providers
FROM #passbk pb WITH (NOLOCK)
INNER JOIN #pba
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
WHERE pr.runType = 4
	AND pb.scheduleStatus = 10
	AND pb.ldate IS NOT NULL
	AND pb.ldate > 0
	AND pb.recordStatus = 'A'
	AND pb.ldate BETWEEN @stDate AND @toDate 
	AND CASE 
		WHEN Len('1,2,5,6,7,8,9,11,14,700') > 0
			THEN pbfp.programId
		ELSE ''
		END IN ('1', '2', '5', '6', '7', '8', '9', '11', '14', '700')
	AND (
		CASE 
			WHEN Len('102,21,22,19,23,24,5,25,27,28,29,30,31,32,112,104,33,34,1,4,3,2,98,94,82,105,10,91,36,6,38,39,40,7,111,41,42,45,46,99,95,47,107,49,50,51,52') > 0
				THEN pr.providerId
			ELSE ''
			END IN ('102', '21', '22', '19', '23', '24', '5', '25', '27', '28', '29', '30', '31', '32', '112', '104', '33', '34', '1', '4', '3', '2', '98', '94', '82', '105', '10', '91', '36', '6', '38', '39', '40', '7', '111', '41', '42', '45', '46', '99', '95', '47', '107', '49', '50', '51', '52')
		OR pr.providerId IS NULL
		)	
group by pr.runId
	,pb.bookingId
	,pb.ldate
	,ISNULL(peo.actualArrive, peo.estimatedArrive)
	,ISNULL(ped.actualDepart, ped.estimatedDepart) 
	,pfp.name 
	,cou.name

select y.ldate
     , left(y.HHMMSS, 2) HH
     , max(y.current_runs) current_runs
into #vomssource
from
(
    select z2.ldate, z2.n, left(cast(dateadd(second, z2.n, 0) as time), 8) HHMMSS, count(distinct z2.bookingId) current_runs, sum(z2.passengersOn) current_riders
    from
		( select s.n, z.runId, z.bookingId, z.ldate, z.passengersOn, z.pickUpTime, z.dropOffTime, z.FundingProgram, z.Providers
        from #VOMSData z
            join #secdays s on s.ldate = z.ldate
                               and s.n >= z.pickUpTime
                               and s.n <= z.dropOffTime
		) z2
    group by z2.ldate, z2.n
) y
group by y.ldate, left(y.HHMMSS, 2)
order by y.ldate, left(y.HHMMSS, 2), current_runs desc;


merge [rpt].[VOMS_DAILY_HOURLY] t
using #vomssource s
on t.[ldate] = s.[ldate]
   and t.[HH] = s.[HH]
when not matched then
    insert
    (
        [ldate]
      , [HH]
      , [current_runs]
    )
    values
    (s.ldate, s.HH, s.current_runs)
when matched and s.[current_runs] <> t.[current_runs] then
    update set t.current_runs = s.[current_runs]
output $action into #OutputTbl9940;

declare @n int = (select isnull(count(*),0) from #OutputTbl9940 WITH (NOLOCK) where ActionName = 'Insert' group by ActionName )
declare @u int = (select isnull(count(*),0) from #OutputTbl9940 WITH (NOLOCK) where ActionName = 'Update' group by ActionName )
declare @d int = (select isnull(count(*),0) from #OutputTbl9940 WITH (NOLOCK) where ActionName = 'Delete' group by ActionName )


INSERT ltd_dw.[process].[MergeLogs] (
	   [MergeCode]
      ,[ObjectDestination]
      ,[ObjectSource]
      ,[ObjectProgram]
      ,[recInsert]
      ,[recUpdate]
      ,[recDelete]
      ,[MergeBeginDatetime]
	  ,MergeEndDatetime)
	  VALUES(
	  'VOMS', 'ltd_dw.rpt.VOMS_DAILY_HOURLY','LTD-DW2.Novus_PROD','ltd_dw.rpt.Get_VOMS_DAILY_HOURLY',ISNULL(@n,0), ISNULL(@u,0), ISNULL(@d,0), @workstartdt,SYSDATETIME())

drop table if exists #OutputTbl9940
DROP table if exists #VOMSData;
DROP TABLE if exists #TimeTableCTE;
DROP TABLE if exists #seconds;
DROP TABLE if exists #secdays;
DROP TABLE if exists #passbk
drop table if exists #pba
drop table if exists #vomssource


END TRY	  

BEGIN CATCH

       DECLARE @profile VARCHAR(255) = (
                    SELECT NAME
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
