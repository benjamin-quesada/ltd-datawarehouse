SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [kpi].[Send_InformationTechnology] 
@recip varchar(max) NULL
as
/*
CREATED:   20190829
AUTHOR :   B EICHBERGER
PURPOSE:   To produce HTML simple IT kpis using dbemail.
		    
CHANGEDON: 20221004
 CHANGEBY: B EICHBERGER	
   CHANGE: Exclude Cancelled Work Tickets

EXEC EXAMPLE: exec kpi.Send_InformationTechnology 'barb.eichberger@ltd.org' --' -- robin.mayall@ltd.org;

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

--declare @recip NVARCHAR(900)
if @recip is null
BEGIN
SELECT @recip = 'barb.eichberger@gmail.com;'
-- PLANNED FOR SELF SERVICE
--select @recip = (
--SELECT STUFF(
--             (SELECT ';' + [kpi_user_email] 
--              FROM (select distinct [kpi_user_email] from [kpi].[kpi_controls] 
--					where kpi_nbr = 2
--					and getdate() between kpi_start_dt and kpi_end_dt
--					) t1
--              FOR XML PATH (''))
--             , 1, 1, ''))
END
			 
--declare @weekstrt int
--declare @weekend int

--select @weekend = (select cast(datepart(year,dateadd("wk",-1,getdate())) as varchar(10))+ right('00'+cast(datepart(wk,dateadd("wk",-1,getdate())) as varchar(3)),2))
--select @weekstrt = (select cast(datepart(year,dateadd("wk",-16,getdate())) as varchar(10))+ right('00'+cast(datepart(wk,dateadd("wk",-16,getdate())) as varchar(3)),2))


Select q.[RequestId]
	  ,q.[status]
      ,q.[ncreated]
      ,q.[opened]
      ,q.[closed]
      ,q.[workdatemin]
      ,q.[workdatemax]
      ,q.[xcreated]
      ,q.[timespentMinutes]
      ,q.[daysworked]
      ,q.[daysOpen]
      ,q.[weekendMinutes]
,yearWkOpened = cast(datepart(year,opened) as varchar(12)) + right('00'+cast(datepart(wk,opened) as varchar(3)),2)
,yearWkClosed = cast(datepart(year,closed) as varchar(12)) + right('00'+cast(datepart(wk,closed) as varchar(3)),2)
,openedYYMM = cast(datepart(year,opened) as varchar(12)) + right('00'+cast(datepart(month,opened) as varchar(3)),2)
,closedYYMM = cast(datepart(year,closed) as varchar(12)) + right('00'+cast(datepart(month,closed) as varchar(3)),2)
,closedSameWeek = case when cast(datepart(year,opened) as varchar(12)) + right('00'+cast(datepart(wk,opened) as varchar(3)),2)
					=
				  cast(datepart(year,closed) as varchar(12)) + right('00'+cast(datepart(wk,closed) as varchar(3)),2)
					then 1 else 0 end
,minutesdatediff = datediff(minute,cast(ncreated as datetime) ,cast(xcreated as datetime)) 
,ticketsWkdWork = case when weekendMinutes <> 0 then 1 else 0 end
,hoursToFirstWork = case when 
						case when isnull(q.[timespentMinutes],0.0) > 0 then datediff(minute,ncreated,workdatemin) else null end < 0 
							then 0 
						else
						case when isnull(q.[timespentMinutes],0.0) > 0 then datediff(minute,ncreated,workdatemin) else null end/60.0 end 
,minutesToFirstWork = case when 
						case when isnull(q.[timespentMinutes],0.0) > 0 then datediff(minute,ncreated,workdatemin) else null end < 0 
							then 0 
						else
						case when isnull(q.[timespentMinutes],0.0) > 0 then datediff(minute,ncreated,workdatemin) else null end end
into -- drop table -- select * from 
		 #prepStat
	from (
select RequestId, min(created) ncreated, min(opened) opened, max(closed) closed, max(workdate) workdatemax
, min(workdate) workdatemin
, max(created) xcreated
, status
, sum(timespent*60) timespentMinutes
, count(distinct workdate) as daysworked, datediff(day,min(opened),max(created)) daysOpen
, weekendMinutes = sum(isnull(weekendWorked,0))*60.00
	 	 from (
			SELECT Id as RequestId
				  ,cast(workdate as datetime) workdate
				  ,cast(opened as datetime) opened
				  ,cast(closed as datetime) closed
				  ,cast(created as datetime) created
				  ,yyyywk = left(convert(varchar(12),created,112),6)
				  ,case when datepart(dw,workdate) in (1,7) then [Time Spent] end weekendWorked
				  --,daysDatediff = datediff(day,cast(opened as datetime) ,cast(closed as datetime)) 
				   ,[TimeSpent] = case when [Time Spent] = 0 then .08 else [Time Spent] end
				   ,[Status]
			 -- select *  
			 FROM [rpt].[serivicedesk_all]
			 -- select * from [rpt].[serivicedesk_workByCreateDate]
			 Where 1=1
			  --and Id = 10725
			  and created >= dateadd(wk, -17, getdate()) 
			  and opened <= dateadd(day, -1, getdate())
			  and [Time Spent Technician] <> 'undefined'
			  AND [Status] <> 'cancelled'
			  --and left(convert(varchar(12),created,112),6) >= @weekstrt
			  --and left(convert(varchar(12),created,112),6) <= @weekend
			  --ORDER BY cast(workdate as datetime) desc
			   ) o GROUP BY RequestId, [status]
			) q
ORDER BY q.ncreated DESC


select sum(case when [Time Spent] = 0 then .08 else [Time Spent] end*60) timeSpentMinutes
,count(distinct Id) CountInStatus 
into -- drop table -- select *   
#StatusNotClosedAll
FROM [rpt].[serivicedesk_all] 
where created >= '1/1/2018'
and [Time Spent Technician] <> 'undefined'
and [Status] not in ('implementation - completed','closed','completed','resolved','cancelled') 


select sum(case when [Time Spent] = 0 then .08 else [Time Spent] end*60) timeSpentMinutes
,count(distinct Id) CountInStatus 
into -- drop table -- select *   
#StatusClosedAll
FROM [rpt].[serivicedesk_all] 
where created >= '1/1/2018'
and [Time Spent Technician] <> 'undefined'
and [Status] in ('implementation - completed','closed','completed','resolved') 

select * 
into -- drop table -- select * from   
#StatusClosedWeekly
from (
select rn = row_number() OVER (Partition by 1 order by yyyyWk desc)
,* ,
TimeSpentPerTicket = (timeSpentMinutes)/(CountInStatus)
from (
select cast(datepart(year,closed) as varchar(12)) + right('00'+cast(datepart(wk,closed) as varchar(3)),2) as yyyyWk
,sum(case when 
	cast(datepart(year,closed) as varchar(12)) + right('00'+cast(datepart(wk,closed) as varchar(3)),2) 
	= 
	cast(datepart(year,created) as varchar(12)) + right('00'+cast(datepart(wk,created) as varchar(3)),2) then 1 else 0 end)
	as closedSameWeek
, sum(case when [Time Spent] = 0 then .08 else [Time Spent] end*60) timeSpentMinutes
,count(distinct Id) CountInStatus
FROM [rpt].[serivicedesk_all] 
where created >= '1/1/2018'
and created >= dateadd(wk, -17, getdate()) 
and opened <= dateadd(day, -1, getdate()) 
and [Time Spent Technician] <> 'undefined'
and [Status] in ('implementation - completed','closed','completed','resolved') 
group by cast(datepart(year,closed) as varchar(12)) + right('00'+cast(datepart(wk,closed) as varchar(3)),2) 
) i
)p
where rn <> 1 and rn <= 16


-- SUMMARY
select rcAllOpened = count(distinct RequestId)
	 ,closedSameWeek = sum(closedSameWeek)
	 ,weekendMinutes = sum(weekendMinutes)
	 ,ticketsWkdWork = sum(ticketsWkdWork)
into -- select * from -- drop table
#summaryOverview
from #prepStat

-- CHARTED **Closed** Request Counts
select * 
into -- select * from 
#summaryByWeekOverview
from (
select rn = row_number() OVER (Partition by 1 order by calyearWk desc) 
		,calyearWk as yearWkClosed
		,countClosed = count(*)
		,AVGminutesWorkSpentClosed = sum(timespentMinutes) / case when isnull(count(distinct RequestId),0) = 0 THEN 0 
	 													else count(distinct RequestId) end  -- minutes
		,AVGminutesWorkSpentRunningClosed = sum(timespentMinutes) / sum(case when isnull(count(distinct RequestId),0) = 0 THEN 0 
	 													else count(distinct RequestId) end)  OVER (order by calyearWk)
from #prepStat p
 LEFT JOIN (SELECT yearWk = cast([Year] as varchar(6)) + right('00'+cast([WeekOfYear] as varchar(2)),2) ,
				calyearWk = cast([Year] as varchar(6)) + right('00'+cast([WeekOfYear] as varchar(2)),2) + ' - '+
				   CONVERT(varchar,(DATEADD(week, DATEDIFF(week, -1, [CALENDAR_DATE]), -1)),101) 
			  FROM [ltd_dw].[tm].[DW_CALENDAR]
			 where DayOfWeekNbr = 1) d on d.yearWk = p.yearWkClosed
where [status] in ('implementation - completed','closed','completed','resolved') 
group by calyearWk
) x where rn <> 1 and rn <= 17
order by yearWkClosed	


create table #setup9911 (rn INT identity(1,1),column_names varchar(90), [ordinal_position] smallint, datatype varchar(90))
insert #setup9911 (column_names, ordinal_position, datatype)
select column_name, [ordinal_position], DATA_TYPE
FROM TEMPDB.INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME LIKE '%summaryByWeekOverview%'


create table #htmlChartTable (rn INT identity(1,1), RowName1 varchar(90), Group1 varchar(90), Value1 float )
insert #htmlChartTable (RowName1, Group1, Value1)
 select distinct RowName,u.yearWkClosed, u.countClosed
 from (
 SELECT RowName = 'Count Requests Closed ' + ltrim(stuff((
    SELECT ' by ' + cast(column_names as varchar(max))
    FROM #setup9911 WHERE datatype = 'varchar' --and rn = @i
    FOR XML PATH('')
    ), 1, 1, ''))
		from #setup9911 ) o
	Cross APPLY (select yearWkClosed, countClosed from #summaryByWeekOverview) u


create table #chartoutput (rn INT, RowName1 varchar(90), Group1 varchar(90), RPT_OUTPUT varchar(max))

declare @i int = 1
declare @r int = (select max(rn) from #htmlChartTable)
declare @rn1 varchar(90)
declare @rn2 varchar(90)
declare @n INT = 1
declare @rn INT = 1
declare @v1 float
declare @barchar varchar(1) = '?'
Declare @stringIt varchar(max) = ''

WHILE @i < @r
BEGIN

SELECT @rn1 = (select RowName1 FROM #htmlChartTable where rn = @i)
SELECT @rn2 = (select Group1 FROM #htmlChartTable where rn = @i)
select @v1 = (select value1 from #htmlChartTable where rn = @i)
select @stringit = (select replicate(@barchar,value1) from #htmlChartTable where rn = @i)

	 
Insert #chartoutput (rn, RowName1, Group1, RPT_OUTPUT)
select @i, RowName1, Group1, @stringIt +' '+ cast(round(@v1,2) as varchar(8)) from #htmlChartTable where rn = @i


	 select @stringIt = ''
 
select @i = @i + 1
If @i > @r
	BREAK
	ELSE CONTINUE

END


declare @htmlmax1 nvarchar(max) = ''

declare @header1 varchar(max) = '|Summary of Information Technology KPIs||'
select @htmlmax1 =  @htmlmax1 + 
 (SELECT CONVERT(NVARCHAR(MAX), (SELECT
    (SELECT @header1 FOR XML PATH(''), TYPE) AS 'caption',
    (SELECT 'Sort' as th, 'Metric' AS th, 'KPI.............' AS th FOR XML RAW('tr'), ELEMENTS, TYPE) AS 'thead',
     (select s as td, a as td, g as td from (
		SELECT 1 as s,'Count all Closed Tickets since 1/1/2018' a, 'QQQ'+cast(CountInStatus as varchar(20)) AS g FROM #StatusClosedAll 
		UNION 
		SELECT 2 as s,'Count All Currently Open Tickets' a, 'QQQ'+cast(CountInStatus as varchar(20)) AS g FROM #StatusNotClosedAll
		UNION 
		SELECT 3 as s,'Avg Time (hours) Worked on (all since 1/1/2018) Currently Open Tickets' a, 'QQQ'+cast(cast((timeSpentMinutes/60.00)/(CountInStatus) as decimal(10,2)) as varchar(20)) AS g FROM #StatusNotClosedAll 
		UNION 
		SELECT 4 as s,'Avg Time (hours) Worked In Last 15 Weeks of Closed Tickets' a, 'QQQ'+cast(cast(avg(timeSpentPerTicket/60.00) as decimal(10,2)) as varchar(20)) AS g FROM #StatusClosedWeekly 
		UNION
		SELECT 5 as s,'In last 15 Weeks Percentage of Tickets Closed in Same Week Requested' a, 'QQQ'+cast(cast((sum(closedSameWeek*1.00)/sum(countInStatus)*1.00)*100 as decimal(10,1)) as varchar(22))+'%' as g from #StatusClosedWeekly
		--cast(round(closedSameWeek,2) as varchar(20)) AS g FROM #summaryOverview 
		UNION
		SELECT 6 as s,'Count Tickets with Weekend Time' a, 'QQQ'+cast(cast(ticketsWkdWork as INT) as varchar(20)) AS g FROM #summaryOverview
		UNION 
		SELECT 7 as s,'All Weekend Time (hours) Worked' a, 'QQQ'+cast(cast(weekendMinutes/60.00 as decimal(10,2)) as varchar(20)) AS g FROM #summaryOverview
		) x
		FOR XML RAW('tr'), ELEMENTS, TYPE
    ) AS 'tbody'
  FOR XML PATH(''), ROOT('table'))));



declare @htmlmax nvarchar(max) = ''

declare @header varchar(max) = '|IT KPIs and Service Requests Closed by Year and Week of Year||'
select @htmlmax =  @htmlmax + 
 (SELECT CONVERT(NVARCHAR(MAX), (SELECT
    (SELECT @header FOR XML PATH(''), TYPE) AS 'caption',
    (SELECT 'Year and Week|of Year' AS th, 'Requests Closed|by Week' AS th FOR XML RAW('tr'), ELEMENTS, TYPE) AS 'thead',
    (
    SELECT top 15 Group1 AS td, RPT_OUTPUT as td
      FROM #chartoutput AS c
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
<br><br><a href="http://ltd-test-bi/reports/powerbi/IT%20and%20ITS/IT%20Service%20Completion%20Dashboard%20v2">IT Dashboard</a>
<br><br>
<p class="foots">For information about these KPIs: support@ltd.org<br><br>
Confidentiality Statement: The contents of this e-mail and any attachments are intended solely for the addressee.  The information may also be confidential and/or legally privileged.  This transmission is sent for the sole purpose of delivery to the intended recipient.  If you have received this transmission in error, any use, reproduction, or dissemination of this transmission is strictly prohibited.  If you are not the intended recipient, please immediately notify the sender by reply e-mail, support@ltd.org and delete this message and its attachments, if any.  E-mail is covered by the Electronic Communications Privacy Act, 18 USC SS 2510-2521 and is legally privileged. Messages to and from this email may also be exempt from public disclosure under 49 CFR Part 15.15(b) as Sensitive Security Information.'

declare @headerClean varchar(90) = ''
select @headerClean = (select substring(replace(replace(@header,'|',' - '),' -  - ',''),4,999))

--select @msgAll

exec msdb..sp_send_dbmail @recipients = @recip, -- 'robin.mayall@ltd.org', -- would like to automate next, prepare a sign up sheet in power bi report server for email addresses
  @blind_copy_recipients ='barb.eichberger@ltd.org',
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
