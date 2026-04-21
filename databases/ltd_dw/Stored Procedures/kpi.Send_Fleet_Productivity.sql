SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [kpi].[Send_Fleet_Productivity] as
/*
CREATED:   20201130
AUTHOR :   B EICHBERGER
PURPOSE:   To produce HTML simple IT kpis using dbemail.
		   Fleet Performance to Planning with NTD KPI Demo for Robin Mayall 
CHANGEDON: 
 CHANGEBY:  
   CHANGE:  

EXEC EXAMPLE: exec kpi.Send_Fleet_Productivity

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


IF OBJECT_ID('tempdb.dbo.##prepStatF', 'U') IS NOT NULL
  DROP TABLE dbo.##prepStatF




declare @weekstrt int
declare @weekend int

select @weekend = (select cast(datepart(year,dateadd("wk",-1,getdate())) as varchar(10))+ right('00'+cast(datepart(wk,dateadd("wk",-1,getdate())) as varchar(3)),2))
select @weekstrt = (select cast(datepart(year,dateadd("wk",-16,getdate())) as varchar(10))+ right('00'+cast(datepart(wk,dateadd("wk",-16,getdate())) as varchar(3)),2))

select *
,yearWk = cast(datepart(year,the_date) as varchar(10)) + right('00'+ cast(datepart("wk",the_date) as varchar(3)),2 )
into ##prepStatF      
  from [LTD-TMDATA].ltd_db.[dbo].ntd_stats_v
  where cast(datepart(year,the_date) as varchar(10)) + right('00'+ cast(datepart("wk",the_date) as varchar(3)),2 ) Between @weekstrt and @weekend
 

 -- select * from ##prepStat



---- USE TO COLOR CODE HTML OUTPUT
--declare @maxnd int = (select isnull(max(OutofServiceWeekYr),0) from (select yearWk,description_lc, sum(OutofServiceWeekYr) OutofServiceWeekYr from ##stageRoadCalls group by yearWk,description_lc) x)
--declare @minnd int = (select isnull(min(OutofServiceWeekYr),0) from (select yearWk,description_lc, sum(OutofServiceWeekYr) OutofServiceWeekYr from ##stageRoadCalls group by yearWk,description_lc) x)
--declare @maxnl int = (select isnull(max(OutofServiceWeekYr),0) from (select yearWk,ltd_bus_class, sum(OutofServiceWeekYr) OutofServiceWeekYr from ##stageRoadCalls group by yearWk,ltd_bus_class) x)
--declare @minnl int = (select isnull(min(OutofServiceWeekYr),0) from (select yearWk,ltd_bus_class, sum(OutofServiceWeekYr) OutofServiceWeekYr from ##stageRoadCalls group by yearWk,ltd_bus_class) x)

--select @maxnd , @minnd, @maxnl, @minnd 



select 
avg_sched_in_service_hours_all = avg(1.00*sched_in_service_hours),
avg_actual_in_service_hours_all = avg(1.00*actual_in_service_hours),
	[avg_total_hrs_actual_pct_of_sched_all] = cast(sum(1.00*actual_total_hours) / sum(1.00*sched_total_hours) as decimal(10,4)) ,
avg_sched_in_service_hours_emx = avg(case when emx = 'y' then sched_in_service_hours else 0.00 end) ,
avg_actual_in_service_hours_emx = avg(case when emx = 'y' then actual_in_service_hours else 0.00 end) ,
	[avg_in_service_hrs_actual_pct_of_sched_emx] =cast(sum(case when emx = 'y' then 1.00*actual_in_service_hours else 0 end) / sum(case when emx = 'y' then 1.00*sched_in_service_hours else 0 end) as decimal(10,4)),
avg_sched_revenue_hours_all = avg(1.00*sched_rev_hours),
avg_actual_revenue_hours_all = avg(1.00*actual_rev_hours),
	[avg_rev_miles_actual_pct_of_sched_all] = cast((sum(1.00*actual_rev_hours) / sum(1.00*sched_rev_hours)) as decimal(10,4)) ,
avg_sched_revenue_hours_emx = avg(case when emx = 'y' then 1.00*sched_rev_hours else 0.00 end) ,
avg_actual_revenue_hours_emx = avg(case when emx = 'y' then 1.00*actual_rev_hours else 0.00 end) ,
	[avg_rev_miles_actual_pct_of_sched_emx] = cast(sum(case when emx = 'y' then actual_rev_hours else 0.00 end) / sum(case when emx = 'y' then sched_rev_hours else 0.00 end) as decimal(10,4)) ,
avg_schedule_rev_miles_all = avg(1.00*sched_rev_miles),
avg_schedule_total_miles_all = avg(1.00*sched_total_miles),
avg_actual_total_miles_all = avg(1.00*actual_total_miles),
    [avg_total_miles_actual_pct_of_sched] = cast((sum(1.00 * actual_total_miles) / sum(1.00 * sched_total_miles))  as decimal(10,4)) ,  
avg_schedule_rev_miles_emx = avg(case when emx = 'y' then 1.00*sched_rev_miles else 0.00 end),
avg_schedule_total_miles_emx = avg(case when emx = 'y' then 1.00*sched_total_miles else 0.00 end),
avg_actual_total_miles_emx = avg(case when emx = 'y' then 1.00*actual_total_hours else 0.00 end) ,
	[avg_total_miles_actual_pct_of_total_emx] = cast((sum(case when emx = 'y' then actual_total_miles else 0.00 end) / sum(case when emx = 'y' then sched_total_miles else 0.00 end)) as decimal(10,4)) ,
[passenger_miles] = sum(passenger_miles) ,
[avg_passenger_miles] = avg(passenger_miles) ,
[avg_trip_len]  = cast((1.00 * sum(passenger_miles) / sum(boardings)) as numeric(9,2)) 

,[ons_per_sched_in_srv_hr]  = sum(1.0*boardings) / sum(sched_in_service_hours) 
,[ons_per_actual_in_srv_hr] = sum(1.0*boardings) / sum(actual_in_service_hours) 
,[ons_per_sched_rev_hr]     = sum(1.0*boardings) / sum(sched_rev_hours)
,[ons_per_actual_rev_hr]    = sum(1.0*boardings) / sum(actual_rev_hours)
,[ons_per_sched_total_hr]   = sum(1.0*boardings) / sum(sched_total_hours)
,[ons_per_actual_total_hr]  = sum(1.0*boardings) / sum(actual_total_hours)
       
,[ons_per_sched_rev_mile]    = cast(1.0 * sum(boardings) / sum(sched_rev_miles) as numeric(9,2))
,[ons_per_actual_rev_mile]   = cast(1.0 * sum(boardings) / sum(actual_rev_miles) as numeric(9,2))
,[ons_per_sched_total_mile]  = cast(1.0 * sum(boardings) / sum(sched_total_miles) as numeric(9,2))  
,[ons_per_actual_total_mile] = cast(1.0 * sum(boardings) / sum(actual_total_miles)  as numeric(9,2)) 
       
,[pms_per_sched_in_srv_hr]  = sum(passenger_miles) / sum(sched_in_service_hours)  
,[pms_per_actual_in_srv_hr] = sum(passenger_miles) / sum(actual_in_service_hours) 
,[pms_per_sched_rev_hr]     = sum(passenger_miles) / sum(sched_rev_hours)         
,[pms_per_actual_rev_hr]    = sum(passenger_miles) / sum(actual_rev_hours)        
,[pms_per_sched_total_hr]   = sum(passenger_miles) / sum(sched_total_hours)       
,[pms_per_actual_total_hr]  = sum(passenger_miles) / sum(actual_total_hours)      

,[pmss_per_sched_rev_mile]   = cast(1.0 * sum(passenger_miles) / sum(sched_rev_miles) as numeric(9,2))
,[pms_per_actual_rev_mile]   = cast(1.0 * sum(passenger_miles) / sum(actual_rev_miles) as numeric(9,2))   
,[pms_per_sched_total_mile]  = cast(1.0 * sum(passenger_miles) / sum(sched_total_miles) as numeric(9,2))  
,[pms_per_actual_total_mile] = cast(1.0 * sum(passenger_miles) / sum(actual_total_miles) as numeric(9,2)) 

into -- select * from   -- drop table 
#summaryOverview -- select * 
from ##prepStatF

-- SUMMARY
select yearWk,
avg_sched_in_service_hours_all = avg(1.00*sched_in_service_hours),
avg_actual_in_service_hours_all = avg(1.00*actual_in_service_hours),
	[avg_total_hrs_actual_pct_of_sched_all] = cast(sum(1.00*actual_total_hours) / sum(1.00*sched_total_hours) as decimal(10,4)) ,
avg_sched_in_service_hours_emx = avg(case when emx = 'y' then sched_in_service_hours else 0.00 end) ,
avg_actual_in_service_hours_emx = avg(case when emx = 'y' then actual_in_service_hours else 0.00 end) ,
	[avg_total_hrs_actual_pct_of_sched_emx] =cast(sum(case when emx = 'y' then 1.00*actual_total_hours else 0 end) / sum(case when emx = 'y' then 1.00*sched_total_hours else 0 end) as decimal(10,4)),
avg_sched_revenue_hours_all = avg(1.00*sched_rev_hours),
avg_actual_revenue_hours_all = avg(1.00*actual_rev_hours),
ttl_sched_revenue_hours_all = sum(1.00*sched_rev_hours),
ttl_actual_revenue_hours_all = sum(1.00*actual_rev_hours),
	[avg_rev_miles_actual_pct_of_sched_all] = cast((sum(1.00*actual_rev_hours) / sum(1.00*sched_rev_hours)) as decimal(10,4)) ,
avg_sched_revenue_hours_emx = avg(case when emx = 'y' then 1.00*sched_rev_hours else 0.00 end) ,
avg_actual_revenue_hours_emx = avg(case when emx = 'y' then 1.00*actual_rev_hours else 0.00 end) ,
	[avg_rev_miles_actual_pct_of_sched_emx] = cast(sum(case when emx = 'y' then actual_rev_hours else 0.00 end) / sum(case when emx = 'y' then sched_rev_hours else 0.00 end) as decimal(10,4)) ,
avg_schedule_rev_miles_all = avg(1.00*sched_rev_miles),
avg_schedule_total_miles_all = avg(1.00*sched_total_miles),
avg_actual_total_miles_all = avg(1.00*actual_total_miles),
    [avg_total_miles_actual_pct_of_sched] = cast((sum(1.00 * actual_total_miles) / sum(1.00 * sched_total_miles))  as decimal(10,4)) ,  
avg_schedule_rev_miles_emx = avg(case when emx = 'y' then 1.00*sched_rev_miles else 0.00 end),
avg_schedule_total_miles_emx = avg(case when emx = 'y' then 1.00*sched_total_miles else 0.00 end),
avg_actual_total_miles_emx = avg(case when emx = 'y' then 1.00*actual_total_hours else 0.00 end) ,
	[avg_total_miles_actual_pct_of_total_emx] = cast((sum(case when emx = 'y' then actual_total_miles else 0.00 end) / sum(case when emx = 'y' then sched_total_miles else 0.00 end)) as decimal(10,4)) ,
[passenger_miles] = sum(passenger_miles) ,
[avg_passenger_miles] = avg(passenger_miles) ,
[avg_trip_len]  = cast((1.00 * sum(passenger_miles) / sum(boardings)) as numeric(9,2))

,[ons_per_sched_in_srv_hr]  = sum(1.0*boardings) / sum(sched_in_service_hours) 
,[ons_per_actual_in_srv_hr] = sum(1.0*boardings) / sum(actual_in_service_hours) 
,[ons_per_sched_rev_hr]     = sum(1.0*boardings) / sum(sched_rev_hours)
,[ons_per_actual_rev_hr]    = sum(1.0*boardings) / sum(actual_rev_hours)
,[ons_per_sched_total_hr]   = sum(1.0*boardings) / sum(sched_total_hours)
,[ons_per_actual_total_hr]  = sum(1.0*boardings) / sum(actual_total_hours)
       
,[ons_per_sched_rev_mile]    = cast(1.0 * sum(boardings) / sum(sched_rev_miles) as numeric(9,2))
,[ons_per_actual_rev_mile]   = cast(1.0 * sum(boardings) / sum(actual_rev_miles) as numeric(9,2))
,[ons_per_sched_total_mile]  = cast(1.0 * sum(boardings) / sum(sched_total_miles) as numeric(9,2))  
,[ons_per_actual_total_mile] = cast(1.0 * sum(boardings) / sum(actual_total_miles)  as numeric(9,2)) 
       
,[pms_per_sched_in_srv_hr]  = sum(passenger_miles) / sum(sched_in_service_hours)  
,[pms_per_actual_in_srv_hr] = sum(passenger_miles) / sum(actual_in_service_hours) 
,[pms_per_sched_rev_hr]     = sum(passenger_miles) / sum(sched_rev_hours)         
,[pms_per_actual_rev_hr]    = sum(passenger_miles) / sum(actual_rev_hours)        
,[pms_per_sched_total_hr]   = sum(passenger_miles) / sum(sched_total_hours)       
,[pms_per_actual_total_hr]  = sum(passenger_miles) / sum(actual_total_hours)      

,[pmss_per_sched_rev_mile]   = cast(1.0 * sum(passenger_miles) / sum(sched_rev_miles) as numeric(9,2))
,[pms_per_actual_rev_mile]   = cast(1.0 * sum(passenger_miles) / sum(actual_rev_miles) as numeric(9,2))   
,[pms_per_sched_total_mile]  = cast(1.0 * sum(passenger_miles) / sum(sched_total_miles) as numeric(9,2))  
,[pms_per_actual_total_mile] = cast(1.0 * sum(passenger_miles) / sum(actual_total_miles) as numeric(9,2)) 

into -- select *  -- drop table 
#summaryByWeekOverview -- select * 
from ##prepStatF
group by yearWk

-- CHARTED Perc of Rev perc of Sched vs Actual perc of Sched




-- drop table #htmlChartTable_perf2
create table #htmlChartTable_perf2 (rn INT identity(1,1), RowName1 varchar(90), Value1 float, Value2 float, Value3 float )
insert #htmlChartTable_perf2 (RowName1, Value1, Value2, Value3)
 select yearWk = calyearWk
 ,(abs(cast(avg_sched_in_service_hours_all as decimal(10,2))
	- cast(avg_actual_in_service_hours_all as decimal(10,2))))--*.01 
			as 'Delta Scheduled Revenue Hours and Actual Rev Hours'
 ,abs(cast(avg_sched_revenue_hours_all as decimal(10,2))
	- cast(avg_actual_revenue_hours_all as decimal(10,2))) as 'Delta Scheduled and Actual Boarding in Rev Hours'
 ,abs(cast(pmss_per_sched_rev_mile as decimal(10,2))
	- cast(pms_per_actual_rev_mile as decimal(10,2))) as  'Delta Scheduled and Actual Passenger Miles by Rev Mile'
 from #summaryByWeekOverview o
 LEFT JOIN (SELECT yearWk = cast([Year] as varchar(6)) + right('00'+cast([WeekOfYear] as varchar(2)),2) ,
				calyearWk = cast([Year] as varchar(6)) + right('00'+cast([WeekOfYear] as varchar(2)),2) + ' - '+
				   CONVERT(varchar,(DATEADD(week, DATEDIFF(week, -1, [CALENDAR_DATE]), -1)),101) 
			  FROM [ltd_dw].[tm].[DW_CALENDAR]
			 where DayOfWeekNbr = 1) d on d.yearWk = o.yearWk
order by yearWk


create table #chartoutput2 (rn INT, RowName1 varchar(255), RPT_OUTPUT1 varchar(max),  RPT_OUTPUT2 varchar(max),  RPT_OUTPUT3 varchar(max))

declare @i2 int = 1
declare @r2 int = (select max(rn) from #htmlChartTable_perf2)
declare @stringit1 varchar(max)
declare @stringit2 varchar(max)
declare @stringit3 varchar(max)
declare @g2 varchar(32)
WHILE @i2 < @r2
BEGIN

select @g2 = (select RowName1 from #htmlChartTable_perf2 where rn = @i2)
select @stringit1 = (select replicate('@',ceiling(value1*.25)) + ' ' + cast(cast(value1*.25 as decimal(8,2) )as varchar(13)) +'% ' 
						  from #htmlChartTable_perf2 where rn = @i2 )
select @stringIt2 = (select replicate('?',ceiling(value2*2)) + ' ' + cast(cast(value2 as decimal(8,2) )as varchar(13)) +'% ' 
						  from #htmlChartTable_perf2 where rn = @i2 )
select @stringIt3 = (select replicate('^',ceiling(value3*10)) + ' ' + cast(cast(value3 as decimal(8,2) )as varchar(13)) +'% ' 
						  from #htmlChartTable_perf2 where rn = @i2 )
INSERT #chartoutput2 (RowName1 , RPT_OUTPUT1 , RPT_OUTPUT2 , RPT_OUTPUT3) 
select @g2,@stringIt1, @stringit2,@stringit3

 select @stringIt1 = ''
 select @stringit2 = ''
 select @stringit3 = ''
 
select @i2 = @i2 + 1
If @i2 > @r2
	BREAK
	ELSE CONTINUE

END



declare @htmlmax1 nvarchar(max) = ''

declare @header1 varchar(max) = '|Summary of KPIs through|the Most Recent 15 Weeks||'
select @htmlmax1 =  @htmlmax1 + 
 (SELECT CONVERT(NVARCHAR(MAX), (SELECT
    (SELECT @header1 FOR XML PATH(''), TYPE) AS 'caption',
    (SELECT 'Sort' as th, 'Metric' AS th, 'KPI.............' AS th FOR XML RAW('tr'), ELEMENTS, TYPE) AS 'thead',
     (select s as td, a as td, g as td from (
		SELECT 1 as s,'Avg Scheduled In-Service Hours All' a, 'QQQ'+cast(cast(avg_sched_in_service_hours_all as decimal(10,2)) as varchar(20)) AS g -- select *  
				FROM #summaryOverview 
		UNION
		SELECT 2 as s,'Avg Actual In-Service Hours All' a, 'QQQ'+cast(cast(avg_actual_in_service_hours_all as decimal(10,2)) as varchar(20)) AS g FROM #summaryOverview 
		UNION
		SELECT 3 as s,'Avg Scheduled Revenue Hours All' a, 'QQQ'+cast(cast(avg_sched_revenue_hours_all as decimal(10,2)) as varchar(20)) AS g FROM #summaryOverview 
		UNION
		SELECT 4 as s,'Avg Actual Revenue Hours All' a, 'QQQ'+cast(cast(avg_actual_revenue_hours_all as decimal(10,2)) as varchar(20)) AS g FROM #summaryOverview 
		UNION
		SELECT 5 as s,'Avg Scheduled Revenue Hours EMx' a, 'QQQ'+cast(cast(avg_sched_revenue_hours_emx as decimal(10,2)) as varchar(20)) AS g FROM #summaryOverview 
		UNION
		SELECT 6 as s,'Avg Actual Revenue Hours EMx' a, 'QQQ'+cast(cast(avg_actual_revenue_hours_emx as decimal(10,2)) as varchar(20)) AS g FROM #summaryOverview
		UNION 
		SELECT 7 as s,'Avg Ons Per Scheduled Revenue Mile' a, 'QQQ'+cast(cast(ons_per_sched_rev_mile as decimal(10,2)) as varchar(20)) AS g FROM #summaryOverview 
		UNION
		SELECT 8 as s,'Avg Ons Per Actual Revenue Mile' a, 'QQQ'+cast(cast(ons_per_actual_rev_mile as decimal(10,2)) as varchar(20)) AS g FROM #summaryOverview
		UNION 
		SELECT 9 as s,'Avg Trip Length' a, 'QQQ'+cast(cast(avg_trip_len as decimal(10,2)) as varchar(20)) AS g FROM #summaryOverview
		UNION  
		SELECT 10 as s,'Avg Passenger Miles Per Scheduled Revenue Hour' a, 'QQQ'+cast(cast(pmss_per_sched_rev_mile as decimal(10,2)) as varchar(20)) AS g FROM #summaryOverview
		UNION
		SELECT 11 as s,'Avg Passenger Miles Per Actual Revenue Hour' a, 'QQQ'+cast(cast(pms_per_actual_rev_mile as decimal(10,2)) as varchar(20)) AS g FROM #summaryOverview
		 ) x
    FOR XML RAW('tr'), ELEMENTS, TYPE
    ) AS 'tbody'
  FOR XML PATH(''), ROOT('table'))));


  
declare @htmlmaxPerc nvarchar(max) = ''

declare @header2 varchar(max) = '|Weekly Scheduled vs Actuals by Year and Week of Year|Most Recent Week at the Top||'
select @htmlmaxPerc =  @htmlmaxPerc + 
 (SELECT CONVERT(NVARCHAR(MAX), (SELECT
    (SELECT @header2 FOR XML PATH(''), TYPE) AS 'caption',
    (SELECT 'Year and|Week of Year' AS th
			,'Delta Scheduled Revenue Hours|and Actual Rev Hours' AS th 
			,'Delta Scheduled and Actual|Boarding in Rev Hours' AS th 
			,'Delta Scheduled and Actual|Passenger Miles by Rev Mile' as th FOR XML RAW('tr'), ELEMENTS, TYPE) AS 'thead',
    (
    SELECT TOP (15) RowName1 AS td, RPT_OUTPUT1 as td, RPT_OUTPUT2 as td, RPT_OUTPUT3 as td
      FROM #chartoutput2 AS c
      ORDER BY rn DESC
    FOR XML RAW('tr'), ELEMENTS, TYPE
    ) AS 'tbody'
  FOR XML PATH(''), ROOT('table'))));
  --select @htmlmaxPerc


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

select @htmlmax1 = (select replace(replace(@htmlmax1,'|','<br>'),'<td>QQQ','<td class="alignRight">'))
select @htmlmaxPerc = (select replace(replace(replace(replace(@htmlmaxPerc,'|','<br>'),'?','&#9608;'),'@','&#9618;'),'^','&#9619;'))

set @msgAll =  @msgAll + 
+ @htmlmax1
+' 
<br><br>'
+ @htmlmaxPerc
+' 
<br><br>
<p class="foots">For information about these KPIs email: support@ltd.org<br><br>
Confidentiality Statement: The contents of this e-mail and any attachments are intended solely for the addressee.  The information may also be confidential and/or legally privileged.  This transmission is sent for the sole purpose of delivery to the intended recipient.  If you have received this transmission in error, any use, reproduction, or dissemination of this transmission is strictly prohibited.  If you are not the intended recipient, please immediately notify the sender by reply e-mail, support@ltd.org and delete this message and its attachments, if any.  E-mail is covered by the Electronic Communications Privacy Act, 18 USC SS 2510-2521 and is legally privileged. Messages to and from this email may also be exempt from public disclosure under 49 CFR Part 15.15(b) as Sensitive Security Information.'

--declare @headerClean varchar(90) = ''
--select @headerClean = (select replace(@header,'|',' - '))

--select @msgAll

exec msdb..sp_send_dbmail @recipients = 'barb.eichberger@ltd.org;Aimee.Reichert@ltd.org' , -- 'robin.mayall@ltd.org', -- would like to automate next, prepare a sign up sheet in power bi report server for email addresses
  @blind_copy_recipients ='barb.eichberger@ltd.org' ,
  @subject = 'Fleet Performance from NTD KPIs', 
  @body_format = 'html',
  @from_address = 'Automated KPI Emails <support@ltd.org>',
  @body = @msgAll


  
IF OBJECT_ID('tempdb.dbo.##prepStatF', 'U') IS NOT NULL
  DROP TABLE dbo.##prepStatF



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
