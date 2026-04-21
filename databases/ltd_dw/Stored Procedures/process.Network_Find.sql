SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   PROCEDURE [process].[Network_Find]
@searchString nvarchar(50), -- abra
@searchMapDriveLetter varchar(1), -- Z
@searchUNC varchar(255) -- \\ad.ltd.org\dfs
as
-- exec process.Network_Find 'hta', 'Q', '\\ltd-cifsna1\'

--=================
----TEST
--declare
--@searchString nvarchar(50) = 'hta',
--@searchMapDriveLetter varchar(1) = 'Q',
--@searchUNC varchar(255) = '\\ltd-cifsna1\'
--=================

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


declare @netuse varchar(255) = 'net use '+@searchMapDriveLetter+': /DELETE > nul 2>&1' --
exec xp_cmdshell @netuse
print @netuse
waitfor delay '00:00:02'
select @netuse = 'net use '+@searchMapDriveLetter+': '+ @searchUNC + ' /p:no > nul 2>&1' --
exec xp_cmdshell @netuse
print @netuse
        
drop table if exists wrk.ltd_network_search_list
create table wrk.ltd_network_search_list ([output] nvarchar(max) null)

declare  @cmd1        varchar(255)
select @cmd1 = 'dir '+@searchMapDriveLetter+':\*. /s /b'
print @cmd1
insert wrk.ltd_network_search_list (output) exec master..xp_cmdshell @cmd1

delete from wrk.ltd_network_search_list where output is null

-- select * from wrk.ltd_network_search_list 


drop table if exists wrk.ltd_NetworkFolderList 
create table wrk.ltd_NetworkFolderList (id int identity(1,1), [output] nvarchar(max) null)

INSERT wrk.ltd_NetworkFolderList ([output])
select distinct [output] 
from wrk.ltd_network_search_list l where 1=1
--and output like '%.hta%' --or output like '%report%'
and output not like '%CCTV%'
and output not like '%ABRA%'
and output not like '%SQLBackups%'
and output not like '%Support%'
	AND NOT EXISTS (select output from wrk.ltd_NetworkFolderList
				where output = l.output)



declare @i INT = 1
declare @cmd2        varchar(255)
declare @cmd3        varchar(255)
declare @r INT = (select max(id) from wrk.ltd_NetworkFolderList)
declare @currDir varchar(max)

drop table if exists process.NetworkSearchResults
create table process.NetworkSearchResults (output nvarchar(max) null)


While @i <= @r
BEGIN
select @currDir = (select [output] from wrk.ltd_NetworkFolderList where id = @i
)
--=================
----TEST
--declare @searchString nvarchar(50) = 'hta'
--=================

--select @cmd3 = 'findstr /I /M "'+@searchString+'" "'+ @currDir +'"\*.bat'
--insert process.NetworkSearchResults (output) exec master..xp_cmdshell @cmd3

--select @cmd3 = 'findstr /I /M "'+@searchString+'" "'+ @currDir +'"\*.dtsx'
--insert wrk.ltd_NetworkSearchResults (output) exec master..xp_cmdshell @cmd3

--select @cmd3 = 'findstr /I /M "'+@searchString+'" "'+ @currDir +'"\*.dts'
--insert wrk.ltd_NetworkSearchResults (output) exec master..xp_cmdshell @cmd3

--select @cmd3 = 'findstr /I /M "'+@searchString+'" "'+ @currDir +'"\*.rpt'
--insert wrk.ltd_NetworkSearchResults (output) exec master..xp_cmdshell @cmd3

--select @cmd3 = 'findstr /I /M "'+@searchString+'" "'+ @currDir +'\*.hta'
--insert process.NetworkSearchResults (output) exec master..xp_cmdshell @cmd3

select @cmd3 = 'findstr /I /M "'+ @currDir +'\*.hta"'
--print @cmd3
insert process.NetworkSearchResults (output) exec master..xp_cmdshell @cmd3


select @i = @i + 1

if @i > @r
BREAK
	else continue

	END


drop table if exists process.ltd_NetworkSearchStringResults 
create table process.ltd_NetworkSearchStringResults  (id int identity(1,1), [output] nvarchar(max) null, extension varchar(8), SearchCode varchar(22))

INSERT process.ltd_NetworkSearchStringResults (output,extension,searchCode)
select o.output
     , o.extension
	 , o.searchCode
     from (
select distinct output,substring(output,charindex('.',[output],1)+1,4) extension, @searchString as searchCode
from process.NetworkSearchResults
 where 1=1
 and output not like 'FINDSTR%'
   and output is not null)
   o
   --where extension in ('hta')
   -- ,'xlsx','dts','dtsx','bat'

/* ----------------- SELECT SAMPLE
select * from 
	(select output,substring(output,charindex('.',[output],1)+1,4) extension
	--, searchCode 
	from wrk.ltd_NetworkSearchResults with (nolock)
	--process.ltd_NetworkSearchList
	 where output not like 'FINDSTR%'
	   and output not like '%Old\%'
	   and output is not null ) o
where extension in ('bat','rpt','dtsx','dts','xlsx')
group by output, extension
order by output desc

 ----------------- SELECT SAMPLE */
GO
