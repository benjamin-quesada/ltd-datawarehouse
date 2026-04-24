SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [kpi].[Send_Maintenance_PivotCosts] as
/*
CREATED:   20201201
AUTHOR :   B EICHBERGER
PURPOSE:   To produce HTML simple IT kpis using dbemail.
		   Maintenance KPI Demo for Robin Mayall 
CHANGEDON: 
 CHANGEBY:  
   CHANGE:  

EMAIL SUBJECT = Maintenance Work Order Count, Summary Costs and Aging

EXEC EXAMPLE: exec kpi.Send_Maintenance_PivotCosts

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


IF OBJECT_ID('tempdb.dbo.##htmlbig', 'U') IS NOT NULL
  DROP TABLE dbo.##htmlbig

IF OBJECT_ID('tempdb.dbo.##maintenanceCostPivot', 'U') IS NOT NULL
  DROP TABLE dbo.##maintenanceCostPivot

IF OBJECT_ID('tempdb.dbo.##pivotAllCost', 'U') IS NOT NULL
  DROP TABLE dbo.##pivotAllCost

IF OBJECT_ID('tempdb.dbo.##pivotBuckets', 'U') IS NOT NULL
  DROP TABLE dbo.##pivotBuckets

IF OBJECT_ID('tempdb.dbo.##pivotPMClass', 'U') IS NOT NULL
  DROP TABLE dbo.##pivotPMClass
  
IF OBJECT_ID('tempdb.dbo.##pivotRoadCalls', 'U') IS NOT NULL
  DROP TABLE dbo.##pivotRoadCalls

IF OBJECT_ID('tempdb.dbo.##prepStatPC', 'U') IS NOT NULL
  DROP TABLE dbo.##prepStatPC

IF OBJECT_ID('tempdb.dbo.##stageAllCalls', 'U') IS NOT NULL
  DROP TABLE dbo.##stageAllCalls

IF OBJECT_ID('tempdb.dbo.##stageRoadCalls', 'U') IS NOT NULL
  DROP TABLE dbo.##stageRoadCalls

IF OBJECT_ID('tempdb.dbo.##stagePMWork', 'U') IS NOT NULL
  DROP TABLE dbo.##stagePMWork
  
IF OBJECT_ID('tempdb.dbo.#setup9912', 'U') IS NOT NULL
  DROP TABLE dbo.#setup9912

IF OBJECT_ID('tempdb.dbo.#setup9992', 'U') IS NOT NULL
  DROP TABLE dbo.#setup9992
  
IF OBJECT_ID('tempdb.dbo.#setup9993', 'U') IS NOT NULL
  DROP TABLE dbo.#setup9993

IF OBJECT_ID('tempdb.dbo.#classMedian', 'U') IS NOT NULL
  DROP TABLE #classMedian

IF OBJECT_ID('tempdb.dbo.#summaryOverview', 'U') IS NOT NULL
  DROP TABLE #summaryOverview

IF OBJECT_ID('tempdb.dbo.#htmlChartTable', 'U') IS NOT NULL
  DROP TABLE #htmlChartTable

IF OBJECT_ID('tempdb.dbo.#summaryByWeekOverview', 'U') IS NOT NULL
  DROP TABLE #summaryByWeekOverview

IF OBJECT_ID('tempdb.dbo.#chartoutput', 'U') IS NOT NULL
  DROP TABLE #chartoutput

IF OBJECT_ID('tempdb.dbo.##htmlData', 'U') IS NOT NULL
  DROP TABLE ##htmlData

IF OBJECT_ID('tempdb.dbo.##htmlData3', 'U') IS NOT NULL
  DROP TABLE ##htmlData3

declare @weekstrt int
declare @weekend int

select @weekend = (select cast(datepart(year,dateadd("wk",0,getdate())) as varchar(10))+ right('00'+cast(datepart(wk,dateadd("wk",0,getdate())) as varchar(3)),2))
select @weekstrt = (select cast(datepart(year,dateadd("wk",-17,getdate())) as varchar(10))+ right('00'+cast(datepart(wk,dateadd("wk",-17,getdate())) as varchar(3)),2))

select jm.work_order_no
	  ,[eq_equip_no]          = lm.eq_equip_no
      ,[ltd_bus_class]        = bc.ltd_bus_class
      ,[atric]                = bc.atric
      ,[emx_bus]              = bc.emx_bus
      ,[active]               = bc.unit_is_active
      ,[meter_1_life_total]   = jm.meter_1_life_total
      ,[description_lc]       = rcc.description_lc
      ,[rc_category]          = rcc.rc_category
	  ,jm.job_type
	  ,lm_hours = sum(lm.hours)
	  ,lm_cost = sum(lm.cost)
	  ,lm_avg_labor_rate = avg(lm.[labor_rate])
	  ,jm.[datetime_out_service]
	  ,jm.[datetime_in_service] 
	  ,hoursOutOfService = datediff(hour,[datetime_out_service], isnull(jm.datetime_in_service,getdate()))
	  ,min_to_first_labor = datediff(minute, jm.datetime_out_service,isnull(jm.datetime_first_labor,getdate()))
	  ,jm.datetime_first_labor
	  ,jm.datetime_closed
	  ,jm.labor_cost
	  ,jm.parts_cost
	  ,jm.comml_cost
	  ,jm.overhead_cost
	  ,jm.total_cost
	  ,yearWk = cast(datepart(year,datetime_out_service) as varchar(10))+ right('00'+cast(datepart(wk,datetime_out_service) as varchar(3)),2)
	  ,calyearWk = cast(datepart(year,datetime_out_service) as varchar(6)) + right('00'+cast(datepart(wk,datetime_out_service) as varchar(3)),2) + ' - '+
				   CONVERT(varchar,(DATEADD(week, DATEDIFF(week, -1, datetime_out_service), -1)),101) 
	  ,rcType = case when lm.task_task_code in('45','45-10') then 'Road Call' else 'Not Road Call' end
	  ,openWorkOrderAging = 
			case when jm.[datetime_in_service] is null and datediff(day,jm.[datetime_out_service],getdate()) between 0 and 9 then '0-9 Days'
				 when jm.[datetime_in_service] is null and datediff(day,jm.[datetime_out_service],getdate()) between 10 and 19 then '10-19 Days'
				 when jm.[datetime_in_service] is null and datediff(day,jm.[datetime_out_service],getdate()) between 20 and 29 then '20-29 Days'
				 when jm.[datetime_in_service] is null and datediff(day,jm.[datetime_out_service],getdate()) between 30 and 39 then '30-39 Days'
				 when jm.[datetime_in_service] is null and datediff(day,jm.[datetime_out_service],getdate()) between 40 and 45 then '40-49 Days'
				 when jm.[datetime_in_service] is null and datediff(day,jm.[datetime_out_service],getdate()) >= 50 then '50+ Days' end
into -- drop table --  select * from  
##prepStatPC 
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
	  ,jm.job_type
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
	  ,cast(datepart(year,datetime_out_service) as varchar(6)) + right('00'+cast(datepart(wk,datetime_out_service) as varchar(3)),2) + ' - '+
				   CONVERT(varchar,(DATEADD(week, DATEDIFF(week, -1, datetime_out_service), -1)),101) 
	  ,case when lm.task_task_code in('45','45-10') then 'Road Call' else 'Not Road Call' end

-- select distinct yearWk, calyearWk from ##prepStatPC
select * 
into #yearFilterPC 
from (
select yearWk, rn = row_number() OVER (order by YearWk) 
from (select distinct yearWk from ##prepStatPC) w ) o
where rn between 2 and 16


 -- POPULATE THE ALL WORK ORDER TABLE SOURCE
select count(*) OutofServiceWeekYr, description_lc , ltd_bus_class, sum(total_cost) total_cost
,calyearWk  as yearWk --  cast(datepart(year,datetime_out_service) as varchar(10))+ right('00'+cast(datepart(wk,datetime_out_service) as varchar(3)),2)
into -- drop table
##stageAllCalls
from ##prepStatPC a1
join #yearFilterPC  f on f.yearWk = cast(datepart(year,datetime_out_service) as varchar(10))+ right('00'+cast(datepart(wk,datetime_out_service) as varchar(3)),2)
WHERE ltd_bus_class <> '260' AND ltd_bus_class <> '760' AND ltd_bus_class <> 'unknown'
	group by ltd_bus_class, description_lc,calyearWk


 -- POPULATE THE ALL Road Call WORK ORDER TABLE SOURCE
select count(*) OutofServiceWeekYr, description_lc , ltd_bus_class, sum(total_cost) total_cost
,calyearWk  as yearWk --  cast(datepart(year,datetime_out_service) as varchar(10))+ right('00'+cast(datepart(wk,datetime_out_service) as varchar(3)),2)
into -- drop table -- select * from 
##stageRoadCalls
from ##prepStatPC a2
join #yearFilterPC  f on f.yearWk = cast(datepart(year,datetime_out_service) as varchar(10))+ right('00'+cast(datepart(wk,datetime_out_service) as varchar(3)),2)
WHERE rcType = 'Road Call'
AND ltd_bus_class <> '260' AND ltd_bus_class <> '760' AND ltd_bus_class <> 'unknown'
	group by ltd_bus_class, description_lc,calyearWk

	
 -- POPULATE THE PM TABLE SOURCE
select count(*) OutofServiceWeekYr, description_lc , ltd_bus_class, sum(total_cost) total_cost
,calyearWk  as yearWk --  cast(datepart(year,datetime_out_service) as varchar(10))+ right('00'+cast(datepart(wk,datetime_out_service) as varchar(3)),2)
into -- drop table -- select * from 
##stagePMwork
from ##prepStatPC a3
join #yearFilterPC  f on f.yearWk = cast(datepart(year,datetime_out_service) as varchar(10))+ right('00'+cast(datepart(wk,datetime_out_service) as varchar(3)),2)
WHERE ltd_bus_class <> '260' AND ltd_bus_class <> '760' AND ltd_bus_class <> 'unknown' and job_type = 'PM'
	group by ltd_bus_class, description_lc,calyearWk


-- PIVOT ROAD CALL COST TYPE SERVICE REQUIRED
declare @colhdrsSel nvarchar(max) = ( 
SELECT STUFF(
             (SELECT ', cast(isnull([' + yearWk +'],0) as decimal(10,2)) '+ '['+  yearWk + ']'
              FROM (select distinct yearWk from ##stageRoadCalls 
					UNION
					select distinct yearWk from ##stagePMwork 
					UNION
					select distinct yearWk from ##stageAllCalls   ) t1
              FOR XML PATH (''))
             , 1, 1, ''))

declare @colhdrsSum nvarchar(max) = ( 
SELECT STUFF(
             (SELECT ', [' + yearWk +']'  
              FROM (select distinct yearWk from ##stageRoadCalls 
					UNION
					select distinct yearWk from ##stagePMwork 
					UNION
					select distinct yearWk from ##stageAllCalls  ) t1
              FOR XML PATH (''))
             , 1, 1, ''))
declare @sqlcmd nvarchar(max) = ''
select @sqlcmd = @sqlcmd + 
'
select ltd_bus_class ,'+@colhdrsSel+'
into  -- select * from 
##pivotRoadCalls
FROM (select yearWk,ltd_bus_class
	,sum(total_cost) total_cost
from ##stageRoadCalls c1
group by yearWk,ltd_bus_class
	 )
s
PIVOT ( 
	SUM(total_cost) for yearWk in ('+@colhdrsSum+')) as p'
--print @sqlcmd

exec sp_executesql @sqlcmd

--PIVOT BUS CLASS PM WORK TOTAL
declare @colhdrsSel2 nvarchar(max) = ( 
SELECT STUFF(
             (SELECT ', cast(isnull([' + yearWk +'],0) as decimal(10,2)) '+ '['+  yearWk + ']'
              FROM (select distinct yearWk from ##stageRoadCalls 
					UNION
					select distinct yearWk from ##stagePMwork 
					UNION
					select distinct yearWk from ##stageAllCalls   ) t1
              FOR XML PATH (''))
             , 1, 1, ''))


declare @colhdrsSum2 nvarchar(max) = ( 
SELECT STUFF(
             (SELECT ', [' + yearWk +']'  
              FROM (select distinct yearWk from ##stageRoadCalls 
					UNION
					select distinct yearWk from ##stagePMwork 
					UNION
					select distinct yearWk from ##stageAllCalls   ) t1
              FOR XML PATH (''))
             , 1, 1, ''))
declare @sqlcmd2 nvarchar(max) = ''
select @sqlcmd2 = @sqlcmd2 + 
'
select ltd_bus_class ,'+@colhdrsSel2+'
into  -- select * from 
 ##pivotPMClass
FROM (select yearWk,ltd_bus_class
	,sum(total_cost) total_cost
from ##stagePMwork
group by yearWk,ltd_bus_class
	 )
s
PIVOT ( 
	SUM(total_cost) for yearWk in ('+@colhdrsSum2+')) as p'
--print @sqlcmd2

exec sp_executesql @sqlcmd2



--PIVOT BUS CLASS ALL WORK ORDER COST BY BUS CLASS
declare @colhdrsSel2a nvarchar(max) = ( 
SELECT STUFF(
             (SELECT ', cast(isnull([' + yearWk +'],0) as decimal(10,2)) '+ '['+  yearWk + ']'
              FROM (select distinct yearWk from ##stageRoadCalls 
					UNION
					select distinct yearWk from ##stagePMwork 
					UNION
					select distinct yearWk from ##stageAllCalls   ) t1
              FOR XML PATH (''))
             , 1, 1, ''))


declare @colhdrsSum2a nvarchar(max) = ( 
SELECT STUFF(
             (SELECT ', [' + yearWk +']'  
              FROM (select distinct yearWk from ##stageRoadCalls 
					UNION
					select distinct yearWk from ##stagePMwork 
					UNION
					select distinct yearWk from ##stageAllCalls   ) t1
              FOR XML PATH (''))
             , 1, 1, ''))
declare @sqlcmd2a nvarchar(max) = ''
select @sqlcmd2a = @sqlcmd2a + 
'
select ltd_bus_class ,'+@colhdrsSel2a+'
into  -- select * from 
 ##pivotAllCost
FROM (select yearWk,ltd_bus_class
	,sum(total_cost) total_cost
from ##stageAllCalls
group by  yearWk,ltd_bus_class
	 )
s
PIVOT ( 
	SUM(total_cost) for yearWk in ('+@colhdrsSum2a+')) as p'
--print @sqlcmd3

exec sp_executesql @sqlcmd2a



-- calculate the median value of the total_cost of items from an individual ltd_bus_class
/*The statistical median is the value which separates a dataset into halves – one comprises 
greater values, and the other comprises lesser ones. For a specified dataset, it can be 
considered as the “middle” value. For example, in the dataset {1, 3, 3, 4, 5, 6, 7, 8, 9}, 
the median is 5, which is fourth largest, and fourth smallest number in the dataset.
*/
SELECT cast(ltd_bus_class  as INT) ltd_bus_class,
       cast(AVG(total_cost) as decimal (8,2)) AS MEDIANCOST
