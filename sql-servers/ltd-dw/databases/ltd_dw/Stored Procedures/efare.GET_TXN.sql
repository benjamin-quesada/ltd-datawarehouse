SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE   PROCEDURE [efare].[GET_TXN]

AS



/*
AUTHOR   : BEichberger
DATE     : 09-18-2019
PURPOSE  : Data Extract from API sources and stage_TXN

-- exec [efare].[GET_TXN]

------------------LTD_GLOSSARY---------------
UPDATED BY:	Sopheap Suy
UPDATED DT: 10/31/2024
purpose	 :  Add object activities on who, what, when call this object
			write this data to aud.object_activity table everytime it's called 

UPDATED BY:	Sopheap Suy
UPDATED DT: 12/09/2024
purpose	  : change where exists key to name instead of name, description, faretx
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


create table #filelist (rnbr INT identity(1,1), fileloading nvarchar(255))
insert #filelist (fileloading) select fileloading from [efare].[stage_TXN] group by fileloading

declare @i INT
declare @r INT
declare @sqlcmd nvarchar(max)
declare @currentfile nvarchar(255)

select @r = (select max(rnbr) from #filelist)
select @i = 1

WHILE @i <= @r
BEGIN


select @currentfile = (select fileloading from #filelist where rnbr = @i)


select @sqlcmd = ''
SELECT @sqlcmd = @sqlcmd + '
create table ##OutputTbl0942(
	[Name] [varchar](50) NULL,
	[fileloaded] [nvarchar](255) NULL
)

INSERT INTO -- truncate table 
[efare].[TXN]
( [Name]
      ,[Description]
      ,[FareTx]
      ,[fileloaded])
OUTPUT inserted.[Name],inserted.fileloaded into ##OutputTbl0942
SELECT 
 [Name]
      ,[Description]
      ,[FareTx]
	  ,fileloading
FROM [ltd_dw].[efare].[stage_TXN] s
where fileloading = '''+ @currentfile + ''' and not exists (select [Name] from [efare].[TXN]
						 where [Name] = s.[Name]
						   )
group by 
[Name]
      ,[Description]
      ,[FareTx]
	  ,fileloading

insert [process].[Fileload] (
	  [FileSourceName]
      ,[FileSourceGroup]
      ,[FileRowCount])
 select fileloaded,''eFARE'',count(*) from ##OutputTbl0942 group by fileloaded

 drop table ##OutputTbl0942'

 
 --print @sqlcmd
 EXEC sp_executesql @sqlcmd

 SELECT @i = @i + 1

 IF @i > @r BREAK
 ELSE 
 CONTINUE

 END
GO
