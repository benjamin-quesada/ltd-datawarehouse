SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [kpi].[Send_Operations_Performance] as
/*
CREATED:   20201118
AUTHOR :   B EICHBERGER
PURPOSE:   To produce HTML simple OPS kpis using dbemail.
		   Demo for Robin Mayall 
CHANGEDON: 
 CHANGEBY:  
   CHANGE:  

EXEC EXAMPLE: exec kpi.Send_Operations_Performance

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


IF OBJECT_ID('tempdb.dbo.#prepStat', 'U') IS NOT NULL
  DROP TABLE #prepStat

CREATE TABLE #prepStat(
	[wn] [bigint] NOT NULL,
	[yearWk] [varchar](14) NOT NULL,
	[calYearWk] varchar(32) NOT NULL,
	[calendar_date] [date] NULL,
	[rte_public] [varchar](8) NULL,
	[rte_and_dir] [varchar](10) NULL,
	[rte_dir] [varchar](1) NULL,
	[operator] [varchar](23) NULL,
	[trip_id] [numeric](10, 0) NULL,
	[trip_end] [char](5) NULL,
	[hour_Trip_end] [int] NULL,
	[min_Trip_end] [int] NULL,
	[sa_tp] [int] NOT NULL,
	[revenue_id] [char](1) NULL,
	[overload_id] [int] NULL,
	[the_bus] [varchar](20) NULL,
	[tp] [varchar](8) NULL,
	[tp_name] [varchar](50) NULL,
	[early] [numeric](5, 0) NULL,
	[late] [numeric](5, 0) NULL,
	[missing] [numeric](5, 0) NULL,
	[ontime] [numeric](5, 0) NULL,
	[not_ontime] [numeric](7, 0) NULL,
	[adhere_min] [numeric](9, 2) NULL,
	[adhere_sec] [numeric](11, 0) NULL
) ON [PRIMARY]

INSERT #prepStat (
		[wn]
      ,[yearWk]
	  ,calYearWk
      ,[calendar_date]
      ,[rte_public]
      ,[rte_and_dir]
      ,[rte_dir]
      ,[operator]
      ,[trip_id]
      ,[trip_end]
      ,[hour_Trip_end]
      ,[min_Trip_end]
      ,[sa_tp]
      ,[revenue_id]
      ,[overload_id]
      ,[the_bus]
      ,[tp]
      ,[tp_name]
      ,[early]
      ,[late]
      ,[missing]
      ,[ontime]
      ,[not_ontime]
      ,[adhere_min]
      ,[adhere_sec])
SELECT [wn]
      ,i.[yearWk]
	  ,d.calYearWk
      ,[calendar_date]
      ,[rte_public]
      ,[rte_and_dir]
      ,[rte_dir]
      ,[operator]
      ,[trip_id]
      ,[trip_end]
      ,[hour_Trip_end]
      ,[min_Trip_end]
      ,[sa_tp]
      ,[revenue_id]
      ,[overload_id]
      ,[the_bus]
      ,[tp]
      ,[tp_name]
      ,[early]
      ,[late]
      ,[missing]
      ,[ontime]
      ,[not_ontime]
      ,[adhere_min]
      ,[adhere_sec]
FROM (
select wn = dense_rank() OVER (order by yearWk desc),* 
from (
	SELECT 
	yearWk = cast(year(calendar_date) as varchar(12)) + right('00' + cast(datepart("wk",calendar_date) as varchar(12)),2),
	calendar_date,
	v.rte_public,
	v.rte_and_dir,
	v.rte_dir,
	v.operator,
	v.trip_id,
	v.trip_end,
	hour_Trip_end = cast(left(v.trip_end, 2)as INT),
	min_Trip_end = cast(right(v.trip_end, 2) as INT),
	v.sa_tp,
	revenue_id,
	overload_id,
	v.the_bus,
	v.tp,
	v.tp_name,
	(v.adjusted_early) AS 'early'
	, (v.adjusted_late) AS 'late'
	, (v.adjusted_missing) AS 'missing'
	, (v.adjusted_ontime) AS 'ontime'
	, (v.adjusted_early) 
		+ (v.adjusted_late) 
		+ (v.adjusted_missing) as not_ontime
    ,[adhere_min]
	,[adhere_sec]
		FROM [tm].[ADHERENCE_METRICS] v
		join tm.DW_CALENDAR c on c.CALENDAR_ID = v.calendar_id 
WHERE c.CALENDAR_DATE >= dateadd("wk",-18,getdate())
) o

) i
JOIN (SELECT yearWk = cast([Year] as varchar(6)) + right('00'+cast([WeekOfYear] as varchar(2)),2) ,
				calyearWk = cast([Year] as varchar(6)) + right('00'+cast([WeekOfYear] as varchar(2)),2) + ' - '+
				   CONVERT(varchar,(DATEADD(week, DATEDIFF(week, -1, [CALENDAR_DATE]), -1)),101) 
			  FROM [ltd_dw].[tm].[DW_CALENDAR]
			 where DayOfWeekNbr = 1) d on d.yearWk = i.yearWk
WHERE wn between 1 and 16
order by i.yearWk
	
	-- select distinct wn, yearWk from #prepStat

-- SUMMARY SIGNIFICANT TIME POINT
select o.*, percOnTime2030 = (countOnTime2030/(countOnTime2030+countNotOnTime2030 ))*100
into -- select * from 
#summaryByWeekSIG
from (
select rcAlltp = count(distinct tp)
	 ,countTrips = count(distinct trip_id)
	 ,countRouteDir = count(distinct rte_and_dir)
	 ,countOperator = count(distinct Operator)
	 ,percOnTime = (sum(ontime)/(sum(not_ontime) + sum(ontime)))*100
	 ,countLate = sum(late)
	 ,countMissing = sum(missing)
	 ,countEarly = sum(early)
	 ,countOnTime = sum(ontime)
	 ,countOnTime2030 = sum(case when hour_trip_end >=20 and min_Trip_end >= 30 then ontime else 0 end)
	 ,countLate2030 = sum(case when hour_trip_end >=20 and min_Trip_end >= 30 then late else 0 end)
	 ,countMissing2030 = sum(case when hour_trip_end >=20 and min_Trip_end >= 30 then missing else 0 end)
	 ,countNotOnTime2030 = sum(case when hour_trip_end >=20 and min_Trip_end >= 30 then early else 0 end)
		 + sum(case when hour_trip_end >=20 and min_Trip_end >= 30 then late else 0 end)
		 + sum(case when hour_trip_end >=20 and min_Trip_end >= 30 then missing else 0 end)
	 ,AvSecAdh = avg([adhere_sec])
from #prepStat s  
) o



	 
-- SUMMARY ALL TIME POINT
select o.*, percOnTime2030 = (countOnTime2030/(countOnTime2030+countNotOnTime2030 ))*100
into -- select * from 
#summaryByWeekAll
from (
select rcAlltp = count(distinct tp)
	 ,countTrips = count(distinct trip_id)
	 ,countRouteDir = count(distinct rte_and_dir)
	 ,countOperator = count(distinct Operator)
	 ,percOnTime = (sum(ontime)/(sum(not_ontime) + sum(ontime)))*100
	 ,countLate = sum(late)
	 ,countMissing = sum(missing)
	 ,countEarly = sum(early)
	 ,countOnTime = sum(ontime)
	 ,countOnTime2030 = sum(case when hour_trip_end >=20 and min_Trip_end >= 30 then ontime else 0 end)
	 ,countLate2030 = sum(case when hour_trip_end >=20 and min_Trip_end >= 30 then late else 0 end)
	 ,countMissing2030 = sum(case when hour_trip_end >=20 and min_Trip_end >= 30 then missing else 0 end)
	 ,countNotOnTime2030 = sum(case when hour_trip_end >=20 and min_Trip_end >= 30 then early else 0 end)
		 + sum(case when hour_trip_end >=20 and min_Trip_end >= 30 then late else 0 end)
		 + sum(case when hour_trip_end >=20 and min_Trip_end >= 30 then missing else 0 end)
	 ,AvSecAdh = avg([adhere_sec])
from #prepStat a
)
o


-- OPTIONS FOR CHARTED Significant TimePoints
select  rn = row_number() OVER ( order by o.yearWk) 
,o.*, percOnTime2030 = (countOnTime2030/(countOnTime2030+countNotOnTime2030 ))*100
,d.calyearWk
into -- select * from 
#summaryOverviewSIG
from (
select z.yearWk
	 ,rcAlltp = count(distinct tp)
	 ,countTrips = count(distinct trip_id)
	 ,countRouteDir = count(distinct rte_and_dir)
	 ,countOperator = count(distinct Operator)
	 ,percOnTime = (sum(ontime)/(sum(not_ontime) + sum(ontime)))*100
	 ,countLate = sum(late)
	 ,countMissing = sum(missing)
	 ,countEarly = sum(early)
	 ,countOnTime = sum(ontime)
	 ,countOnTime2030 = sum(case when hour_trip_end >=20 and min_Trip_end >= 30 then ontime else 0 end)
	 ,countLate2030 = sum(case when hour_trip_end >=20 and min_Trip_end >= 30 then late else 0 end)
	 ,countMissing2030 = sum(case when hour_trip_end >=20 and min_Trip_end >= 30 then missing else 0 end)
	 ,countNotOnTime2030 = sum(case when hour_trip_end >=20 and min_Trip_end >= 30 then early else 0 end)
		 + sum(case when hour_trip_end >=20 and min_Trip_end >= 30 then late else 0 end)
		 + sum(case when hour_trip_end >=20 and min_Trip_end >= 30 then missing else 0 end)
	 ,AvSecAdh = avg([adhere_sec])
		from #prepStat z	
		where sa_tp = 1
group by z.yearWk ) o
 JOIN (SELECT yearWk = cast([Year] as varchar(6)) + right('00'+cast([WeekOfYear] as varchar(2)),2) ,
				calyearWk = cast([Year] as varchar(6)) + right('00'+cast([WeekOfYear] as varchar(2)),2) + ' - '+
				   CONVERT(varchar,(DATEADD(week, DATEDIFF(week, -1, [CALENDAR_DATE]), -1)),101) 
			  FROM [ltd_dw].[tm].[DW_CALENDAR]
			 where DayOfWeekNbr = 1) d on d.yearWk = o.yearWk
order by o.yearWk


	-- select distinct yearWk from #summaryOverviewSIG


-- drop table #setup9911
create table #setup9911 (rn INT identity(1,1),column_names varchar(90), [ordinal_position] smallint, datatype varchar(90))
insert #setup9911 (column_names, ordinal_position, datatype)
select column_name, [ordinal_position], DATA_TYPE
FROM TEMPDB.INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME LIKE '%summaryOverviewSIG%'


-- drop table #htmlChartTable
create table #htmlChartTable (rn INT identity(1,1), RowName1 varchar(90), Group1 varchar(90), Value1 float )
insert #htmlChartTable (RowName1, Group1, Value1)

 select distinct RowName,u.yearWk, u.percOnTime
 from (
 SELECT RowName =  ltrim(stuff((
    SELECT ' Percent '+ replace(replace(cast(column_names as varchar(max)) ,'perc',''),'2030',' after 20:30') + ' by Year and Week of Year'
    FROM #setup9911 WHERE datatype = 'numeric' and column_names = 'percOnTime'
    FOR XML PATH('')
    ), 1, 1, ''))
		from #setup9911 ) o
	Cross APPLY (select calyearWk as yearWk, percOnTime from #summaryOverviewSIG) u
order by rowname desc,yearWk

-- drop table #chartoutput 
create table #chartoutput (rn INT, RowName1 varchar(90), Group1 varchar(90), RPT_OUTPUT varchar(max))

declare @i int = 1
declare @r int = (select max(rn) from #htmlChartTable)
declare @rn1 varchar(90)
declare @rn2 varchar(90)
declare @rn INT = 1
declare @v1 float
declare @barchar varchar(1) = '?'
Declare @stringIt varchar(max) = ''

WHILE @i <= @r
BEGIN

SELECT @rn1 = (select RowName1 FROM #htmlChartTable where rn = @i)
SELECT @rn2 = (select Group1 FROM #htmlChartTable where rn = @i)
select @v1 = (select value1 from #htmlChartTable where rn = @i)
select @stringit = (select substring(replicate(@barchar,(round(value1,0))),70,99999) from #htmlChartTable where rn = @i)

	 
Insert #chartoutput (rn, RowName1, Group1, RPT_OUTPUT)
select @i, RowName1, Group1, @stringIt +' '+ cast(round(@v1,2) as varchar(8)) from #htmlChartTable where rn = @i


	 select @stringIt = ''
 
select @i = @i + 1
If @i > @r
	BREAK
	ELSE CONTINUE

END
-- select * from #chartoutput 
-- drop table #htmlChartTable2
create table #htmlChartTable2 (rn INT identity(1,1), RowName1 varchar(max), Group1 varchar(90), Value1 float )
insert #htmlChartTable2 (RowName1, Group1, Value1)
 select distinct RowName,u.yearWk, u.AvSecAdh
 from (
 SELECT RowName =  ltrim(stuff((
    SELECT 'Avg Seconds Non Performance by Year and Week of Year'
    FROM #setup9911 WHERE datatype = 'numeric' and column_names = 'AvSecAdh'
    FOR XML PATH('')
    ), 1, 1, ''))
		from #setup9911 ) o
	Cross APPLY (select calyearWk as yearWk, AvSecAdh from #summaryOverviewSIG) u
order by rowname desc,yearWk
-- select * from #htmlChartTable2 where value1 < 0
-- 
--drop table #chartoutput2 
create table #chartoutput2 (rn INT, RowName1 varchar(120), Group1 varchar(120), RPT_OUTPUT1 varchar(max), RPT_OUTPUT2 varchar(max))

declare @i2 int = 1
declare @r2 int = (select max(rn) from #htmlChartTable)
declare @rn12 varchar(90)
declare @rn22 varchar(90)
declare @v12 float
declare @barchar2 varchar(1) = '?'
Declare @stringIt2 varchar(max) = ''
Declare @stringIt2a varchar(max) = ''
Declare @stringIt2b varchar(max) = ''
DECLARE @minV INT
Declare @signTest TINYINT

WHILE @i2 <= @r2
BEGIN

SELECT @rn12 = (select RowName1 FROM #htmlChartTable2 where rn = @i2)
select @minV = (select abs(ceiling(Min(value1))) from #htmlChartTable2)
Select @signTest = (select case when value1 < 0 then 1 else 0 end from #htmlChartTable2 where rn = @i2 )
select @v12 = (select value1 from #htmlChartTable2 where rn = @i2 )

if @signTest = 1 -- negative number
BEGIN
-- TEST LINE
select @stringit2 = (select 'QQQ'+replicate('?',ceiling(abs(@v12*.33))) from #htmlChartTable where rn = @i2 )
select @stringIt2a = ''
END
		
	
if @signTest = 0 
BEGIN
select @stringit2 = (select 'QQQ') 
select @stringIt2b = (select replicate('?',ceiling(abs(@v12*.33))) from #htmlChartTable where rn = @i2  )
END
		

Insert #chartoutput2 (rn, RowName1, Group1, RPT_OUTPUT1, RPT_OUTPUT2)
select @i2, RowName1, Group1, @stringIt2  , @stringIt2b + ' '+ cast(round(@v12,2) as varchar(8)) from #htmlChartTable2 where rn = @i2

 select @stringIt2 = ''
 select @stringIt2a = ''
 select @stringIt2b = ''
 
select @i2 = @i2 + 1
If @i2 > @r2
	BREAK
	ELSE CONTINUE

END


declare @htmlmax1 nvarchar(max) = ''

declare @header1 varchar(max) = '|Summary of KPIs through the Most Recent 15 Weeks||'
select @htmlmax1 =  @htmlmax1 + 
 (SELECT CONVERT(NVARCHAR(MAX), (SELECT
    (SELECT @header1 FOR XML PATH(''), TYPE) AS 'caption',
    (SELECT 'Sort' as th, 'Metric' AS th, 'KPI.............' AS th FOR XML RAW('tr'), ELEMENTS, TYPE) AS 'thead',
     (select s as td, a as td, g as td from (
		SELECT 1 as s,'Average Count of Trips Per Week' a, replace('QQQ'+cast(round(avg(countTrips*1.00),2) as varchar(20)),'0000','') AS g FROM #summaryOverviewSIG 
		UNION
		SELECT 2 as s,'Average Count Time Points Arrived Early' a, replace('QQQ'+cast(round(avg(countEarly),2) as varchar(20)),'0000','') AS g FROM #summaryOverviewSIG 
		UNION
		SELECT 3 as s,'Average Count Time Points Arrived Late' a, replace('QQQ'+cast(round(avg(countLate),2) as varchar(20)),'0000','') AS g FROM #summaryOverviewSIG 
		UNION
		SELECT 4 as s,'Average Percent On Time' a, replace('QQQ'+cast(round(avg(percOnTime),2) as varchar(90)),'0000','')+'%' AS g FROM #summaryOverviewSIG
		UNION 
		SELECT 5 as s,'Average Percent Not On Time' a, replace('QQQ'+cast(round(avg(100-percOnTime),2) as varchar(20)),'0000','')+'%' AS g FROM #summaryOverviewSIG
		UNION 
		SELECT 6 as s,'Average Seconds Not On Time' a, replace('QQQ'+cast(round(avg(AvSecAdh),2) as varchar(20)),'0000','') AS g FROM #summaryOverviewSIG ) x
    FOR XML RAW('tr'), ELEMENTS, TYPE
    ) AS 'tbody'
  FOR XML PATH(''), ROOT('table'))));

 --select  @htmlmax1

declare @htmlmax nvarchar(max) = ''

declare @header varchar(max) = '|Weekly On Time Significant Time Point Performance by Year and Week of Year|Most Recent Week at the Top||'
select @htmlmax =  @htmlmax + 
 (SELECT CONVERT(NVARCHAR(MAX), (SELECT
    (SELECT @header FOR XML PATH(''), TYPE) AS 'caption',
    (SELECT 'Year and|Week of Year' AS th, 'On Time Performance by Week' AS th FOR XML RAW('tr'), ELEMENTS, TYPE) AS 'thead',
    (
    SELECT top 15 Group1 AS td, RPT_OUTPUT as td
      FROM #chartoutput AS c
      ORDER BY rn DESC
    FOR XML RAW('tr'), ELEMENTS, TYPE
    ) AS 'tbody'
  FOR XML PATH(''), ROOT('table'))));

  
declare @htmlmaxAdh nvarchar(max) = ''

declare @header2 varchar(max) = '|Weekly Seconds Avg Non Performance by Year and Week of Year|Significant Time Points Only|Most Recent Week at the Top||'
select @htmlmaxAdh =  @htmlmaxAdh + 
 (SELECT CONVERT(NVARCHAR(MAX), (SELECT
    (SELECT @header2 FOR XML PATH(''), TYPE) AS 'caption',
    (SELECT 'Year and|Week of Year' AS th,'Late' as th, 'Early - Avg Seconds Performance' AS th FOR XML RAW('tr'), ELEMENTS, TYPE) AS 'thead',
    (
    SELECT top 15 Group1 AS td, RPT_OUTPUT1 as td, RPT_OUTPUT2 as td
      FROM #chartoutput2 AS c
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
 /*
&block;
&#x02588; -- darkest to lightest --v
&#9608; -- not -->&#10074
&blk14;
&#x02591;
&#9617;
&blk12;
&#x02592;
&#9618;&blk34;
&#x02593;
&#9619;
*/

