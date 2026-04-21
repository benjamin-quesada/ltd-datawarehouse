SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [rpt].[IT_in_the_life]
as

/******************************

CREATED BY	: B Eichberger
CREATED ON	: 20190101 (or so)
PURPOSE		: IT Life Report
			  exec rpt.IT_in_the_life

*/
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


declare @dats date = dateadd(year, -5,getdate()) 

DROP TABLE IF EXISTS #split
DROP TABLE IF EXISTS #desc;
create table #desc (
descid int identity(1,1),
datetm date not null,
descr varchar(max) not null)
insert #desc (datetm,descr)
select o.datm, o.[description] from (
select  DATEADD(mi, DATEDIFF(mi, GETUTCDATE(), GETDATE()),DATEADD(second, (createdtime/1000),{d '1970-01-01'})) datm
,REPLACE(REPLACE(replace(replace(replace(replace(replace (replace([description],'"',''),'#',''),'&lt;',''),'&quot;',''),'&amp;',''),'&gt;',''),'"',''),'.','') [description] FROM [ltd-itdb2].servicedesk_new.dbo.workorder WITH (NOLOCK)
union all
select  DATEADD(mi, DATEDIFF(mi, GETUTCDATE(), GETDATE()),DATEADD(second, (CREATEDTIME/1000),{d '1970-01-01'})) datm
,REPLACE(REPLACE(replace(replace(replace(replace(replace (replace([description],'"',''),'#',''),'&lt;',''),'&quot;',''),'&amp;',''),'&gt;',''),'"',''),'.','') [description]  from [ltd-itdb2].servicedesk_new.dbo.chargestable WITH (NOLOCK)
union all
select  DATEADD(mi, DATEDIFF(mi, GETUTCDATE(), GETDATE()),DATEADD(second, (CREATEDTIME/1000),{d '1970-01-01'})) datm
,REPLACE(REPLACE(replace(replace(replace(replace(replace (replace(NOTESTEXT,'"',''),'#',''),'&lt;',''),'&quot;',''),'&amp;',''),'&gt;',''),'"',''),'.','') notestext  from [ltd-itdb2].servicedesk_new.dbo.[Notes] WITH (NOLOCK)
union all
SELECT DATEADD(mi, DATEDIFF(mi, GETUTCDATE(), GETDATE()),DATEADD(second, (w.CREATEDTIME/1000),{d '1970-01-01'})) datm
,REPLACE(REPLACE(replace(replace(replace(replace(replace (replace([DEPTNAME],'"',''),'#',''),'&lt;',''),'&quot;',''),'&amp;',''),'&gt;',''),'"',''),'.','') notestext
  FROM [ltd-itdb2].[servicedesk_new].[dbo].[DepartmentDefinition] d
  join [ltd-itdb2].[servicedesk_new].[dbo].WorkOrder w on w.DEPTID = d.DEPTID

) o
WHERE datm >= @dats
and o.description is not null and datm is not null 



drop table if exists #split
create table #split (datd date not null, ITWord VARCHAR(255) not null)

DECLARE @workwords VARCHAR(255)
DECLARE @workdt date
DECLARE @strngLen int
DECLARE @i INT 
DECLARE @r INT

Select @r = (select count(*) from #desc)
select @i = 1

While @i <= @r
BEGIN


SET @workwords = (select descr from #desc where descid = @i)
SET @workdt =  (select datetm from #desc where descid = @i)
SET @strngLen = CHARINDEX(' ', @workwords)

WHILE CHARINDEX(' ', @workwords) > 0
BEGIN
    SET @strngLen = CHARINDEX(' ', @workwords);


    INSERT INTO #split
    SELECT @workdt, substring(@workwords,1,@strngLen - 1);
    
    SET @workwords = SUBSTRING(@workwords, @strngLen + 1, LEN(@workwords));
END

INSERT INTO #split (datd,ITWord)
SELECT @workdt, @workwords

Select @i = @i + 1
if @i > @r 
	 BREAK
ELSE CONTINUE

END

DECLARE @tody DATE = GETDATE()

truncate table rpt.it_life_word_cloud
insert rpt.it_life_word_cloud (itword,occu,work_year,last_refresh)

SELECT LOWER(replace(replace(replace(REPLACE(REPLACE(RTRIM(ltrim(ITWord)),'[','')
		,'thanks','thank you'),'thank yous','thank you')
		,'&',''),'  ',' ')) ITWord
	, count(*) occu , year(datd) as work_year, @tody last_refresh
from #split
where isnumeric(left(ITWord,1)) = 0 
AND
len(rtrim(ltrim(ITWord))) > 3
AND
ITWord not like '%.%'
AND
ITWord not like '%,%'
AND
ITWord not like '%\%'
AND
ITWord not like '%?%'
AND
ITWord not like 'F:%'
AND
ITWord not like 'P:%'
AND
ITWord not like '%AnalystP:%'
AND
ITWord not like '%)%'
AND
ITWord not like '%(%'
AND
ITWord not like '%;%'
AND
ITWord not like '%*%'
AND
ITWord not like '%-%'

AND
rtrim(ltrim(ITWord)) not in (
'stop',
'from',
'nbsp',
'draw',
'this',
'they',
'these',
'does',
'with',
'that',
'From:',
'still',
'Shawna',
'Lane',
'Transit',
'Name:',
'Sent:',
'Neil',
'Blickfeldt',
'Barb',
'Eichberger',
'Steve',
'Parrott',
'Cory',
'Graham',
'Harry',
'Sanger',
'Date:',
'Will',
'Bigelow',
'District',
'Jil',
'Shah',
'have',
'what',
's',
't',
'sopheap',
'suy',
'nick',
'holdway',
'benjamin',
'quesada',
'ian',
'tuck',
'chad',
'moore',
'riggs',
'bateman',
'richard',
'reakseker',
'michael',
'541',
'Subject:',
'into',
'then',
'after',
'like',
'sent',
'then',
'your',
'their',
'sch-',
'/></div>',
'analyst/administrative'
)
and ITWord NOT LIKE '%NBSP%'
and ITWord NOT LIKE '%DIV%'
and ITWord NOT LIKE '%<%'
and ITWord NOT LIKE '%>%'
and ITWord NOT LIKE '%=%'
and ITWord NOT LIKE '%:%'
and ITWord NOT LIKE '%font-%'
and ITWord NOT LIKE '%text-%'
AND ITWord NOT LIKE 'didn%t'
AND ITWord NOT LIKE '%nbsp%'
AND ITWord NOT LIKE '%ltdorg'
AND ITWord NOT LIKE '%@%'
group by ITWord, year(datd) 

insert rpt.it_life_word_cloud(itword,occu,work_year,last_refresh)
select 'thank you',399,work_year,cast(getdate() as date) from (
select distinct work_year from rpt.it_life_word_cloud) i

--delete from rpt.it_life_word_cloud where itword = 'thank you' and occu = 599

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
