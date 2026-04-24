SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[Network_Find]
@searchString nvarchar(50), -- abra
@searchMapDriveLetter varchar(1), -- Z
@searchUNC varchar(255) -- \\ad.ltd.org\dfs
as
-- exec  dbo.Network_Find 'timeless%taskid%abra%earning%', 'Z', '\\ad.ltd.org\dfs'
set nocount on

--=================
--TEST
--declare
--@searchString nvarchar(50) = 'abra',
--@searchMapDriveLetter varchar(1) = 'Z',
--@searchUNC varchar(255) = '\\ad.ltd.org\dfs'
--=================



declare @netuse varchar(255) = 'net use '+@searchMapDriveLetter+': /DELETE > nul 2>&1' --
exec xp_cmdshell @netuse
--print @netuse
waitfor delay '00:00:04'
select @netuse = 'net use '+@searchMapDriveLetter+': '+ @searchUNC + ' /p:no > nul 2>&1' --
exec xp_cmdshell @netuse
--print @netuse


declare  @cmd1        varchar(255)
--@filepath   varchar(255),
         

if (select count(*) from sys.tables where name = 'outputlist') > 0
BEGIN
drop table wrk.outputlist
END

if (select count(*) from sys.tables where name = 'outputlist') = 0
BEGIN
create table wrk.outputlist ([output] nvarchar(max) null)
END

select @cmd1 = 'dir '+@searchMapDriveLetter+':\*. /s /b'
insert wrk.outputlist (output) exec master..xp_cmdshell @cmd1


delete from wrk.outputlist where output like '%profile%'
delete from wrk.outputlist where output like '%archive%'
delete from wrk.outputlist where output like '%CCTV%'
delete from wrk.outputlist where output like '%windows%'
delete from wrk.outputlist where output like '%decommissioned%'
delete from wrk.outputlist where output like '%IO_Controls%'
delete from wrk.outputlist where output like '%hasdev%'
delete from wrk.outputlist where output like '%backup%'
delete from wrk.outputlist where output like '%hastest%'
delete from wrk.outputlist where output like '%!%'
delete from wrk.outputlist where output like '%training%'
delete from wrk.outputlist where output like '%mvideo%'
delete from wrk.outputlist where output like '%pictometry%'
delete from wrk.outputlist where output like '%Map%'
delete from wrk.outputlist where output like '%hanover%'
delete from wrk.outputlist where output like '%runtime%'
delete from wrk.outputlist where output like '%signs%'
delete from wrk.outputlist where output like '%sounds%'
delete from wrk.outputlist where output like '%celeron%'
delete from wrk.outputlist where output like '%schematics%'
delete from wrk.outputlist where output like '%IRIS-IRMA%'
delete from wrk.outputlist where output like '%Microsoft%'

select count(*) from wrk.outputlist

--if (select count(*) from sys.tables where name = 'NetworkFolderList') > 0
--BEGIN
--drop table dbo.NetworkFolderList 
--END

--if (select count(*) from sys.tables where name = 'NetworkFolderList') = 0
--BEGIN
--create table dbo.NetworkFolderList  (id int identity(1,1), [output] nvarchar(max) null)
--END

--INSERT dbo.NetworkFolderList ([output])
--select distinct [output] 
--from wrk.outputlist where [output] is not null 



----if (select count(*) from sys.tables where name = 'outputlist') > 0
----BEGIN
----drop table wrk.outputlist
----END



--declare @i INT = 1
--declare @cmd2        varchar(255)
--declare @cmd3        varchar(255)
--declare @r INT = (select max(id) from [dbo].[NetworkFolderList])
--declare @currDir varchar(max)


--if (select count(*) from sys.tables where name = 'NetworkSearchOutput') > 0
--BEGIN
--drop table wrk.NetworkSearchOutput
--END

--if (select count(*) from sys.tables where name = 'NetworkSearchOutput') = 0
--BEGIN
--create table wrk.NetworkSearchOutput (output nvarchar(max) null)
--END


--While @i <= @r
--BEGIN
--select @currDir = (select [output] from [dbo].[NetworkFolderList] where id = @i
--)

--select @cmd3 = 'findstr /I /M "'+@searchString+'" "'+ @currDir +'"\*.bat'
--insert wrk.NetworkSearchOutput (output) exec master..xp_cmdshell @cmd3

--select @cmd3 = 'findstr /I /M "'+@searchString+'" "'+ @currDir +'"\*.dtsx'
--insert wrk.NetworkSearchOutput (output) exec master..xp_cmdshell @cmd3

--select @cmd3 = 'findstr /I /M "'+@searchString+'" "'+ @currDir +'"\*.dts'
--insert wrk.NetworkSearchOutput (output) exec master..xp_cmdshell @cmd3

--select @cmd3 = 'findstr /I /M "'+@searchString+'" "'+ @currDir +'"\*.rpt'
--insert wrk.NetworkSearchOutput (output) exec master..xp_cmdshell @cmd3

--select @cmd3 = 'findstr /I /M "'+@searchString+'" "'+ @currDir +'"\*.xlsx'
--insert wrk.NetworkSearchOutput (output) exec master..xp_cmdshell @cmd3

--select @i = @i + 1

--if @i > @r
--BREAK
--	else continue

--	END


----if (select count(*) from sys.tables where name = 'NetworkSearchList') > 0
----BEGIN
----drop table dbo.NetworkSearchList 
----END

----if (select count(*) from sys.tables where name = 'NetworkSearchList') = 0
----BEGIN
----create table dbo.NetworkSearchList  (id int identity(1,1), [output] nvarchar(max) null, extension varchar(8))
----END

--INSERT dbo.NetworkSearchList (output,extension,searchCode)
--select * from (
--select distinct output,substring(output,charindex('.',[output],1)+1,4) extension, 'ltd_time_tracking' as searchCode
--from wrk.NetworkSearchOutput
-- where output not like 'FINDSTR%'
--   and output is not null)
--   o
--   where extension in ('rpt','xlsx','dts','dtsx','bat')

--/* ----------------- SELECT SAMPLE
--select * from 
--	(select output,substring(output,charindex('.',[output],1)+1,4) extension
--	--, searchCode 
--	from wrk.NetworkSearchOutput with (nolock)
--	--dbo.NetworkSearchList
--	 where output not like 'FINDSTR%'
--	   and output not like '%Old\%'
--	   and output is not null ) o
--where extension in ('bat','rpt','dtsx','dts','xlsx')
--group by output, extension
--order by output desc

-- ----------------- SELECT SAMPLE */
GO