select @msgAll = @msgAll + 
(select replace(replace(@htmlmax1,'|','<br>'),'<td>QQQ','<td class="alignRight">'))
+' 
<br><br>'
+
(select replace(replace(replace(@htmlmaxAdh,'|','<br>'),'?','&#9608;'),'<td>QQQ','<td class="alignRight">'))
+'
<br><br>'
+ 
(select replace(replace(@htmlmax,'|','<br>'),'?','<span>&#9552;</span>'))
+' 
<br><br><br>
For information about these KPIs email: support@ltd.org<br><br>
Confidentiality Statement: The contents of this e-mail and any attachments are intended solely for the addressee.  The information may also be confidential and/or legally privileged.  This transmission is sent for the sole purpose of delivery to the intended recipient.  If you have received this transmission in error, any use, reproduction, or dissemination of this transmission is strictly prohibited.  If you are not the intended recipient, please immediately notify the sender by reply e-mail, support@ltd.org and delete this message and its attachments, if any.  E-mail is covered by the Electronic Communications Privacy Act, 18 USC SS 2510-2521 and is legally privileged. Messages to and from this email may also be exempt from public disclosure under 49 CFR Part 15.15(b) as Sensitive Security Information.'
--select @msgAll

declare @headerClean varchar(max) 
select @headerclean = 'Operations Weekly Performance KPI'

exec msdb..sp_send_dbmail @profile_name = 'SQLData',
  @recipients = 'barb.eichberger@ltd.org;Aimee.Reichert@ltd.org;Cheryl.Munkus@ltd.org' , -- 'robin.mayall@ltd.org', -- would like to automate next, prepare a sign up sheet in power bi report server for email addresses
  @blind_copy_recipients ='barb.eichberger@ltd.org' ,
  @subject = @headerClean, 
  @body_format = 'html',
  @from_address = 'Automated KPI Emails <support@ltd.org>',
  @body = @msgAll




  
END TRY	  

BEGIN CATCH

       DECLARE @profile VARCHAR(255) = (
                    SELECT NAME
                    FROM msdb.dbo.sysmail_profile where name = 'SQLData'
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
