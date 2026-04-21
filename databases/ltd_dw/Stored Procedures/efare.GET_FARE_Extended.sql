SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE procedure [efare].[GET_FARE_Extended]

as

SET NOCOUNT ON

/*
AUTHOR   : BEichberger
DATE     : 05-01-2023
PURPOSE  : Data Extract from API sources and stage_FARE (with new extended data available)

-- exec [efare].[GET_FARE_Extended]

------------------LTD_GLOSSARY---------------
UPDATED BY:	Sopheap Suy
UPDATED DT:  10/31/2024
purpose	 :  Add object activities on who, what, when call this object
			write this data to aud.object_activity table everytime it's called 

UPDATED BY:	B Eichberger
UPDATED DT: 1/5/2026
purpose	 :  add model_partition to the table level to aid model load 

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

CREATE TABLE #filelist (rnbr INT IDENTITY(1,1), fileloading NVARCHAR(255))
INSERT #filelist (fileloading) SELECT fileloading FROM [efare].[stage_FARE_Extended] GROUP BY fileloading

DECLARE @i INT
DECLARE @r INT
DECLARE @sqlcmd NVARCHAR(MAX)
DECLARE @currentfile NVARCHAR(255)

SELECT @r = (SELECT MAX(rnbr) FROM #filelist)
SELECT @i = 1

WHILE @i <= @r
BEGIN


SELECT @currentfile = (SELECT fileloading FROM #filelist WHERE rnbr = @i)



-- update the card xref
insert efare.card_account_xref(cardNumber,accountId)
select distinct
cardNumber,accountId from [ltd_dw].[efare].[stage_FARE_Extended] f 
where f.cardNumber is not null and f.accountId is not null 
and not exists
	(select 1 from efare.card_account_xref d
	where d.cardNumber = f.cardNumber and d.accountId = f.accountId) 


select @sqlcmd = ''
select @sqlcmd = @sqlcmd + '
create table ##OutputTbl0242(
	[txId] [varchar](50) NULL,
	[fileloaded] [nvarchar](255) NULL
)

INSERT INTO -- truncate table 
[efare].[FARE_Extended]
( [txID]
      ,[ts]
      ,[type]
      ,[mediaUsed]
      ,[mediaType]
      ,[cardNumber]
      ,[fareType]
      ,[accountId]
	  ,cardAccount_Key
      ,[stopName]
      ,[stopId]
      ,[routeName]
      ,[latitude]
      ,[longitude]
      ,[reader]
	  ,vehicle
      ,[passUsed]
      ,[productAbbreviation]
      ,[trip]
      ,[readerPosition]
      ,[fare]
      ,[routeTypeId]
      ,[routeTypeName]
      ,[fileloaded]
	  ,[postedTs]
	  ,[passFirstUsed]
	  ,[lastModifiedTs]
	  ,[stopGtfsId]
	  ,[stopGtfsCode]
      ,model_partition)
OUTPUT inserted.txId,inserted.fileloaded into ##OutputTbl0242
SELECT 
 [txID]
      ,[ts]
      ,[type]
      ,[mediaUsed]
      ,[mediaType]
      ,s.[cardNumber]
      ,[fareType]
      ,s.[accountId]
	  ,c.cardAccount_Key
      ,[stopName]
      ,[stopId]
      ,[routeName]
      ,[latitude]
      ,[longitude]
      ,[reader]
	  ,vehicle
      ,[passUsed]
      ,[productAbbreviation]
      ,[trip]
      ,[readerPosition]
      ,cast([fare] as float)*.01 as [fare]
      ,[routeTypeId]
      ,[routeTypeName]
      ,[fileloading]
	  ,[postedTs]
	  ,[passFirstUsed]
	  ,[lastModifiedTs]
	  ,[stopGtfsId]
	  ,[stopGtfsCode]
      ,year(convert(date,ts)) as model_partition
FROM [ltd_dw].[efare].[stage_FARE_Extended] s
left join ltd_dw.efare.card_account_xref c on c.accountId = s.accountId and c.cardNumber = s.cardNumber
where fileloading = '''+ @currentfile + ''' 
	and not exists (select 1 from [efare].[FARE_Extended] 
	where TxId = s.TxId and accountId = isnull(s.accountId,''0'') and cardNumber = isnull(s.CardNumber,''0''))
group by 
[txID],[ts]
      ,[type]
      ,[mediaUsed]
      ,[mediaType]
      ,s.[cardNumber]
      ,[fareType]
      ,s.[accountId]
	  ,c.cardAccount_Key
      ,[stopName]
      ,[stopId]
      ,[routeName]
      ,[latitude]
      ,[longitude]
      ,[reader]
	  ,vehicle
      ,[passUsed]
      ,[productAbbreviation]
      ,[trip]
      ,[readerPosition]
      ,cast([fare] as float)*.01 
      ,[routeTypeId]
      ,[routeTypeName]
      ,[fileloading]
	  ,[postedTs]
	  ,[passFirstUsed]
	  ,[lastModifiedTs]
	  ,[stopGtfsId]
	  ,[stopGtfsCode]

insert [process].[Fileload] (
	  [FileSourceName]
      ,[FileSourceGroup]
      ,[FileRowCount])
 select fileloaded,''eFARE'',count(*) from ##OutputTbl0242 group by fileloaded

 drop table ##OutputTbl0242'

 
 --print @sqlcmd
 EXEC sp_executesql @sqlcmd

 SELECT @i = @i + 1

 IF @i > @r BREAK
 ELSE 
 CONTINUE

 END
GO
