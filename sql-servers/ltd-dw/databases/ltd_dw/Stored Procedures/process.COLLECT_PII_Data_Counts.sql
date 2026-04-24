SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [process].[COLLECT_PII_Data_Counts]
as

-- exec process.COLLECT_PII_Data_Counts

/*------------------LTD_GLOSSARY---------------
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


if (select count(*) from tempdb.sys.tables where name like '%sd_counts%') > 0
BEGIN
drop table ##sd_counts
END

if (select count(*) from tempdb.sys.tables where name like '%sd_count2%') > 0
BEGIN
drop table ##sd_count2
END

SET NOCOUNT ON
create table ##sd_Counts (
rn  INT identity(1,1) NOT NULL,
srv varchar(90) NULL,
db varchar(90),
tableNm varchar(90),
tablesch varchar(32),
rcount int)


--select distinct srv from ##sd_counts 

insert ##sd_Counts(srv,db,tableNm,tablesch)
(select distinct RTRIM(LTRIM([server])) srv,RTRIM(LTRIM([db])) db,[TableView],[schema] from process.[PII Tables Hosts]
 	where (isnull([PII],'') = 'Sensitive PII' --or [GDPR Classification] like 'Person%' or [GDPR Classification] like 'Special%'
	)
	and [server] not like '%dw%' 
	and [server] not like 'z%'
	) 

create table ##sd_Count2 (
rn  INT identity(1,1) NOT NULL,
srv varchar(90) NULL,
db varchar(90),
tableNm varchar(90),
tablesch varchar(32),
rcount int)


insert ##sd_Count2(srv,db,tableNm,tablesch)
(select distinct [Server],[db],[TableView],[schema] from process.[PII Tables Hosts] WITH (NOLOCK)
 	where (isnull([PII],'') = 'Sensitive PII' --or [GDPR Classification] like 'Person%' or [GDPR Classification] like 'Special%'
	)
	and [server] like '%dw%' and [TableView] like '%dw%' 
	and [server] not like 'z%'
	) 


update ##sd_counts set db = 'GoldStandard' where db = 'eden'

update ##sd_counts set db = 'GoldStandard' where db = 'eden main'

declare @i INT
declare @r INT
declare @currentSrv nvarchar(90)
declare @currentDb nvarchar(90)
declare @currentTb	nvarchar(90)
declare @currSch nvarchar(32)

--declare @newRc INT
declare @sqlcmd nvarchar(max)

select @i = 1
select @r = (select count(*) from ##sd_Counts)

While @i <= @r
BEGIN


select @currentSrv = (select srv from ##sd_Counts where rn = @i)
select @currentDb = (select db from ##sd_Counts where rn = @i)
select @currentTb = (select tableNm from ##sd_Counts where rn = @i)
select @currSch = (select tablesch from ##sd_Counts where rn = @i)

select @sqlcmd = 'declare @newRc INT
select @newRc = (select count (*) from ['+ @currentSrv + '].[' + @currentDb + '].'+ @currSch + '.[' + @currentTb+'] WITH (NOLOCK))
	Update  ##sd_counts
	set rcount = @newrC where srv not like ''%DW%'' and rn = '+cast(@i as nvarchar(12))

print @sqlcmd
exec sp_executesql @sqlcmd

select @i = @i + 1

IF @i > @r
BREAK
	else continue


END


select @i = 1
select @r = (select count(*) from ##sd_Count2)

While @i <= @r
BEGIN


select @currentSrv = (select srv from ##sd_Count2 where rn = @i)
select @currentDb = (select db from ##sd_Count2 where rn = @i)
select @currentTb = (select tableNm from ##sd_Count2 where rn = @i)
select @currSch = (select tablesch from ##sd_Count2 where rn = @i)

select @sqlcmd = 'declare @newRc INT
select @newRc = (select count (*) from [' + @currentDb + '].'+ @currSch + '.[' + @currentTb+'] WITH (NOLOCK))
	Update  ##sd_count2
	set rcount = @newrC where srv like ''%dw%'' and rn = '+cast(@i as nvarchar(12))

--print @sqlcmd
exec sp_executesql @sqlcmd

select @i = @i + 1

IF @i > @r
BREAK
	else continue


END


INSERT process.PII_Count_Summary
 ( 
      [rn]
      ,[srv]
      ,[db]
      ,[tableNm]
      ,[tablesch]
      ,[rcount]
)
select * 
from ##sd_counts
union
select * from ##sd_Count2
order by rcount desc 

INSERT process.PII_All_Count (allRecords)
select sum(isnull(rc,0)) allRecords 
from (
select sum(isnull(rcount,0)) rc from ##sd_counts
union
select sum(isnull(rcount,0)) from ##sd_Count2
) o

INSERT [process].[PII_Column_Info]
([db]
      ,[Column]
      ,[PII]
      ,[PII Data Domain]
      ,[GDPR Classification]
      ,[GDPR Data Domain]
)
select distinct db,[Column],PII,[PII Data Domain] ,[GDPR Classification]  , [GDPR Data Domain]
from (
select * from process.[PII Tables Hosts] where  (PII like 'Sensitive%' or [GDPR Classification] like 'Person%' or [GDPR Classification] like 'Special%'
)
) o





GO
