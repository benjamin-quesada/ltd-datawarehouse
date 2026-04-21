SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE   PROCEDURE [efare].[GET_FARE]

as

SET NOCOUNT ON

/*
AUTHOR   : BEichberger
DATE     : 09-18-2019
PURPOSE  : Data Extract from API sources and stage_FARE

-- exec [efare].[GET_FARE]

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



create table #filelist (rnbr INT identity(1,1), fileloading nvarchar(255))
insert #filelist (fileloading) select fileloading from [efare].[stage_FARE] group by fileloading

declare @i INT
declare @r INT
declare @sqlcmd nvarchar(max)
declare @currentfile nvarchar(255)

select @r = (select max(rnbr) from #filelist)
select @i = 1

While @i <= @r
BEGIN


select @currentfile = (select fileloading from #filelist where rnbr = @i)


select @sqlcmd = ''
select @sqlcmd = @sqlcmd + '
create table ##OutputTbl0242(
	[txId] [varchar](50) NULL,
	[fileloaded] [nvarchar](255) NULL
)

INSERT INTO -- truncate table 
[efare].[FARE]
( [txID]
      ,[ts]
      ,[type]
      ,[mediaUsed]
      ,[mediaType]
      ,[cardNumber]
      ,[fareType]
      ,[accountId]
      ,[routeName]
      ,[routeNumber]
      ,[latitude]
      ,[longitude]
      ,[reader]
      ,[passUsed]
      ,[readerPosition]
      ,[fare]
      ,[fileloaded])
OUTPUT inserted.txId,inserted.fileloaded into ##OutputTbl0242
SELECT 
 [txID]
      ,[ts]
      ,[type]
      ,[mediaUsed]
      ,[mediaType]
      ,[cardNumber]
      ,[fareType]
      ,[accountId]
      ,[routeName]
      ,[routeNumber]
      ,[latitude]
      ,[longitude]
      ,[reader]
      ,[passUsed]
      ,[readerPosition]
      ,cast([fare] as float)*.01 as [fare]
      ,[fileloading]
FROM [ltd_dw].[efare].[stage_FARE] s
where fileloading = '''+ @currentfile + ''' and not exists (select TxId from [efare].[FARE] where TxId = s.TxId)
group by 
[txID]
      ,[ts]
      ,[type]
      ,[mediaUsed]
      ,[mediaType]
      ,[cardNumber]
      ,[fareType]
      ,[accountId]
      ,[routeName]
      ,[routeNumber]
      ,[latitude]
      ,[longitude]
      ,[reader]
      ,[passUsed]
      ,[readerPosition]
      ,[fare]
      ,[fileloading]

insert [process].[Fileload] (
	  [FileSourceName]
      ,[FileSourceGroup]
      ,[FileRowCount])
 select fileloaded,''eFARE'',count(*) from ##OutputTbl0242 group by fileloaded

 drop table ##OutputTbl0242'

 
 --print @sqlcmd
 exec sp_executesql @sqlcmd

 select @i = @i + 1

 if @i > @r BREAK
 else 
 continue

 END
GO
