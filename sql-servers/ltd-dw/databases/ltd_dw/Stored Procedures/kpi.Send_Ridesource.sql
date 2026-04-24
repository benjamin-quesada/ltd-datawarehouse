SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE   PROCEDURE [kpi].[Send_Ridesource] as
/*
CREATED:   20190829
AUTHOR :   B EICHBERGER
PURPOSE:   To produce HTML simple Ridesource stats using dbemail.
		   Demo for Robin Mayall 
CHANGEDON: 
 CHANGEBY:  
   CHANGE:  

EXEC EXAMPLE: exec kpi.Send_Ridesource

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



SELECT yearWk = cast(datepart(year,serviceDateDt) as varchar(10))+ right('00'+cast(datepart(wk,serviceDateDt) as varchar(3)),2)  
, *
,DATEADD(dd, -(DATEPART(dw, serviceDateDt)-1), serviceDateDt) [WeekStart]
,DATEADD(dd, 7-(DATEPART(dw, serviceDateDt)), serviceDateDt) [WeekEnd]
into -- select * from -- drop table 
#prepStatNovus --  order by yearwk,itineraryId
from (
		select * ,
			abs( case when isnull([leg0ScheduleTime],0) <> 0 and isnull([leg0ActualArrive],0) <> 0 then [leg0ScheduleTime] - [leg0ActualArrive]
				when isnull([leg0ScheduleTime],0) <> 0 and isnull([leg0ActualArrive],0) = 0 and isnull([leg0EstimatedArrive],0) <> 0 then [leg0ScheduleTime] - [leg0EstimatedArrive]
				else 0 end)  +
			abs( case when isnull([leg1ActualArrive],0) <> 0 and isnull([leg1EstimatedArrive],0) <> 0 then [leg1EstimatedArrive] - [leg1ActualArrive]
				else 0 end) timespanAll
				,
			case when ((
			abs( case when isnull([leg0ScheduleTime],0) <> 0 and isnull([leg0ActualArrive],0) <> 0 then [leg0ScheduleTime] - [leg0ActualArrive]
				when isnull([leg0ScheduleTime],0) <> 0 and isnull([leg0ActualArrive],0) = 0 and isnull([leg0EstimatedArrive],0) <> 0 then [leg0ScheduleTime] - [leg0EstimatedArrive]
				else 0 end)
			  +
			abs( case when isnull([leg1ActualArrive],0) <> 0 and isnull([leg1EstimatedArrive],0) <> 0 then [leg1EstimatedArrive] - [leg1ActualArrive]
				else 0 end)
				) /60 ) > 15 then 1 else 0 end  performanceIssue
		 from [ltd-dw2].ltd_novus.rpt.SERVICE_REPORT_SUMMARY 
			where record_deleted_flag = 0
				and serviceDateDt  >= dateadd(week, -17, getdate()) 
				and serviceDateDt <= dateadd(day, -1, getdate())
			   ) o 



select yearWk = cast(datepart(year,NOSHOW_DATE_DATE) as varchar(10))+ right('00'+cast(datepart(wk,NOSHOW_DATE_DATE) as varchar(3)),2)  
,* 
into -- drop table -- select * from 
#prepNoShowStatCCOs	
	from (
select *,NOSHOW_DATE_DATE = cast(convert(varchar(12),[NOSHOW_DATE] ,140) as date)
 from [ltd-dw2].ltd_novus.[cco].[COMBINED_NOSHOW_DATA]
where cast(convert(varchar(12),[NOSHOW_DATE] ,140) as date) >= dateadd(wk, -17, getdate()) 
			  and cast(convert(varchar(12),[NOSHOW_DATE] ,140) as date)  <= dateadd(day, -1, getdate())
			 	) i	 

select yearWk = cast(datepart(year,COMPLAINT_DATE_DATE) as varchar(10))+ right('00'+cast(datepart(wk,COMPLAINT_DATE_DATE) as varchar(3)),2)  
,* 
into -- drop table -- select * from 
#prepComplaintwStatCCOs from 
(	select * , COMPLAINT_DATE_DATE = cast(convert(varchar(12),[COMPLAINT_DATE] ,140) as date)
		from [ltd-dw2].ltd_novus.[cco].[COMBINED_COMPLAINT_DATA]
	where cast(convert(varchar(12),[COMPLAINT_DATE] ,140) as date) >= dateadd(wk, -17, getdate()) 
				  and cast(convert(varchar(12),[COMPLAINT_DATE] ,140) as date)  <= dateadd(day, -1, getdate())
			 ) q


			 
select itineraryId
, yearWk = cast(datepart(year,serviceDateDt) as varchar(10))+ right('00'+cast(datepart(wk,serviceDateDt) as varchar(3)),2) 
      ,max(isnull([ADDITIONAL_PASSENGERS],0)) [ADDITIONAL_PASSENGERS]
into -- drop table -- select * from 
#passengerAdd
	from (
		select c.itineraryId,c.serviceDateDt,
			ADDITIONAL_PASSENGERS = case when len(pe.passengerOnOff) - len(replace(pe.passengerOnOff,'+','')) <= 0 then 0 else 
						len(pe.passengerOnOff) - len(replace(pe.passengerOnOff,'+',''))-1 END
		from -- select top 100 * from 
		[LTD-DW2].[Novus_PROD].[dbo].PassEvent pe WITH (NOLOCK)
		 join #prepStatNovus c on c.bookingId = pe.bookingId
		 where passengerOnOff like '%+%'
		 --group by c.itineraryId
	) q
where isnull(ADDITIONAL_PASSENGERS,0) <> 0
group by itineraryId,cast(datepart(year,serviceDateDt) as varchar(10))+ right('00'+cast(datepart(wk,serviceDateDt) as varchar(3)),2) 


select yearWk, rn = row_number() OVER (order by YearWk) 
into #yearFilter
from (select distinct yearWk from #prepStatNovus) w

declare @sumAddPass INT = (select sum(ADDITIONAL_PASSENGERS) from #passengerAdd where additional_passengers > 0)
-- SUMMARY
select totalUniqueClientsServed = count(distinct clientId) -- may have had more than one ride of course
	 ,countAllTrips = count(distinct n.itineraryId)
	 ,totalPassAdded = @sumAddPass --+ count(distinct clientId)
	 ,milesTotalEst = sum(estimatedDistance)
	 ,milesTtlClaimed = sum(providerCostDistance)
	 ,EstVSActualMiles = sum(providerCostDistance)-sum(estimatedDistance)
	 ,milesAvgTrip = sum(n.providerCostDistance) / count(distinct n.itineraryId)  -- mmilesperTrip
	 ,vendorsActive = count(distinct providerName)
	 ,countOnTimeAll = count(distinct n.itineraryId) - sum(performanceIssue)
	 ,countOnTimePerc = 100*(count(distinct n.itineraryId) - sum(performanceIssue)) /(1.00*count(distinct n.itineraryId))
	 ,totalComplaintsRecd = (select count(distinct [CCO_ITI_KEY]) from #prepComplaintwStatCCOs )
	 ,totalNoShows = (select count(distinct [CCO_ITI_KEY]) from #prepNoShowStatCCOs )
into -- select * from -- drop table 
#summaryOverview
from #prepStatNovus n
join (select yearWk from #yearFilter where rn < 16) t on t.yearWk = n.yearWk

--where itineraryId = 2858511


-- CHARTED Closed Request Counts

-- SUMMARY WEEKLY

select n.yearWk
	,totalUniqueClientsServed = count(distinct clientId) -- may have had more than one ride of course
	 ,countAllTrips = count(distinct n.itineraryId)
	 ,countOnTimeAll = count(distinct n.itineraryId) - sum(performanceIssue)
	 ,totalPassAdded = (select sum(ADDITIONAL_PASSENGERS) from #passengerAdd where additional_passengers > 0 and yearWk = n.yearWk ) --+ count(distinct clientId)
	 ,milesTotalEst = sum(estimatedDistance)
	 ,milesTtlClaimed = sum(providerCostDistance)
	 ,EstVSActualMiles = sum(providerCostDistance)-sum(estimatedDistance)
	 ,milesAvgTrip = sum(n.providerCostDistance) / count(distinct n.itineraryId)  -- mmilesperTrip
	 ,vendorsActive = count(distinct providerName)
	 ,countOnTimePerc = 100*(count(distinct n.itineraryId) - sum(performanceIssue)) /(1.00*count(distinct n.itineraryId))
	 ,totalComplaintsRecd = (select count(distinct [CCO_ITI_KEY]) from #prepComplaintwStatCCOs where yearWk = n.yearWk )
	 ,totalNoShows = (select count(distinct [CCO_ITI_KEY]) from #prepNoShowStatCCOs where yearWk = n.yearWk )
into -- select * from -- drop table 
#summaryByWeekOverview
from #prepStatNovus n
join (select yearWk from #yearFilter where rn < 16) t on t.yearWk = n.yearWk
group by n.yearWk




create table #setup9919 (rn INT identity(1,1),column_names varchar(90), [ordinal_position] smallint, datatype varchar(90))
insert #setup9919 (column_names, ordinal_position, datatype)
select column_name, [ordinal_position], DATA_TYPE
FROM TEMPDB.INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME LIKE '%#summaryByWeekOverview%'


-- drop table -- select * from #htmlChartTableRS
create table #htmlChartTableRS (rn INT identity(1,1), RowName1 varchar(90), Group1 varchar(90), Value1 float )
insert -- drop table
#htmlChartTableRS (RowName1, Group1, Value1)
 select distinct RowName,u.yearWk, u.totalUniqueClientsServed
 from (
 SELECT RowName =  ltrim(stuff((
    SELECT ' Total Unique Clients Served by Year and Week of Year'
    FROM #setup9919 WHERE column_names = 'totalUniqueClientsServed'
    FOR XML PATH('')
    ), 1, 1, ''))
		from #setup9919 ) o
	Cross APPLY (select yearWk, totalUniqueClientsServed from #summaryByWeekOverview) u
order by rowname desc,yearWk
-- select * from #htmlChartTableRS
-- drop table #chartoutputRS 

create table #chartoutputRS (rn INT, RowName1 varchar(90), Group1 varchar(90), RPT_OUTPUT varchar(max))

declare @i int = 1
declare @r int = (select max(rn) from #htmlChartTableRS)
declare @rn1 varchar(90)
declare @rn2 varchar(90)
declare @rn INT = 1
declare @v1 float
declare @barchar varchar(1) = '?'
Declare @stringIt varchar(max) = ''

WHILE @i < @r
BEGIN


select @stringIt = ''

SELECT @rn1 = (select RowName1 FROM #htmlChartTableRS where rn = @i)
SELECT @rn2 = (select Group1 FROM #htmlChartTableRS where rn = @i)
select @v1 = (select value1 from #htmlChartTableRS where rn = @i)

select @stringit = (select replicate(@barchar,(value1 *.01)) from #htmlChartTableRS where rn = @i)

Insert #chartoutputRS (rn, RowName1, Group1, RPT_OUTPUT)
select @i, RowName1, Group1, @stringIt +' '+ cast(round(@v1,2) as varchar(8))+'' from #htmlChartTableRS where rn = @i

select @stringIt = ''
 
select @i = @i + 1
If @i > @r
	BREAK
	ELSE CONTINUE

END


declare @htmlmax1 nvarchar(max) = ''

declare @header1 varchar(max) = '|Summary of Ridesource KPIs through the Most Recent 15 Weeks||'
select @htmlmax1 =  @htmlmax1 + 
 (SELECT CONVERT(NVARCHAR(MAX), (SELECT
    (SELECT @header1 FOR XML PATH(''), TYPE) AS 'caption',
    (SELECT 'Sort' as th, 'Metric' AS th, 'KPI.............' AS th FOR XML RAW('tr'), ELEMENTS, TYPE) AS 'thead',
     (select s as td, a as td, g as td from (
		SELECT 1 as s,'Total Unique Clients Served' a, 'QQQ'+cast(cast(totalUniqueClientsServed as INT) as varchar(20)) AS g FROM #summaryOverview 
		UNION
		SELECT 2 as s,'Count of All Trips' a, 'QQQ'+cast(cast(countAllTrips as INT) as varchar(20)) AS g FROM #summaryOverview 
		UNION
		SELECT 3 as s,'Avg Miles Per Trip' a, 'QQQ'+cast(cast(milesAvgTrip as decimal(10,2)) as varchar(20)) AS g FROM #summaryOverview 
		UNION
		SELECT 4 as s,'Vendors Active in this Period' a, 'QQQ'+cast(cast(vendorsActive as INT) as varchar(20)) AS g FROM #summaryOverview
		UNION 
		SELECT 5 as s,'Complaints Received in this Period' a, 'QQQ'+cast(cast(totalComplaintsRecd as INT) as varchar(20)) AS g FROM #summaryOverview
		UNION 
		SELECT 6 as s,'Total Count of Trip No Shows' a, 'QQQ'+cast(cast(totalNoShows as INT) as varchar(20)) AS g FROM #summaryOverview
		UNION 
		SELECT 7 as s,'On Time Percentage' a, 'QQQ'+cast(cast(countOnTimePerc as decimal(10,2)) as varchar(20)) + '%' AS g FROM #summaryOverview ) x
    FOR XML RAW('tr'), ELEMENTS, TYPE
    ) AS 'tbody'
  FOR XML PATH(''), ROOT('table'))));



declare @htmlmax nvarchar(max) = ''

declare @header varchar(max) = '|Total Count of Unique Clients Served|Most Recent Week at the Top||'
select @htmlmax =  @htmlmax + 
 (SELECT CONVERT(NVARCHAR(MAX), (SELECT
    (SELECT @header FOR XML PATH(''), TYPE) AS 'caption',
    (SELECT 'Year and Week|of Year' AS th, 'Clients Served|by Week' AS th FOR XML RAW('tr'), ELEMENTS, TYPE) AS 'thead',
    (
    SELECT top 15 Group1 AS td, RPT_OUTPUT as td
      FROM #chartoutputRS AS c
      ORDER BY rn DESC
    FOR XML RAW('tr'), ELEMENTS, TYPE
    ) AS 'tbody'
  FOR XML PATH(''), ROOT('table'))));

  DECLARE @msgAll nvarchar(max) = ''

select @msgAll = @msgAll + 
'<style>
thead,
tfoot {
    background-color: #3f87a6;
    color: #fff;
    text-align: left;
}

tbody {
    background-color: #3f87a6;
}

caption {
    padding: 8px 8px 12px 12px;
    color: #000;
    text-align: left;
    caption-side: center;
	font-weight: 900;
    font-size: 13px;
	font-weightsize: 900;
	white-space: nowrap;
}

table {
    border-collapse: collapse;
    border: 2px solid #c8c8c8;
    letter-spacing: 0px;
	border-spacing: 2px;
    font-family: sans-serif;
    font-size: 11px;
	white-space: nowrap;
}

td,
th {
    border: 1px solid rgb(190, 190, 190);
    padding: 2px 3px;
    text-align: left;
	white-space: nowrap;
}

.bar {
  letter-spacing: -5px;
}

.alignRight {
  text-align: right;
}

.conditRed {
  color: #e60000;
}
.conditOrange {
  color: #ffa033;
}
.conditGrn {
  color: #33cc33;
}
.foots {
    font-family: sans-serif;
    font-size: 9px;
}
</style>'

select @msgAll = @msgAll + 
(select replace(replace(@htmlmax1,'|','<br>'),'<td>QQQ','<td class="alignRight">'))
+' 
<br><br>'
+ 
(select replace(replace(replace(@htmlmax,'|','<br>'),'?','<span>&#9608;</span>'),',<td><span>','<td class="bar"><span>'))
+' 
<br><br>
<p class="foots">For information about these KPIs email: support@ltd.org<br><br>
Confidentiality Statement: The contents of this e-mail and any attachments are intended solely for the addressee.  The information may also be confidential and/or legally privileged.  This transmission is sent for the sole purpose of delivery to the intended recipient.  If you have received this transmission in error, any use, reproduction, or dissemination of this transmission is strictly prohibited.  If you are not the intended recipient, please immediately notify the sender by reply e-mail, support@ltd.org and delete this message and its attachments, if any.  E-mail is covered by the Electronic Communications Privacy Act, 18 USC SS 2510-2521 and is legally privileged. Messages to and from this email may also be exempt from public disclosure under 49 CFR Part 15.15(b) as Sensitive Security Information.'

declare @headerClean varchar(90) = 'Ridesource Weekly KPIs'
--select @headerClean = (select substring(replace(replace(@header,'|',' - '),' -  - ',''),4,999))

--select @msgAll

exec msdb..sp_send_dbmail @recipients = 'barb.eichberger@ltd.org;' , -- 'robin.mayall@ltd.org', -- would like to automate next, prepare a sign up sheet in power bi report server for email addresses
  @blind_copy_recipients ='barb.eichberger@ltd.org' ,
  @subject = @headerClean, 
  @body_format = 'html',
  @from_address = 'Automated KPI Emails <support@ltd.org>',
  @body = @msgAll




  
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
