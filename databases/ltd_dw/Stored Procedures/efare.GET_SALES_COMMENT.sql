SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE   PROCEDURE [efare].[GET_SALES_COMMENT]

as


/*
AUTHOR   : BEichberger
DATE     : 09-18-2019
PURPOSE  : Data Extract from API sources and stage_SALE

-- exec [efare].[GET_SALES_COMMENT]

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
insert #filelist (fileloading) select fileloading from [efare].[stage_SALE] group by fileloading

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
create table ##OutputTbl0042(
	[txId] [varchar](50) NULL,
	[fileloaded] [nvarchar](255) NULL
)



INSERT INTO -- truncate table 
[efare].[SALE_COMMENT]
( [txId]
      ,[respstat]
      ,[retref]
      ,[account]
      ,[token]
      ,[profileid]
      ,[amount]
      ,[merchid]
      ,[respcode]
      ,[resptext]
      ,[respproc]
      ,[batchid]
      ,[avsresp]
      ,[cvvresp]
      ,[authcode]
      ,[commcard]
	  ,fileloaded)
OUTPUT inserted.txId,inserted.fileloaded into ##OutputTbl0042
SELECT 
  txId,
  JSON_VALUE(comment, ''$.respstat'') AS respstat,
  JSON_VALUE(comment, ''$.retref'') AS retref,
 JSON_VALUE(comment, ''$.account'') AS account,
 JSON_VALUE(comment, ''$.token'') AS token,
 JSON_VALUE(comment, ''$.profileid'') AS profileid,
 JSON_VALUE(comment, ''$.amount'') AS amount,
 JSON_VALUE(comment, ''$.merchid'') AS merchid,
 JSON_VALUE(comment, ''$.respcode'') AS respcode,
 JSON_VALUE(comment, ''$.resptext'') AS resptext,
 JSON_VALUE(comment, ''$.respproc'') AS respproc,
 JSON_VALUE(comment, ''$.batchid'') AS batchid,
 JSON_VALUE(comment, ''$.avsresp'') AS avsresp,
 JSON_VALUE(comment, ''$.cvvresp'') AS cvvresp,
 JSON_VALUE(comment, ''$.authcode'') AS authcode,
 JSON_VALUE(comment, ''$.commcard'') AS commcard,
 fileloading
FROM [ltd_dw].[efare].[stage_SALE] s
where isjson(comment) = 1
and fileloading = '''+ @currentfile + ''' and not exists (select TxId from [efare].[SALE_COMMENT] where TxId = s.TxId)
group by 
txId,
  JSON_VALUE(comment, ''$.respstat'') ,
  JSON_VALUE(comment, ''$.retref'') ,
 JSON_VALUE(comment, ''$.account'') ,
 JSON_VALUE(comment, ''$.token'') ,
 JSON_VALUE(comment, ''$.profileid'') ,
 JSON_VALUE(comment, ''$.amount'') ,
 JSON_VALUE(comment, ''$.merchid'') ,
 JSON_VALUE(comment, ''$.respcode'') ,
 JSON_VALUE(comment, ''$.resptext'') ,
 JSON_VALUE(comment, ''$.respproc'') ,
 JSON_VALUE(comment, ''$.batchid'') ,
 JSON_VALUE(comment, ''$.avsresp'') ,
 JSON_VALUE(comment, ''$.cvvresp'') ,
 JSON_VALUE(comment, ''$.authcode'') ,
 JSON_VALUE(comment, ''$.commcard''),
 fileloading

insert [process].[Fileload] (
	  [FileSourceName]
      ,[FileSourceGroup]
      ,[FileRowCount])
 select fileloaded,''eFARE'',count(*) from ##OutputTbl0042 group by fileloaded

 drop table ##OutputTbl0042'

 
 
 --print @sqlcmd
 exec sp_executesql @sqlcmd

 select @i = @i + 1

 if @i > @r BREAK
 else 
 continue

 END
GO
