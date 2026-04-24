SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [kpi].[Send_Operations_Absences] as
/*
CREATED:   20201123
AUTHOR :   B EICHBERGER
PURPOSE:   To produce HTML simple OPS kpis using dbemail.
		   Demo for Robin Mayall 
CHANGEDON: 
 CHANGEBY:  
   CHANGE:  

EXEC EXAMPLE: exec kpi.Send_Operations_Absences

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

IF OBJECT_ID('tempdb.dbo.##pivotPayType', 'U') IS NOT NULL
drop table ##pivotPayType
IF OBJECT_ID('tempdb.dbo.#prepAStat', 'U') IS NOT NULL
drop table #prepAStat
IF OBJECT_ID('tempdb.dbo.#yearFilter', 'U') IS NOT NULL
drop table #yearFilter
IF OBJECT_ID('tempdb.dbo.##prepOStat', 'U') IS NOT NULL
drop table ##prepOStat
IF OBJECT_ID('tempdb.dbo.##summaryA', 'U') IS NOT NULL
drop table ##summaryA
IF OBJECT_ID('tempdb.dbo.#summaryOverallOps', 'U') IS NOT NULL 
drop table #summaryOverallOps
IF OBJECT_ID('tempdb.dbo.#summaryO', 'U') IS NOT NULL
drop table #summaryO
IF OBJECT_ID('tempdb.dbo.#summaryWeeklyOverview', 'U') IS NOT NULL
drop table #summaryWeeklyOverview

select yearWk, personnelID, rtrim(ltrim(o.emp_sid)) emp_sid, s.supervisor, absCode
, Replace(c.pay_category,'Absenteeism','Absence') pay_category
,codeTypeDesc, codeDesc
--, cast((isnull(absSeconds,0)/3600) as decimal (12,3)) absHours
, cast((isnull(timeWorkedSeconds,0)/3600) as decimal(12,2)) timeWorked
, cast((isnull(premiumTime,0)/3600) as decimal(12,2)) premiumHours
, cast((isnull(leaveTime,0)/3600) as decimal(12,2)) leaveHours
into  -- select * from -- drop table 
#prepAStat 
from (
SELECT convert(VARCHAR(32), absence.absDateBegin, 112) + 100000000 absDateBeginCalKey
	,yearWk = cast(year(absence.absDateBegin) as varchar(12)) + right('00' + cast(datepart("wk",absence.absDateBegin) as varchar(12)),2)
	,absence.absDateBegin
	,absence.emp_sid
	,timeWorked timeWorkedSeconds
	,premiumTime
	,leaveTime
	,daysEffective
	,dailyAbsence.absCode
	,cds.codeSet
	,cds.description AS codeDesc
	,ct.description AS codeTypeDesc
	,absPayCode
	,accrualLeaveType
	,workWeek
	,personnelID
	,lastName
	,firstName
	,mi
	,lastDayWorked
	,lastPlatformWorked
	,dailyAbsence.OpDate 
	,convert(VARCHAR(32), dailyAbsence.OpDate, 112) + 100000000 OpDateCalKey
FROM [ltd-ops].midas.dbo.absence absence WITH (NOLOCK)
	,[ltd-ops].midas.dbo.dailyAbsence dailyAbsence WITH (NOLOCK)
	,[ltd-ops].midas.dbo.dailyEmployee dailyEmployee WITH (NOLOCK)
	,[ltd-ops].midas.dbo.employee employee WITH (NOLOCK)
	,[ltd-ops].midas.[dbo].[codes] cds WITH (NOLOCK)
	,[ltd-ops].midas.[dbo].[codeTypes] ct WITH (NOLOCK)
WHERE absence.emp_SID = dailyAbsence.emp_SID
	AND absence.absCode = dailyAbsence.absCode
	AND absence.absDateBegin = dailyAbsence.absDateBegin
	AND absence.absTimeBegin = dailyAbsence.absTimeBegin
	AND dailyEmployee.division = dailyAbsence.division
	AND dailyEmployee.emp_SID = absence.emp_SID
	AND dailyEmployee.emp_SID = dailyAbsence.emp_SID
	AND dailyEmployee.opDate = dailyAbsence.opDate
	AND employee.emp_SID = absence.emp_SID
	AND employee.emp_SID = dailyAbsence.emp_SID
	AND employee.emp_SID = dailyEmployee.emp_SID
	AND dailyAbsence.absCode = cds.codeValue
	AND cds.codeType = ct.codeType
	AND dailyAbsence.opDate >= '2018-07-01 00:00:00'
	AND ct.[description] like ('Abs%')
	AND absence.absDateBegin >= dateadd("wk",-17, getdate())
	and cds.codetype = 'ABAT'
) o
left join [ltd-ops].midas.[dbo].[ltd_operator_supervisor] s on rtrim(ltrim(s.[emp_sid])) = rtrim(ltrim(o.emp_sid))
left join [ltd-ops].[midas].[dbo].[ltd_pay_categories_2020] c on c.codevalue = absCode


select yearWk, rn = row_number() OVER (order by YearWk) 
into #yearFilter
from (select distinct yearWk from #prepAStat) w

-- OPERATING PAID TIME
select y.yearWk,RTRIM(LTRIM(emp_sid)) emp_sid,[paytype],codeDesc, pay_category, isnull(calctime,0) calctime
into  -- select * from -- drop table 
##prepOStat
from 
	(
	select rtrim(ltrim( emp_sid)) emp_sid
		  ,yearWk = cast(year(opdate) as varchar(12)) + right('00' + cast(datepart("wk",opdate) as varchar(12)),2)
		  ,[workclass] = workclass
		  ,[paytype]   = paytype
		  ,[codeDesc]  = c.[description]
		  ,l.pay_category
		  ,[calctime]  = calctime -- select * 
	  from [ltd-ops].midas.dbo.dailyemployeetimedetail d WITH (NOLOCK)
	  inner join [ltd-ops].midas.dbo.codes c WITH (NOLOCK) on c.codeValue = d.paytype
	  inner join -- select * from 
	  [ltd-ops].[midas].[dbo].[ltd_pay_categories_2020] l on l.[codevalue] = d.payType 
	 where 1=1
	 and paysource = 'rpay'
	 and opdate >= dateadd("wk",-16, getdate())
	 and paytype not in ( 'PL','PG','DBRF','GU','SB') AND NOT ( paytype = 'W/EO' and l.pay_category = 'W/E Overtime Adjustment')
	 ) y	 
join (select yearWk from #yearFilter where rn < 18 and rn > 1) t on t.yearWk = y.yearWk
 
-- SUMMARY Overall Weekly Absences 
select  rn = row_number() OVER (order by yearWk) , yearWk
--,pay_category
--,timeWorkedHours 
	--,premiumHours
	,sum(case when pay_category like '%unan%' then leaveHours else 0 end) as unanticipated
	,sum(case when pay_category not like '%unan%' then leaveHours else 0 end) as anticipated
into -- select * from -- drop table 
##summaryA
from (
select s.yearWk,pay_category
	,sum(timeWorked) timeWorkedHours
	,sum(leaveHours) leaveHours
	,sum(premiumHours) premiumHours
from #prepAStat s
join (select yearWk from #yearFilter where rn < 18 and rn > 1) t on t.yearWk = s.yearWk
where pay_category <> 'Uncategorized'
group by s.yearWk,pay_category
having (
--sum(timeWorked) <> 0 OR 
	sum(leaveHours) <> 0
	--OR sum(premiumHours) <> 0 
	) 
	)
o
group by yearWk


select distinct paytype 
into #paylist
from ##prepOStat 
order by paytype



-- SUMMARY Overall Weekly Operating Excluding Platform Pivot
declare @colhdrsSel nvarchar(max) = ( 
SELECT STUFF(
             (SELECT ', cast(isnull([' + paytype +'],0) as decimal(10,2)) '+ '['+  paytype + ']'
              FROM (select distinct paytype from #paylist  ) t1
              FOR XML PATH (''))
             , 1, 1, ''))


declare @colhdrsSum nvarchar(max) = ( 
SELECT STUFF(
             (SELECT ', [' + paytype +']'  
              FROM (select distinct paytype from #paylist  ) t1
              FOR XML PATH (''))
             , 1, 1, ''))

declare @sqlcmd nvarchar(max) = ''
select @sqlcmd = @sqlcmd + 
'
select yearWk ,'+@colhdrsSel+'
into ##pivotPayType
FROM (select yearWk,paytype
	,cast(sum(calctime)/3600.00 as decimal(10,2)) calcOTime
from ##prepOStat
group by  yearWk,paytype
	 )
s
PIVOT ( 
	SUM(calcOTime) for paytype in ('+@colhdrsSum+')) as p'
--print @sqlcmd
-- select * from ##pivotPayType
exec sp_executesql @sqlcmd


-- SUMMARY Overall Weekly Operating Excluding Platform
select  rn = row_number() OVER (order by yearWk) , yearWk 
,countOperator
,calcOTime/3600.00 as opsHours
into -- select * from -- drop table
#summaryO 
from (
select b.yearWk
	,count(distinct emp_sid) countOperator
	,sum(calctime) calcOTime
from ##prepOStat b
join (select yearWk from #yearFilter where rn < 18 and rn > 1) t on t.yearWk = b.yearWk
 
group by b.yearWk
	 )
o




-- OPTIONS FOR CHARTED Percent unanticipated Absences
select rn = row_number() over (order by d.calyearWk)
,d.calyearWk as yearWk
, opsHours 
, a.absHours
, a.abuHours
,  a.absHours + a.abuHours as totalAbsHours
,opsHours + absHours + abuHours totalHours
,case when isnull(a.abuHours,0)=0 then 0 else cast(((absHours + abuHours) )/ a.abuHours as decimal(12,4)) end percOfAbsencesUnanticipated
--,cast((opsHours + absHours + abuHours)/ a.abuHours as decimal(12,4)) percOfAbsencesUnanticipated
,case when isnull(absHours,0) + isnull(abuHours,0) = 0 then 0 else cast((opsHours)/ (absHours + abuHours) as decimal(12,4)) end percOfOperationsAbsences
--,cast((opsHours + absHours + abuHours)/ (absHours + abuHours) as decimal(12,4)) percOfOperationsAbsences
,CountOperatorsRecorded = (select count(distinct p) from  
				(select distinct rtrim(ltrim(emp_sid collate SQL_Latin1_General_CP850_CI_AS))  p from ##prepOStat
				UNION
				select distinct rtrim(ltrim(personnelId collate SQL_Latin1_General_CP850_CI_AS))  from #prepAStat) o 
			)
into -- select * from -- drop table 
 #summaryWeeklyOverview
 from 
(select distinct yearWk from ##summaryA 
	union
 select distinct yearWk from ##summaryA) w
LEFT JOIN (SELECT yearWk = cast([Year] as varchar(6)) + right('00'+cast([WeekOfYear] as varchar(2)),2) ,
				calyearWk = cast([Year] as varchar(6)) + right('00'+cast([WeekOfYear] as varchar(2)),2) + ' - '+
				   CONVERT(varchar,(DATEADD(week, DATEDIFF(week, -1, [CALENDAR_DATE]), -1)),101) 
			  FROM [ltd_dw].[tm].[DW_CALENDAR]
			 where DayOfWeekNbr = 1) d on d.yearWk = w.yearWk
JOIN (select yearWk,sum(cast(OpsHours as decimal (12,2))) OpsHours from #summaryO group by yearWk) o on o.yearWk = w.yearWk 
JOIN (select yearWk,sum(anticipated) absHours , sum(unanticipated) abuHours from ##summaryA group by yearWk ) a on a.yearWk = w.yearWk 
--join (select yearWk from #yearFilter where rn < 16) t on t.yearWk = w.yearWk
order by d.calyearWk


select
avgWeeklyScheduledAbsenceHours = case when isnull(count(*), 0) = 0 then 0 else cast(sum(absHours)/count(*) as decimal(12,3)) end
,avgWeeklyUnanticipatedAbsenceHours = case when isnull(count(*), 0) = 0 then 0 else cast(sum(abuHours)/count(*)  as decimal(12,3)) end
,absPercUnanticipated = case when isnull(count(*), 0) = 0 then 0 else cast(sum(case when (abuHours * 1.00) = 0 then 0 else (absHours+abuHours)/(abuHours * 1.00) end)/count(*)  as decimal(12,3)) end
,opsHours = case when isnull(count(*), 0) = 0 then 0 else cast(sum(opsHours)/count(*) as decimal(12,3)) end
,maxOpsHours = cast(max(opsHours) as decimal(12,3))
,allRecordedHours = case when isnull(count(*), 0) = 0 then 0 else cast((sum(opsHours)+sum(absHours)+sum(abuHours))/count(*) as decimal(12,3)) end
,allRecordedOperators = 
		 (select count(distinct p) from  
				(select distinct rtrim(ltrim(emp_sid collate SQL_Latin1_General_CP850_CI_AS))  p from ##prepOStat
				UNION
				select distinct rtrim(ltrim(personnelId collate SQL_Latin1_General_CP850_CI_AS))  from #prepAStat) o 
			)
into -- select * from -- drop table 
#summaryOverallOps
from #summaryWeeklyOverview
--where rn <> 1 and rn <> 17



-- drop table #setup9911Ops
create table #setup9911Ops (rn INT identity(1,1),column_names varchar(90), [ordinal_position] smallint, datatype varchar(90))
insert #setup9911Ops (column_names, ordinal_position, datatype)
select column_name, [ordinal_position], DATA_TYPE
FROM TEMPDB.INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME LIKE '%summaryWeeklyOverview%'
-- select * from #setup9911Ops

-- drop table -- select * from #htmlChartTableOps
create table #htmlChartTableOps (rn INT identity(1,1), RowName1 varchar(90), Group1 varchar(90), Value1 float )
insert -- drop table
#htmlChartTableOps (RowName1, Group1, Value1)
 select distinct RowName,u.yearWk, u.percOfAbsencesUnanticipated
 from (
 SELECT RowName =  ltrim(stuff((
    SELECT ' Percent '+ replace(replace(cast(column_names as varchar(max)) ,'percOf',''),'AbsencesUnanticipated','Absences Unanticipated') + ' by Year and Week of Year'
    FROM #setup9911Ops WHERE datatype = 'decimal' and column_names = 'percOfAbsencesUnanticipated'
    FOR XML PATH('')
    ), 1, 1, ''))
		from #setup9911Ops ) o
	Cross APPLY (select yearWk, percOfAbsencesUnanticipated from #summaryWeeklyOverview) u
order by rowname desc,yearWk
-- select * from #htmlChartTableOps
-- drop table #chartoutputOps 

create table #chartoutputOps (rn INT, RowName1 varchar(90), Group1 varchar(90), RPT_OUTPUT varchar(max))

declare @i int = 1
declare @r int = (select max(rn) from #htmlChartTableOps)
declare @rn1 varchar(90)
declare @rn2 varchar(90)
declare @rn INT = 1
declare @v1 float
declare @barchar varchar(1) = '?'
Declare @stringIt varchar(max) = ''

WHILE @i < @r
BEGIN


select @stringIt = ''

SELECT @rn1 = (select RowName1 FROM #htmlChartTableOps where rn = @i)
SELECT @rn2 = (select Group1 FROM #htmlChartTableOps where rn = @i)
select @v1 = (select value1 from #htmlChartTableOps where rn = @i)
select @stringit = (select replicate(@barchar,value1) from #htmlChartTableOps where rn = @i)

Insert #chartoutputOps (rn, RowName1, Group1, RPT_OUTPUT)
select @i, RowName1, Group1, @stringIt +' '+ cast(round(@v1,2) as varchar(8))+' %' from #htmlChartTableOps where rn = @i

select @stringIt = ''
 
select @i = @i + 1
If @i > @r
	BREAK
	ELSE CONTINUE

END

-- select * from  #chartoutputOps

-- drop table #htmlChartTableOps2
create table #htmlChartTableOps2 (rn INT identity(1,1), RowName1 varchar(max), Group1 varchar(90), Value1 float, Value2 float )
insert #htmlChartTableOps2 (RowName1, Group1, Value1, Value2)
 select yearwk, yearwk group1, percOfAbsencesUnanticipated ,percOfOperationsAbsences 
 from #summaryWeeklyOverview
 where rn <> 1 and rn <> 17
order by yearWk
-- select * from #htmlChartTableOps2 where value1 < 0
-- 
--drop table #chartoutput2 
create table #chartoutput2 (rn INT, RowName1 varchar(255), Group1 varchar(120), RPT_OUTPUT1 varchar(max),  RPT_OUTPUT2 varchar(max))

declare @i2 int = 1
declare @r2 int = (select max(rn) from #htmlChartTableOps2)
declare @stringit2 varchar(max)
declare @stringit2b varchar(max)
declare @g2 varchar(32)
WHILE @i2 < @r2
BEGIN

select @g2 = (select Group1 from #htmlChartTableOps2 where rn = @i2)
select @stringit2 = (select replicate('@',ceiling(value2)) + ' ' + cast(cast(value2 as decimal(8,2) )as varchar(13)) +'% ' 
						  from #htmlChartTableOps2 where rn = @i2 )
select @stringIt2b = (select replicate('?',ceiling(value1)) + ' ' + cast(cast(value1 as decimal(8,2) )as varchar(13)) +'% ' 
						  from #htmlChartTableOps2 where rn = @i2 )
INSERT #chartoutput2 (RowName1 , Group1 , RPT_OUTPUT1 , RPT_OUTPUT2 ) 
select 'Percent of Overall Operational Hours and Percent Unanticipated of all Absence Hours', @g2 ,@stringIt2, @stringit2b

 select @stringIt2 = ''
 select @stringit2b = ''
 
select @i2 = @i2 + 1
If @i2 > @r2
	BREAK
	ELSE CONTINUE

END

-- select * from #chartoutput2

declare @htmlmax1 nvarchar(max) = ''

declare @header1 varchar(max) = '|Summary of KPIs through|the Most Recent 15 Weeks||'
select @htmlmax1 =  @htmlmax1 + 
 (SELECT CONVERT(NVARCHAR(MAX), (SELECT
    (SELECT @header1 FOR XML PATH(''), TYPE) AS 'caption',
    (SELECT 'Sort' as th, 'Metric' AS th, 'KPI.............' AS th FOR XML RAW('tr'), ELEMENTS, TYPE) AS 'thead',
     (select s as td, a as td, g as td from (
		SELECT 1 as s,'Avg Weekly Scheduled Absence Hours' a, 'QQQ'+cast(round(cast(avgWeeklyScheduledAbsenceHours as decimal(10,2)),2) as varchar(20)) AS g FROM #summaryOverallOps 
		UNION
		SELECT 2 as s,'Avg Weekly Unanticipated Absence Hours' a, rtrim('QQQ'+cast(round(cast(avgWeeklyUnanticipatedAbsenceHours as decimal(10,2)),2) as varchar(20))) AS g FROM #summaryOverallOps 
		UNION
		SELECT 3 as s,'Avg Weekly Percent of Unanticipated Absences' a, replace('QQQ'+cast(round(avg(cast(absPercUnanticipated as decimal(5,2))),2) as varchar(20))+'%','0000','') AS g FROM #summaryOverallOps 
		UNION
		SELECT 4 as s,'Avg Weekly Operational Hours Recorded' a, 'QQQ'+cast(round(cast(opsHours as decimal(10,2)),2) as varchar(90)) AS g FROM #summaryOverallOps
		UNION 
		SELECT 5 as s,'Avg Weekly Absence and Operational Hours' a, 'QQQ'+cast(round(cast(allRecordedHours as decimal(10,2)),2) as varchar(20))  AS g FROM #summaryOverallOps
		UNION 
		SELECT 6 as s,'Maximum Recorded Weekly Operational Hours' a, 'QQQ'+cast(round(cast(maxOpsHours as decimal(10,2)),2) as varchar(20))  AS g -- select * 
		FROM #summaryOverallOps
		UNION 
		SELECT 7 as s,'Total Unique Count Operators in Last 15 Weeks' a, 'QQQ'+cast(round(avg(cast(allrecordedOperators as INT)),0) as varchar(20)) AS g FROM #summaryOverallOps ) x
    FOR XML RAW('tr'), ELEMENTS, TYPE
    ) AS 'tbody'
  FOR XML PATH(''), ROOT('table'))));

 --select  @htmlmax1

declare @htmlmax nvarchar(max) = ''

--declare @header varchar(max) = '|Percent of Unanticipated Absences|by Week||'
--select @htmlmax =  @htmlmax + 
-- (SELECT CONVERT(NVARCHAR(MAX), (SELECT
--    (SELECT @header FOR XML PATH(''), TYPE) AS 'caption',
--    (SELECT 'Year and|Week of Year' AS th, 'Percent of All Absences|that were unanticipated, by Week' AS th FOR XML RAW('tr'), ELEMENTS, TYPE) AS 'thead',
--    (
--    SELECT top 15 Group1 AS td, RPT_OUTPUT as td
--      -- select * 
--	  FROM #chartoutputOps AS c
--      ORDER BY rn DESC
--    FOR XML RAW('tr'), ELEMENTS, TYPE
--    ) AS 'tbody'
--  FOR XML PATH(''), ROOT('table'))));

  
declare @htmlmaxPerc nvarchar(max) = ''

declare @header2 varchar(max) = '|Weekly Hours Avg Absences as a Percent of|All Absences and All Operational Hours|by Year and Week of Year|Most Recent Week at the Top||'
select @htmlmaxPerc =  @htmlmaxPerc + 
 (SELECT CONVERT(NVARCHAR(MAX), (SELECT
    (SELECT @header2 FOR XML PATH(''), TYPE) AS 'caption',
    (SELECT 'Year and|Week of Year' AS th,'Percent Unanticipated|Of All Absences' AS th ,'Percent All Absences|Of All Operational Hours' AS th FOR XML RAW('tr'), ELEMENTS, TYPE) AS 'thead',
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
(select replace(replace(replace(replace(replace(@htmlmaxPerc,'|','<br>'),'?','&#9608;'),'@','&#9618;'),'TTT','&#9608;') ,'RRR','&#9618;'))
+'
<br><br>'
+ 
(select replace(replace(@htmlmax,'|','<br>'),'?','<span>&#9608;</span>'))
+' 
<br><br><br>
For information about these KPIs email: support@ltd.org<br><br>
Confidentiality Statement: The contents of this e-mail and any attachments are intended solely for the addressee.  The information may also be confidential and/or legally privileged.  This transmission is sent for the sole purpose of delivery to the intended recipient.  If you have received this transmission in error, any use, reproduction, or dissemination of this transmission is strictly prohibited.  If you are not the intended recipient, please immediately notify the sender by reply e-mail, support@ltd.org and delete this message and its attachments, if any.  E-mail is covered by the Electronic Communications Privacy Act, 18 USC SS 2510-2521 and is legally privileged. Messages to and from this email may also be exempt from public disclosure under 49 CFR Part 15.15(b) as Sensitive Security Information.'
--select @msgAll

declare @headerClean nvarchar(max) 
select @headerclean = 'Operations Weekly Attendance KPIs'

exec msdb..sp_send_dbmail @profile_name = 'SQLData',
  @recipients = 'barb.eichberger@ltd.org;' , -- 'robin.mayall@ltd.org', -- would like to automate next, prepare a sign up sheet in power bi report server for email addresses
  @blind_copy_recipients ='barb.eichberger@ltd.org' ,
  @subject = @headerClean, 
  @body_format = 'html',
  @from_address = 'Automated KPI Emails <support@ltd.org>',
  @body = @msgAll


IF OBJECT_ID('tempdb.dbo.#prepAStat', 'U') IS NOT NULL
drop table #prepAStat
IF OBJECT_ID('tempdb.dbo.#yearFilter', 'U') IS NOT NULL
drop table #yearFilter
IF OBJECT_ID('tempdb.dbo.##prepOStat', 'U') IS NOT NULL
drop table ##prepOStat
IF OBJECT_ID('tempdb.dbo.##summaryA', 'U') IS NOT NULL
drop table ##summaryA
IF OBJECT_ID('tempdb.dbo.#summaryOverallOps', 'U') IS NOT NULL 
drop table #summaryOverallOps
IF OBJECT_ID('tempdb.dbo.#summaryO', 'U') IS NOT NULL
drop table #summaryO
IF OBJECT_ID('tempdb.dbo.#summaryWeeklyOverview', 'U') IS NOT NULL
drop table #summaryWeeklyOverview
IF OBJECT_ID('tempdb.dbo.##pivotPayType', 'U') IS NOT NULL
drop table ##pivotPayType

  
END TRY	  

BEGIN CATCH

       DECLARE @profile VARCHAR(255) = (
                    SELECT NAME
                    FROM msdb.dbo.sysmail_profile where name = 'SQLData'
                    )
       DECLARE @errormsg NVARCHAR(max)
             ,@error INT
             ,@message NVARCHAR(max)
             ,@xstate INT
             ,@errsev INT
             ,@sub VARCHAR(max);

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