into -- select * from -- drop table 
#classMedian
FROM   (SELECT ltd_bus_class, 
               total_cost, 
               ROW_NUMBER() 
                 OVER ( 
                   PARTITION BY ltd_bus_class 
                   ORDER BY total_cost ASC, ltd_bus_class ASC) AS ROWASC, 
               ROW_NUMBER() 
                 OVER ( 
                   PARTITION BY ltd_bus_class 
                   ORDER BY total_cost DESC)                   AS ROWDESC 
        FROM   ##prepStatPC SOH) X 
WHERE  ROWASC IN ( ROWDESC, ROWDESC - 1, ROWDESC + 1 ) 
GROUP  BY ltd_bus_class 
ORDER  BY ltd_bus_class;



select rn = row_number() OVER (Partition by groupNumb order by groupNumb,cast(ltd_bus_class as INT)	) , *
into -- select * from -- drop table
##maintenanceCostPivot 
FROM (
select 1 groupNumb, 'all costs by bus class' as RptGroup,* from ##pivotAllCost Where isnumeric(ltd_bus_class) = 1
UNION
select 2 ,'road calls cost by bus class',* from ##pivotRoadCalls Where isnumeric(ltd_bus_class) = 1
UNION
select 3, 'pm costs by bus class', * from ##pivotPMClass Where isnumeric(ltd_bus_class) = 1
) o
order by groupNumb,cast(ltd_bus_class as INT)

 
-- SUMMARY
select woAllOpened = count(distinct work_order_no)
,totalWorkOrderHours = sum(lm_hours)
,sum(case when rcType = 'Road Call' then lm_hours else 0.00 end) as RoadCallHours
,sum(case when rcType = 'Road Call' then 1 else 0.00 end) as RoadCallCount
,percOfHoursRoadCalls = case when sum(case when rcType = 'Road Call' then lm_hours else 0.00 end) = 0 then 0 else
				sum(case when rcType = 'Road Call' then lm_hours else 0.00 end) end /sum(lm_hours) * 100 
,percOfWorkRoadCalls = case when sum(case when rcType = 'Road Call' then 1 else 0.00 end) = 0 then 0 else
				sum(case when rcType = 'Road Call' then 1 else 0.00 end) end /count(distinct work_order_no) * 100 
,PMWorkCount	= sum(case when job_type = 'PM' then 1 else 0 end) 
,percOfHoursPMs = case when sum(case when job_type = 'PM' then lm_hours else 0 end) = 0 then 0 else
				sum(case when job_type = 'PM' then lm_hours else 0 end ) end /sum(lm_hours) * 100 
,costAvgAll = avg(total_cost) 
,costAvgRC = cast(avg(case when rcType = 'Road Call' then total_cost else 0 end) as decimal(10,2))  
,costAvgPM = cast(avg(case when job_type = 'PM' then total_cost else 0 end ) as decimal(10,2)  )
,countAllOpen = sum(case when datetime_in_service is null then 1 else 0 end)
,countAllClosed = sum(case when datetime_in_service is not null then 1 else 0 end)
,countRCOpen = sum(case when datetime_in_service is null and rctype = 'Road Call' then 1 else 0 end)
,countRCClosed = sum(case when datetime_in_service is not null  and rctype = 'Road Call' then 1 else 0 end)
,countPMOpen = sum(case when datetime_in_service is null and job_type = 'PM' then 1 else 0 end)
,countPMClosed = sum(case when datetime_in_service is not null  and job_type = 'PM' then 1 else 0 end)
,hoursAvgToFirstLabor = cast(avg(min_to_first_labor/60.00) as decimal(10,3))
,avgHoursSpent = avg(lm_hours)  -- 
,avgHoursRCSpent = avg(case when rctype = 'Road Call' then lm_hours else 0 end)
,avgHoursPMSpent = avg(case when job_type = 'PM' then lm_hours else 0 end)
,outofServiceAvgHours = avg(hoursOutOfService)
,outofServiceRCAvgHours = cast(avg(case when rcType = 'Road Call' then hoursOutOfService else 0 end) as decimal(10,3))
,outofServicePMAvgHours = cast(avg(case when job_type = 'PM' then hoursOutOfService else 0 end) as decimal(10,3))
,hoursRCAvgToFirstLabor = cast(avg(case when rcType = 'Road Call' then min_to_first_labor/60.00 else 0 end) as decimal(10,3)), 
maxCostPM = (select cast(isnull(max(total_cost),0) as decimal(8,2)) from ##stagePMwork) ,
maxCostRC = (select cast(isnull(max(total_cost),0) as decimal(8,2)) from  ##stageRoadCalls ),
maxCostAll = (select cast(isnull(max(total_cost),0) as decimal(8,2)) from ##stageAllCalls ),
avgCostPM = (select cast(isnull(avg(total_cost),0) as decimal(8,2)) from ##stagePMwork ),
avgCostRC = (select cast(isnull(avg(total_cost),0) as decimal(8,2)) from ##stageRoadCalls ),
avgCostAll = (select cast(isnull(avg(total_cost),0) as decimal(8,2)) from ##stageAllCalls )
	into -- select * from 
#summaryOverview -- select * 
from ##prepStatPC


-- CHARTED Closed Request Counts
select rn = row_number() OVER (order by yearWk desc) ,
	 yearWk as 'Year Wk Closed', count(distinct work_order_no) countClosed 
	into -- drop table 
	#summaryByWeekOverview
	 from ##prepStatPC 
	where datetime_in_service is not null 
group by yearWk


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

declare @header1 varchar(max) = '|Summary of KPIs through the Most Recent 15 Weeks||'
select @htmlmax1 =  @htmlmax1 + 
 (SELECT CONVERT(NVARCHAR(MAX), (SELECT
    (SELECT @header1 FOR XML PATH(''), TYPE) AS 'caption',
    (SELECT 'Sort' as th, 'Metric' AS th, 'KPI................' AS th FOR XML RAW('tr'), ELEMENTS, TYPE) AS 'thead',
     (select s as td, a as td, g as td from (
		SELECT 1 as s,'Count Work Orders Opened' a, 'QQQ'+cast(cast(woAllOpened as INT) as varchar(20)) AS g 
				FROM #summaryOverview 
		UNION
		SELECT 2 as s,'Count Road Call Work Orders Opened' a, 'QQQ'+cast(cast(RoadCallCount as INT) as varchar(20)) AS g 
				FROM #summaryOverview 
		UNION
		SELECT 3 as s,'Count PM Work Orders Opened' a, 'QQQ'+cast(cast(PMWorkCount as INT) as varchar(20)) AS g 
				FROM #summaryOverview 
		UNION
		SELECT 4 as s,'Count Work Orders Closed' a, 'QQQ'+cast(cast(countAllClosed as INT) as varchar(20)) AS g 
				FROM #summaryOverview 
		UNION
		SELECT 5 as s,'Count Road Call Work Orders Closed' a, 'QQQ'+cast(cast(countRCClosed as INT) as varchar(20)) AS g 
				FROM #summaryOverview 
		UNION
		SELECT 6 as s,'Count PM Work Orders Closed' a, 'QQQ'+cast(cast(countPMClosed as INT) as varchar(20)) AS g 
				FROM #summaryOverview 
		UNION
		SELECT 7 as s,'Total of All Opened Work Orders Hours Worked' a, 'QQQ'+cast(cast(totalWorkOrderHours as decimal(10,2)) as varchar(20)) from #summaryOverview
		UNION
		SELECT 8 as s,'Road Calls as Percent of the Count of Opened Work Orders' a, 'QQQ'+cast(cast(percOfWorkRoadCalls as decimal(10,1)) as varchar(20))+'%' AS g FROM #summaryOverview 
		UNION
		SELECT 9 as s,'Road Call Hours as a Percent of Hours Worked on All Opened Work Orders' a, 'QQQ'+cast(cast(percOfHoursRoadCalls as decimal(10,1)) as varchar(20))+'%' as g from #summaryOverview
		UNION
		SELECT 10 as s,'PM as Percent of the Count of Opened Work Orders' a, 'QQQ'+cast(cast(PMWorkCount as decimal(10,1)) as varchar(20))+'%' AS g FROM #summaryOverview 
		UNION
		SELECT 11 as s,'PM Hours as a Percent of Hours Worked on All Opened Work Orders' a, 'QQQ'+cast(cast(percOfHoursPMs as decimal(10,1)) as varchar(20))+'%' as g from #summaryOverview
		UNION 
		SELECT 12 as s, 'Avg Cost of All Work Orders' a, 'QQQ'+cast(cast(costAvgAll as decimal(10,2)) as varchar(20)) AS g FROM #summaryOverview
		UNION 
		SELECT 13 as s, 'Avg Cost of Road Call Work Orders' a, 'QQQ'+cast(cast(costAvgRC as decimal(10,2)) as varchar(20)) as g from #summaryOverview
		UNION
		SELECT 14 as s,'Avg Cost of PM Work Orders' a, 'QQQ'+cast(cast(costAvgPM as decimal(10,2)) as varchar(20)) as g from #summaryOverview
		UNION 
		SELECT 15 as s, 'Avg Hours of All Work Orders' a, 'QQQ'+cast(cast(avgHoursSpent as decimal(10,2)) as varchar(20)) AS g FROM #summaryOverview
		UNION 
		SELECT 16 as s, 'Avg Hours of Road Call Work Orders' a, 'QQQ'+cast(cast(avgHoursRCSpent as decimal(10,2)) as varchar(20)) as g from #summaryOverview
		UNION
		SELECT 17 as s,'Avg Hours of PM Work Orders' a, 'QQQ'+cast(cast(avgHoursPMSpent as decimal(10,2)) as varchar(20)) as g from #summaryOverview
		UNION	
		SELECT 18 as s,'All Open Work Order Count' a, 'QQQ'+cast(cast(countAllOpen as decimal(10,2)) as varchar(20)) AS g FROM #summaryOverview
		UNION 
		SELECT 19 as s,'Road Call Open Work Order Count' a, 'QQQ'+cast(cast(countRCOpen as decimal(10,2)) as varchar(20)) AS g FROM #summaryOverview
		UNION 
		SELECT 20 as s,'PM Open Work Order Count' a, 'QQQ'+cast(cast(countPMOpen as decimal(10,2)) as varchar(20)) AS g FROM #summaryOverview
		UNION 
		SELECT 21 as s,'Avg Out of Service Hours' a, 'QQQ'+cast(cast(outofServiceAvgHours as decimal (10,2)) as varchar(20)) AS g FROM #summaryOverview
		UNION 
		SELECT 22 as s,'Avg Out of Service Road Call Hours' a, 'QQQ'+cast(cast(outofServiceRCAvgHours as decimal (10,2)) as varchar(20)) AS g FROM #summaryOverview
		UNION 
		SELECT 23 as s,'Avg Out of Service PM Hours' a, 'QQQ'+cast(cast(outofServicePMAvgHours as decimal (10,2)) as varchar(20)) AS g FROM #summaryOverview
		UNION 
		SELECT 24 as s,'Avg Hours to Road Call First Labor' a, 'QQQ'+cast(cast(hoursRCAvgToFirstLabor as decimal (10,2)) as varchar(20)) AS g FROM #summaryOverview 
		UNION 
		SELECT 25 as s,'Avg Hours to First Labor' a, 'QQQ'+cast(cast(hoursAvgToFirstLabor as decimal (10,2)) as varchar(20)) AS g FROM #summaryOverview 
		 ) x
    FOR XML RAW('tr'), ELEMENTS, TYPE
    ) AS 'tbody'
  FOR XML PATH(''), ROOT('table'))));



 --drop table #setup9992-- 
 --drop table ##htmlData
--
-- select * from #setup9992
create table #setup9992 (rn INT identity(1,1),column_names varchar(90), [ordinal_position] smallint, datatype varchar(90))
insert #setup9992 (column_names, ordinal_position, datatype)
select column_name, [ordinal_position], DATA_TYPE
FROM TEMPDB.INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME LIKE '%maintenanceCostPivot%' 



declare @colhdrsTH nvarchar(max) = ( 
SELECT STUFF(
             (SELECT ', ''' + column_names +''' as th'  
              FROM (select distinct column_names from #setup9992 where datatype = 'decimal' ) t1
              FOR XML PATH (''))
             , 1, 1, ''))
--select @colhdrsTH3

declare @colhdrsVAL nvarchar(max) = ( 
SELECT STUFF(
             (SELECT ', isnull([' + column_names +'],0) as td'  
              FROM (select distinct column_names from #setup9992 where datatype = 'decimal' ) t1
              FOR XML PATH (''))
             , 1, 1, ''))
--select @colhdrsVAL3



declare @header nvarchar(max)
declare @htmlcmd nvarchar(max) = ''
declare @htmlout nvarchar(max) = ''
declare @htmlcost nvarchar(max) = ''
select @htmlcmd = '
declare @header varchar(max) = ''|Maintenance Work Order Costs by LTD Bus Class||''
select 
 (SELECT CONVERT(NVARCHAR(MAX), (SELECT
    (SELECT @header FOR XML PATH(''''), TYPE) AS ''caption'',
    (SELECT ''LTD Bus Class'' AS th, '+@colhdrsTH+' FOR XML RAW(''tr''), ELEMENTS, TYPE) AS ''thead'',
        (
    SELECT ltd_bus_class as td, '+@colhdrsVAL+' 
      FROM ##maintenanceCostPivot where groupNumb = 1
      ORDER BY cast(ltd_bus_class as INT)
    FOR XML RAW(''tr''), ELEMENTS, TYPE
    ) AS ''tbody''
  FOR XML PATH(''''), ROOT(''table''))));
  '
  --drop table ##htmldata

create table ##htmlData (htmlval varchar(max))
INSERT ##htmlData (htmlval)
  EXEC (@htmlcmd)
  select @htmlcost = (select top 1 htmlval from ##htmlData)

  select @htmlcost = (select replace(@htmlcost, '</td><td>','</td><td class="alignRight">')) -- '<td class="alignRight">')
    --select @htmlcost 



  
-- PIVOT AGING BUCKET WORK ORDERS
select * 
into -- select * from -- drop table 
##PivotBuckets 
from (

select ltd_bus_class,isnull([0-9 Days],0) '0-9 Days'
					,isnull([10-19 Days],0) '10-19 Days'
					,isnull([20-29 Days],0) '20-29 Days'
					,isnull([30-39 Days],0) '30-39 Days'
					,isnull([40-49 Days],0) '40-49 Days'
					,isnull([50+ Days],0) '50+ Days'
FROM (select ltd_bus_class, openWorkOrderAging, count(*) work_count
			from ##prepStatPC where openWorkOrderAging is not null
			group by ltd_bus_class,openWorkOrderAging
	 ) s
PIVOT ( SUM(work_count) for openWorkOrderAging in ([0-9 Days],[10-19 Days],[20-29 Days],[30-39 Days],[40-49 Days],[50+ Days])) as p
) o
order by cast(ltd_bus_class as INT)



-- select * from #setup9993 -- drop table #setup9993
create table #setup9993 (rn INT identity(1,1),column_names varchar(90), [ordinal_position] smallint, datatype varchar(90))
insert #setup9993 (column_names, ordinal_position, datatype)
select column_name, [ordinal_position], DATA_TYPE
FROM TEMPDB.INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME LIKE '%PivotBucket%' order by [ordinal_position]


declare @colhdrsTH3 nvarchar(max) = (
SELECT STUFF(
             (SELECT ', ''' + column_names +''' as th'  
              FROM (select distinct column_names from #setup9993 where datatype = 'int' ) t1
              FOR XML PATH (''))
             , 1, 1, '')) 
 

declare @colhdrsVAL3 nvarchar(max) = ( 
SELECT STUFF(
             (SELECT ', [' + column_names +'] as td'  
              FROM (select distinct column_names from #setup9993 where datatype = 'int' ) t1
              FOR XML PATH (''))
             , 1, 1, ''))
--select @colhdrsVAL3

declare @header3 nvarchar(max)
declare @htmlcmd3 nvarchar(max) = ''
declare @htmlout3 nvarchar(max) = ''
declare @htmldone3 nvarchar(max) = ''
select @htmlcmd3 = '
declare @header varchar(max) = ''|Maintenance Work Order Aging by LTD Bus Class||''
select 
 (SELECT CONVERT(NVARCHAR(MAX), (SELECT
    (SELECT @header FOR XML PATH(''''), TYPE) AS ''caption'',
    (SELECT ''LTD Bus Class'' AS th, '+@colhdrsTH3+' FOR XML RAW(''tr''), ELEMENTS, TYPE) AS ''thead'',
    (
    SELECT ltd_bus_class as td, '+@colhdrsVAL3+' 
      FROM ##PivotBuckets  
	   ORDER BY cast(ltd_bus_class as INT)
      FOR XML RAW(''tr''), ELEMENTS, TYPE
    ) AS ''tbody''
  FOR XML PATH(''''), ROOT(''table''))));
'  

-- drop table ##htmlData3 
select @htmlcmd3 = replace(replace(@htmlcmd3,'[[','['),']]',']')
--select @htmlcmd3
create table ##htmlData3 (htmlval varchar(max))
INSERT ##htmlData3 (htmlval)
  EXEC (@htmlcmd3)
  select @htmldone3 = (select top 1 htmlval from ##htmlData3)

  
 --select @htmldone3

 --SELECT ltd_bus_class as td,  '[0-9 Days]' as td, '[10-19 Days]' as td, '[20-29 Days]' as td, '[30-39 Days]' as td, '[40-49 Days]' as td, '[50+ Days]' as td        FROM ##PivotBuckets 


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
-- exec kpi.Send_Maintenance_PivotCosts
--select @htmldone

select @msgAll = @msgAll 
+ 
(select replace(replace(@htmlmax1,'|','<br>'),'<td>QQQ','<td class="alignRight">'))
+' 
<br><br>'
+
(select replace(replace(@htmldone3,'|','<br>'),'<td>','<td class="alignRight">'))
+' 
<br><br>' 
 + 
(select replace(@htmlcost,'|','<br>'))
+' 
<br><br><br>
<p class="foots">For information about these KPIs email: support@ltd.org<br><br>
Confidentiality Statement: The contents of this e-mail and any attachments are intended solely for the addressee.  The information may also be confidential and/or legally privileged.  This transmission is sent for the sole purpose of delivery to the intended recipient.  If you have received this transmission in error, any use, reproduction, or dissemination of this transmission is strictly prohibited.  If you are not the intended recipient, please immediately notify the sender by reply e-mail, support@ltd.org and delete this message and its attachments, if any.  E-mail is covered by the Electronic Communications Privacy Act, 18 USC SS 2510-2521 and is legally privileged. Messages to and from this email may also be exempt from public disclosure under 49 CFR Part 15.15(b) as Sensitive Security Information.'

declare @headerClean varchar(90) = ''
select @headerClean = 'Maintenance Work Order Count, Summary Costs and Aging' -- (select replace(@header,'|',' - '))

--select @msgAll

exec msdb..sp_send_dbmail @recipients = 'barb.eichberger@ltd.org;'  , -- 'robin.mayall@ltd.org', -- would like to automate next, prepare a sign up sheet in power bi report server for email addresses
  @blind_copy_recipients ='barb.eichberger@ltd.org' ,
  @subject = @headerClean, 
  @body_format = 'html',
  @from_address = 'Automated KPI Emails <support@ltd.org>',
  @body = @msgAll





IF OBJECT_ID('tempdb.dbo.##htmlbig', 'U') IS NOT NULL
  DROP TABLE dbo.##htmlbig

IF OBJECT_ID('tempdb.dbo.##maintenanceCostPivot', 'U') IS NOT NULL
  DROP TABLE dbo.##maintenanceCostPivot

IF OBJECT_ID('tempdb.dbo.##pivotAllCost', 'U') IS NOT NULL
  DROP TABLE dbo.##pivotAllCost

IF OBJECT_ID('tempdb.dbo.##pivotBuckets', 'U') IS NOT NULL
  DROP TABLE dbo.##pivotBuckets

IF OBJECT_ID('tempdb.dbo.##pivotPMClass', 'U') IS NOT NULL
  DROP TABLE dbo.##pivotPMClass
  
IF OBJECT_ID('tempdb.dbo.##pivotRoadCalls', 'U') IS NOT NULL
  DROP TABLE dbo.##pivotRoadCalls

IF OBJECT_ID('tempdb.dbo.##prepStatPC', 'U') IS NOT NULL
  DROP TABLE dbo.##prepStatPC

IF OBJECT_ID('tempdb.dbo.##stageAllCalls', 'U') IS NOT NULL
  DROP TABLE dbo.##stageAllCalls

IF OBJECT_ID('tempdb.dbo.##stageRoadCalls', 'U') IS NOT NULL
  DROP TABLE dbo.##stageRoadCalls

IF OBJECT_ID('tempdb.dbo.##stagePMWork', 'U') IS NOT NULL
  DROP TABLE dbo.##stagePMWork

IF OBJECT_ID('tempdb.dbo.#setup9912', 'U') IS NOT NULL
  DROP TABLE dbo.#setup9912

IF OBJECT_ID('tempdb.dbo.#setup9992', 'U') IS NOT NULL
  DROP TABLE dbo.#setup9992

IF OBJECT_ID('tempdb.dbo.#classMedian', 'U') IS NOT NULL
  DROP TABLE #classMedian

IF OBJECT_ID('tempdb.dbo.#summaryOverview', 'U') IS NOT NULL
  DROP TABLE #summaryOverview

IF OBJECT_ID('tempdb.dbo.#htmlChartTable', 'U') IS NOT NULL
  DROP TABLE #htmlChartTable
 
IF OBJECT_ID('tempdb.dbo.#summaryByWeekOverview', 'U') IS NOT NULL
  DROP TABLE #summaryByWeekOverview

IF OBJECT_ID('tempdb.dbo.#chartoutput', 'U') IS NOT NULL
  DROP TABLE #chartoutput

IF OBJECT_ID('tempdb.dbo.##htmlData', 'U') IS NOT NULL
  DROP TABLE ##htmlData

IF OBJECT_ID('tempdb.dbo.##htmlData3', 'U') IS NOT NULL
  DROP TABLE ##htmlData3


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
