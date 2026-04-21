SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [kpi].[Send_Maintenance_WorkOrderInfo] as
/*
CREATED:   20201130
AUTHOR :   B EICHBERGER
PURPOSE:   To produce HTML simple IT kpis using dbemail.
		   Maintenance KPI Demo for Robin Mayall 
CHANGEDON: 
 CHANGEBY:  
   CHANGE:  

EMAIL SUBJECT = Maintenance_Work Order KPI and Completion Rate - Last 15 Week

EXEC EXAMPLE: exec kpi.Send_Maintenance_WorkOrderInfo

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


IF OBJECT_ID('tempdb.dbo.##prepStatWO', 'U') IS NOT NULL
drop table ##prepStatWO
IF OBJECT_ID('tempdb.dbo.##stageAllWork', 'U') IS NOT NULL
drop table ##stageAllWork
IF OBJECT_ID('tempdb.dbo.##stageRoadCalls', 'U') IS NOT NULL
drop table ##stageRoadCalls
IF OBJECT_ID('tempdb.dbo.##pivotRoadCalls', 'U') IS NOT NULL
drop table ##pivotRoadCalls
IF OBJECT_ID('tempdb.dbo.##pivotRoadCallClass', 'U') IS NOT NULL
drop table ##pivotRoadCallClass
IF OBJECT_ID('tempdb.dbo.##pivotRoadCallCost', 'U') IS NOT NULL
drop table ##pivotRoadCallCost
IF OBJECT_ID('tempdb.dbo.##RoadCallPivot', 'U') IS NOT NULL
drop table ##RoadCallPivot
IF OBJECT_ID('tempdb.dbo.##stageRoadCalls', 'U') IS NOT NULL
drop table ##stageRoadCalls


declare @weekstrt int
declare @weekend int

select @weekend = (select cast(datepart(year,dateadd("wk",-1,getdate())) as varchar(10))+ right('00'+cast(datepart(wk,dateadd("wk",-1,getdate())) as varchar(3)),2))
select @weekstrt = (select cast(datepart(year,dateadd("wk",-16,getdate())) as varchar(10))+ right('00'+cast(datepart(wk,dateadd("wk",-16,getdate())) as varchar(3)),2))

select jm.work_order_no
	  ,[eq_equip_no]          = lm.eq_equip_no
      ,[ltd_bus_class]        = bc.ltd_bus_class
      ,[atric]                = bc.atric
      ,[emx_bus]              = bc.emx_bus
      ,[active]               = bc.unit_is_active
       ,[meter_1_life_total]   = jm.meter_1_life_total
      ,[description_lc]       = rcc.description_lc
      ,[rc_category]          = rcc.rc_category
	  ,lm_hours = sum(lm.hours)
	  ,lm_cost = sum(lm.cost)
	  ,lm_avg_labor_rate = avg(lm.[labor_rate])
	  ,jm.[datetime_out_service]
	  ,jm.[datetime_in_service] 
	  ,hoursOutOfService = datediff(hour,jm.[datetime_out_service], isnull(jm.datetime_in_service,getdate()))*1.00
	  ,min_to_first_labor = datediff(minute, jm.datetime_out_service,isnull(jm.datetime_first_labor,getdate()))*1.00
	  ,jm.datetime_first_labor
	  ,jm.datetime_closed
	  ,jm.labor_cost
	  ,jm.parts_cost
	  ,jm.comml_cost
	  ,jm.overhead_cost
	  ,jm.total_cost
	  ,yearWk = cast(datepart(year,datetime_out_service) as varchar(10))+ right('00'+cast(datepart(wk,datetime_out_service) as varchar(3)),2)
	  ,rcType = case when lm.task_task_code in('45','45-10') then 'Road Call' else 'Not Road Call' end
into -- select * from 
##prepStatWO -- order by work_order_no desc
  from      [ltd-eam].proto.emsdba.lab_main    lm
 inner join [ltd-eam].proto.emsdba.job_main    jm  on jm.work_order_yr         = lm.work_order_yr and jm.work_order_no = lm.work_order_no
 inner join [ltd-eam].ltd_db.dbo.rsn_main_categorized rcc on rcc.reas_reas_for_repair = jm.reas_reas_for_repair
 inner join [ltd-eam].ltd_db.dbo.bus_classes          bc  on bc.eq_equip_no           = lm.eq_equip_no
 where cast(datepart(year,datetime_out_service) as varchar(10))+ right('00'+cast(datepart(wk,datetime_out_service) as varchar(3)),2) Between @weekstrt and @weekend
 --and lm.work_order_no = 3876
 and ltd_bus_class <> '260' AND ltd_bus_class <> '760' AND ltd_bus_class <> 'unknown'
group by 
jm.work_order_no
	  ,lm.eq_equip_no
      ,bc.ltd_bus_class
      ,bc.atric
      ,bc.emx_bus
      ,bc.unit_is_active
      ,jm.datetime_out_service
	  ,jm.[datetime_in_service]
      ,jm.meter_1_life_total
      ,rcc.description_lc
      ,rcc.rc_category
	  ,jm.datetime_first_labor
	  ,jm.datetime_closed
	  ,jm.labor_cost
	  ,jm.parts_cost
	  ,jm.comml_cost
	  ,jm.overhead_cost
	  ,jm.total_cost
	  ,cast(datepart(year,datetime_out_service) as varchar(10))+ right('00'+cast(datepart(wk,datetime_out_service) as varchar(3)),2)
	  ,case when lm.task_task_code in('45','45-10') then 'Road Call' else 'Not Road Call' end


 -- POPULATE THE ALL ROAD CALL TABLE SOURCE
 select calYearWk as yearWk,description_lc,ltd_bus_class,total_cost,OutofServiceWeekYr 
into ##stageRoadCalls
from (
select count(*) OutofServiceWeekYr, description_lc , ltd_bus_class, sum(total_cost) total_cost
,yearWk = cast(datepart(year,datetime_out_service) as varchar(10))+ right('00'+cast(datepart(wk,datetime_out_service) as varchar(3)),2)
from ##prepStatWO
WHERE rcType = 'Road Call'
AND ltd_bus_class <> '260' AND ltd_bus_class <> '760' AND ltd_bus_class <> 'unknown'
	group by ltd_bus_class, description_lc,cast(datepart(year,datetime_out_service) as varchar(10))+ right('00'+cast(datepart(wk,datetime_out_service) as varchar(3)),2)
	) wo
LEFT JOIN (SELECT yearWk = cast([Year] as varchar(6)) + right('00'+cast([WeekOfYear] as varchar(2)),2) ,
				calyearWk = cast([Year] as varchar(6)) + right('00'+cast([WeekOfYear] as varchar(2)),2) + ' - '+
				   CONVERT(varchar,(DATEADD(week, DATEDIFF(week, -1, [CALENDAR_DATE]), -1)),101) 
			  FROM [ltd_dw].[tm].[DW_CALENDAR]
			 where DayOfWeekNbr = 1) d on d.yearWk = wo.yearWk
	
 -- POPULATE THE ALL WORKORDER TABLE SOURCE
 select calYearWk as yearWk,description_lc,ltd_bus_class,total_cost,OutofServiceWeekYr 
into ##stageAllWork 
from (
select count(*) OutofServiceWeekYr, description_lc , ltd_bus_class, sum(total_cost) total_cost
,yearWk = cast(datepart(year,datetime_out_service) as varchar(10))+ right('00'+cast(datepart(wk,datetime_out_service) as varchar(3)),2)
from ##prepStatWO
WHERE ltd_bus_class <> '260' AND ltd_bus_class <> '760' AND ltd_bus_class <> 'unknown'
	group by ltd_bus_class, description_lc,cast(datepart(year,datetime_out_service) as varchar(10))+ right('00'+cast(datepart(wk,datetime_out_service) as varchar(3)),2)
) r
LEFT JOIN (SELECT yearWk = cast([Year] as varchar(6)) + right('00'+cast([WeekOfYear] as varchar(2)),2) ,
				calyearWk = cast([Year] as varchar(6)) + right('00'+cast([WeekOfYear] as varchar(2)),2) + ' - '+
				   CONVERT(varchar,(DATEADD(week, DATEDIFF(week, -1, [CALENDAR_DATE]), -1)),101) 
			  FROM [ltd_dw].[tm].[DW_CALENDAR]
			 where DayOfWeekNbr = 1) d on d.yearWk = r.yearWk

--select * from ##stageAllWork

-- PIVOT ROAD CALL TYPE SERVICE REQUIRED
declare @colhdrsSel nvarchar(max) = ( 
SELECT STUFF(
             (SELECT ', cast(isnull([' + yearWk +'],0) as decimal(10,2)) '+ '['+  yearWk + ']'
              FROM (select distinct yearWk from ##stageRoadCalls  ) t1
              FOR XML PATH (''))
             , 1, 1, ''))


declare @colhdrsSum nvarchar(max) = ( 
SELECT STUFF(
             (SELECT ', [' + yearWk +']'  
              FROM (select distinct yearWk from ##stageRoadCalls  ) t1
              FOR XML PATH (''))
             , 1, 1, ''))
declare @sqlcmd nvarchar(max) = ''
select @sqlcmd = @sqlcmd + 
'
select description_lc ,'+@colhdrsSel+'
into ##pivotRoadCalls
FROM (select yearWk,description_lc
	,sum(OutofServiceWeekYr) OutofServiceWeekYr
from ##stageRoadCalls
group by  yearWk,description_lc
	 )
s
PIVOT ( 
	SUM(OutofServiceWeekYr) for yearWk in ('+@colhdrsSum+')) as p'
--print @sqlcmd

exec sp_executesql @sqlcmd

--PIVOT BUS CLASS WORK ORDER COUNT
declare @colhdrsSel2 nvarchar(max) = ( 
SELECT STUFF(
             (SELECT ', cast(isnull([' + yearWk +'],0) as decimal(10,2)) '+ '['+  yearWk + ']'
              FROM (select distinct yearWk from ##stageRoadCalls  ) t1
              FOR XML PATH (''))
             , 1, 1, ''))


declare @colhdrsSum2 nvarchar(max) = ( 
SELECT STUFF(
             (SELECT ', [' + yearWk +']'  
              FROM (select distinct yearWk from ##stageRoadCalls  ) t1
              FOR XML PATH (''))
             , 1, 1, ''))
declare @sqlcmd2 nvarchar(max) = ''
select @sqlcmd2 = @sqlcmd2 + 
'
select ltd_bus_class ,'+@colhdrsSel2+'
into ##pivotRoadCallClass
FROM (select yearWk,ltd_bus_class
	,sum(OutofServiceWeekYr) OutofServiceWeekYr
from ##stageRoadCalls
group by  yearWk,ltd_bus_class
	 )
s
PIVOT ( 
	SUM(OutofServiceWeekYr) for yearWk in ('+@colhdrsSum2+')) as p'
--print @sqlcmd2

exec sp_executesql @sqlcmd2



--PIVOT BUS CLASS WORK ORDER COST BY BUS CLASS
declare @colhdrsSel3 nvarchar(max) = ( 
SELECT STUFF(
             (SELECT ', cast(isnull([' + yearWk +'],0) as decimal(10,2)) '+ '['+  yearWk + ']'
              FROM (select distinct yearWk from ##stageRoadCalls  ) t1
              FOR XML PATH (''))
             , 1, 1, ''))


declare @colhdrsSum3 nvarchar(max) = ( 
SELECT STUFF(
             (SELECT ', [' + yearWk +']'  
              FROM (select distinct yearWk from ##stageRoadCalls  ) t1
              FOR XML PATH (''))
             , 1, 1, ''))
declare @sqlcmd3 nvarchar(max) = ''
select @sqlcmd3 = @sqlcmd3 + 
'
select ltd_bus_class ,'+@colhdrsSel3+'
into ##pivotRoadCallCost
FROM (select yearWk,ltd_bus_class
	,sum(total_cost) total_cost
from ##stageRoadCalls
group by  yearWk,ltd_bus_class
	 )
s
PIVOT ( 
	SUM(total_cost) for yearWk in ('+@colhdrsSum3+')) as p'
--print @sqlcmd3

exec sp_executesql @sqlcmd3



-- USE TO COLOR CODE HTML OUTPUT
declare @maxnd int = (select isnull(max(OutofServiceWeekYr),0) from (select yearWk,description_lc, sum(OutofServiceWeekYr) OutofServiceWeekYr from ##stageRoadCalls group by yearWk,description_lc) x)
declare @minnd int = (select isnull(min(OutofServiceWeekYr),0) from (select yearWk,description_lc, sum(OutofServiceWeekYr) OutofServiceWeekYr from ##stageRoadCalls group by yearWk,description_lc) x)
declare @maxnl int = (select isnull(max(OutofServiceWeekYr),0) from (select yearWk,ltd_bus_class, sum(OutofServiceWeekYr) OutofServiceWeekYr from ##stageRoadCalls group by yearWk,ltd_bus_class) x)
declare @minnl int = (select isnull(min(OutofServiceWeekYr),0) from (select yearWk,ltd_bus_class, sum(OutofServiceWeekYr) OutofServiceWeekYr from ##stageRoadCalls group by yearWk,ltd_bus_class) x)

--select @maxnd , @minnd, @maxnl, @minnd 


select 1 groupNumb,'road calls count' as RptGroup,* 
into -- select * from 
##RoadCallPivot 
from ##pivotRoadCalls
union
select 2, 'road calls by bus class',* from ##pivotRoadCallClass
UNION
select 3, 'road call costs by bus class', * from ##pivotRoadCallCost
		 
-- SUMMARY
select woAllOpened = count(distinct work_order_no)
,sum(case when rcType = 'Road Call' then 1 else 0 end) as RoadCallCount
	  ,percOfWorkRoadCalls = cast(count(distinct work_order_no)/
			case when sum(case when rcType = 'Road Call' then 1 else 0 end) = 0 then 0 else
				sum(case when rcType = 'Road Call' then 1.00 else 0 end) end as decimal(10,3)) 
	 ,costAvgAll = sum(total_cost) / count(distinct work_order_no)  -- 
	 ,costAvgRC = cast(case when sum(case when rcType = 'Road Call' then total_cost else 0 end) = 0 then 0 else
					sum(case when rcType = 'Road Call' then total_cost else 0 end) / sum(case when rcType = 'Road Call' then 1 else 0 end) end
					as decimal(10,3))   
	 ,countAllOpen = sum(case when datetime_in_service is null then 1 else 0 end)
	 ,countAllClosed = sum(case when datetime_in_service is not null then 1 else 0 end)
	 ,countRCOpen = sum(case when datetime_in_service is null and rctype = 'Road Call' then 1 else 0 end)
	 ,countRCClosed = sum(case when datetime_in_service is not null  and rctype = 'Road Call' then 1 else 0 end)
	 ,outofServiceAvgHours = avg(hoursOutOfService)
	 ,hoursAvgToFirstLabor = cast(avg(min_to_first_labor/60.00) as decimal(10,3))
	 ,avgHoursSpent = avg(lm_hours)  -- 
	 ,outofServiceRCAvgHours = cast(avg(case when rcType = 'Road Call' then hoursOutOfService else 0 end) as decimal(10,3))
	 ,hoursRCAvgToFirstLabor = cast(avg(case when rcType = 'Road Call' then min_to_first_labor/60.00 else 0 end) as decimal(10,3))
	into -- select *  
#summaryOverview -- select * 
from ##prepStatWO

-- CHARTED Closed Request Counts
select rn = row_number() OVER (order by d.calyearWk desc) ,
	 d.calyearWk as 'Year Wk Closed', count(distinct work_order_no) countClosed 
	into -- drop table 
	#summaryByWeekOverview
	 from ##prepStatWO w
	  LEFT JOIN (SELECT yearWk = cast([Year] as varchar(6)) + right('00'+cast([WeekOfYear] as varchar(2)),2) ,
				calyearWk = cast([Year] as varchar(6)) + right('00'+cast([WeekOfYear] as varchar(2)),2) + ' - '+
				   CONVERT(varchar,(DATEADD(week, DATEDIFF(week, -1, [CALENDAR_DATE]), -1)),101) 
			  FROM [ltd_dw].[tm].[DW_CALENDAR]
			 where DayOfWeekNbr = 1) d on d.yearWk = w.yearWk
	where datetime_in_service is not null 
group by d.calyearWk
--order by yearWk	

-- drop table #setup9912
-- select * from #setup9912
create table #setup9912 (rn INT identity(1,1),column_names varchar(90), [ordinal_position] smallint, datatype varchar(90))
insert #setup9912 (column_names, ordinal_position, datatype)
select column_name, [ordinal_position], DATA_TYPE
FROM TEMPDB.INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME LIKE '%summaryByWeekOverview%'


create table #htmlChartTable (rn INT identity(1,1), RowName1 varchar(90), Group1 varchar(90), Value1 float )
insert #htmlChartTable (RowName1, Group1, Value1)
 select distinct RowName,u.[Year Wk Closed], u.countClosed
 from (
 SELECT RowName = 'Count Work Orders Closed ' + ltrim(stuff((
    SELECT ' by ' + cast(column_names as varchar(max))
    FROM #setup9912 WHERE datatype = 'varchar' --and rn = @i
    FOR XML PATH('')
    ), 1, 1, ''))
		from #setup9912 ) o
	Cross APPLY (select [Year Wk Closed], countClosed from #summaryByWeekOverview) u

-- drop table #chartoutput
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
select @stringit = (select replicate(@barchar,value1*.33) from #htmlChartTable where rn = @i)

	 
Insert #chartoutput (rn, RowName1, Group1, RPT_OUTPUT)
select @i, RowName1, Group1, @stringIt +' '+ cast(round(@v1,2) as varchar(8)) from #htmlChartTable where rn = @i


	 select @stringIt = ''
 
select @i = @i + 1
If @i > @r
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
		SELECT 1 as s,'Count Work Orders Opened' a, 'QQQ'+cast(cast(woAllOpened as INT) as varchar(20)) AS g -- select *  
				FROM #summaryOverview 
		UNION
		SELECT 2 as s,'Road Call Work Orders Opened' a, 'QQQ'+cast(cast(RoadCallCount as INT) as varchar(20)) AS g FROM #summaryOverview 
		UNION
		SELECT 3 as s,'Road Calls as Percent of all Opened Work Orders' a, 'QQQ'+cast(cast(percOfWorkRoadCalls as decimal(10,1)) as varchar(20))+'%' AS g FROM #summaryOverview 
		UNION
		SELECT 4 as s,'Avg Cost of All Work Orders' a, 'QQQ'+cast(cast(costAvgAll as decimal(10,2)) as varchar(20)) AS g FROM #summaryOverview
		UNION 
		SELECT 5 as s,'Avg Cost of All Road Call Work Orders' a, 'QQQ'+cast(cast(costAvgRC as decimal(10,2)) as varchar(20)) AS g FROM #summaryOverview
		UNION 
		SELECT 6 as s,'Current Open Work Orders' a, 'QQQ'+cast(cast(countAllOpen as INT) as varchar(20)) AS g FROM #summaryOverview
		UNION 
		SELECT 7 as s,'Current Open Road Call Work Orders' a, 'QQQ'+cast(cast(countRCOpen as INT) as varchar(20)) AS g FROM #summaryOverview
		UNION 
		SELECT 8 as s,'Avg Out of Service Hours' a, 'QQQ'+cast(cast(outofServiceAvgHours as decimal (10,2)) as varchar(20)) AS g FROM #summaryOverview
		UNION 
		SELECT 9 as s,'Avg Hours to First Labor' a, 'QQQ'+cast(cast(hoursAvgToFirstLabor as decimal (10,2)) as varchar(20)) AS g FROM #summaryOverview 
		UNION 
		SELECT 10 as s,'Avg Out of Service Road Call Hours' a, 'QQQ'+cast(cast(outofServiceRCAvgHours as decimal (10,2)) as varchar(20)) AS g FROM #summaryOverview
		UNION 
		SELECT 11 as s,'Avg Hours to Road Call First Labor' a, 'QQQ'+cast(cast(hoursRCAvgToFirstLabor as decimal (10,2)) as varchar(20)) AS g FROM #summaryOverview  ) x
    FOR XML RAW('tr'), ELEMENTS, TYPE
    ) AS 'tbody'
  FOR XML PATH(''), ROOT('table'))));



declare @htmlmax nvarchar(max) = ''

declare @header varchar(max) = '|Maintenance Work Order Summary Cost and Count Closed|by Year and Week of Year||'
select @htmlmax =  @htmlmax + 
 (SELECT CONVERT(NVARCHAR(MAX), (SELECT
    (SELECT @header FOR XML PATH(''), TYPE) AS 'caption',
    (SELECT 'Year and Week|of Year' AS th, 'Work Orders Closed|by Week' AS th FOR XML RAW('tr'), ELEMENTS, TYPE) AS 'thead',
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
<br><br>
<p class="foots">For information about these KPIs email: support@ltd.org<br><br>
Confidentiality Statement: The contents of this e-mail and any attachments are intended solely for the addressee.  The information may also be confidential and/or legally privileged.  This transmission is sent for the sole purpose of delivery to the intended recipient.  If you have received this transmission in error, any use, reproduction, or dissemination of this transmission is strictly prohibited.  If you are not the intended recipient, please immediately notify the sender by reply e-mail, support@ltd.org and delete this message and its attachments, if any.  E-mail is covered by the Electronic Communications Privacy Act, 18 USC SS 2510-2521 and is legally privileged. Messages to and from this email may also be exempt from public disclosure under 49 CFR Part 15.15(b) as Sensitive Security Information.'

declare @headerClean varchar(90) = ''
select @headerClean = 'Maintenance_Work Order KPI and Completion Rate - Last 15 Weeks' -- (select replace(@header,'|',' - '))

--select @msgAll

exec msdb..sp_send_dbmail @recipients = 'barb.eichberger@ltd.org;' , -- 'robin.mayall@ltd.org', -- would like to automate next, prepare a sign up sheet in power bi report server for email addresses
  @blind_copy_recipients ='barb.eichberger@ltd.org' ,
  @subject = @headerClean, 
  @body_format = 'html',
  @from_address = 'Automated KPI Emails <support@ltd.org>',
  @body = @msgAll


IF OBJECT_ID('tempdb.dbo.##prepStatWO', 'U') IS NOT NULL
drop table ##prepStatWO
IF OBJECT_ID('tempdb.dbo.##stageAllWork', 'U') IS NOT NULL
drop table ##stageAllWork
IF OBJECT_ID('tempdb.dbo.##stageRoadCalls', 'U') IS NOT NULL
drop table ##stageRoadCalls
IF OBJECT_ID('tempdb.dbo.##pivotRoadCalls', 'U') IS NOT NULL
drop table ##pivotRoadCalls
IF OBJECT_ID('tempdb.dbo.##pivotRoadCallClass', 'U') IS NOT NULL
drop table ##pivotRoadCallClass
IF OBJECT_ID('tempdb.dbo.##pivotRoadCallCost', 'U') IS NOT NULL
drop table ##pivotRoadCallCost
IF OBJECT_ID('tempdb.dbo.##RoadCallPivot', 'U') IS NOT NULL
drop table ##RoadCallPivot
IF OBJECT_ID('tempdb.dbo.##stageRoadCalls', 'U') IS NOT NULL
drop table ##stageRoadCalls

  
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
