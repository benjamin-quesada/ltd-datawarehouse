SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [rpt].[TouchPassBillingCount_v3]
as
/*
takes tpd (touch pass data) schema tables and unpivots
to stg (stage) tables stg.TouchPassBillingAmount
and stg.TouchPassBillingCount

These tables are used in a subsequent step to format
for refular table use and access by reporting.

Requires data be downloaded in xlsx format from TouchPass
Downlaods must be named "YYYYMM Billing.xlsx" and only to
the folder "File Automation" in Finance workgroup under 
A/R.

An SSIS package run by a sql agent job loads data from
those files after converting to csv:
"Process Automation - TouchPass Monthly"

AUTHOR:  B Eichberger
CREATED: 6/19/2020
TICKET:  RID-8569 (Fare Management - Touch pass integration with Eden)

-- USE:	exec [rpt].[TouchPassBillingCount_v3]
*/

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



truncate table stg.TouchPassSalesCount


DROP TABLE IF EXISTS #rowiterator
DROP TABLE IF EXISTS #tblNames



select p.cn,
       p.TABLE_NAME,
       p.column_name, FLOOR(cn/10)*10 bucket
into #rowiterator 
FROM 	
(
select cn = row_number() over (Partition by table_name order by ordinal_position),
	table_name
	, '[' + column_name + ']' column_name
	from INFORMATION_SCHEMA.columns where TABLE_SCHEMA = 'tpb'
	and column_Name like '%count%' AND table_name NOT LIKE '%20220606113735%'
	--and column_Name not like '%count%' 
	AND table_name NOT LIKE '%202205%'
	AND table_name NOT LIKE '%202206%'
	AND table_name NOT LIKE '%202207%'
	AND table_name NOT LIKE '%202208%'
	AND table_name NOT LIKE '%202209%'
	AND table_name NOT LIKE '%202210%'
	AND table_name NOT LIKE '%202211%'
	AND table_name NOT LIKE '%202212%'
	AND table_name NOT LIKE '%202301%'
	AND table_name NOT LIKE '%202302%'
	AND table_name NOT LIKE '%202303%') p 

--select * from #rowiterator

create table #tblNames (tn INT identity(1,1),tblName varchar(120)) 
insert #tblNames (tblName)
select distinct table_name from #rowiterator

--select * from #tblNames

declare @i INT = 1
declare @r INT = (select max(tn) from #tblNames ) 
declare @selectstmnt nvarchar(max) = ''
declare @columnstmnt nvarchar(max) = ''
declare @currentTbl varchar(120) = ''
declare @currentBkt INT

while @i <= @r
BEGIN

select @currentTbl = (select tblName from #tblNames where tn = @i)

DROP TABLE IF EXISTS #buckets

create table #buckets (bn INT identity(1,1),tblName varchar(120), bucketNbr INT) 
insert #buckets (tblName,bucketNbr)
select distinct table_name, bucket
from #rowiterator where TABLE_NAME = @currentTbl

--select * from #buckets

declare @g INT = 1
declare @gr INT = (select max(bn) from #buckets where tblName = @currentTbl)


While @g <= @gr
BEGIN

select @selectstmnt = ''
select @columnstmnt = ''
select @currentBkt = (select distinct bucketNbr from #buckets where bn = @g and tblName = @currentTbl)

select @columnstmnt = @columnstmnt + (
 select stuff(
  (select ','+column_name from 
      (select replace(column_name,'"','') column_name from #rowiterator r
				where TABLE_NAME = @currentTbl 
				and r.bucket =  @currentBkt
				and column_name not like '%total%' 
				and column_name not like '%reseller%'
				and column_name not like '%user%'
				) t 
   FOR XML PATH('')
  ),1,1,'') b
  )

select @selectstmnt = @selectstmnt + ' 
INSERT stg.TouchPassSalesCount
SELECT ''' + replace(@currentTbl,' Billing','') +''' as YYYYMM,
	 Reseller
	,Product
	,AmtCount
 from (SELECT replace([Reseller],''"'','''')+''^''+replace([User],''"'','''') Reseller, '
select @selectstmnt = @selectstmnt + (
 select stuff(
  (select ',cast(isnull(replace('+column_name + ',''"'',''''),0) as Money) ' + replace(column_name,'"','') from 
      (select column_name from #rowiterator r
				where TABLE_NAME = @currentTbl 
				and r.bucket =  @currentBkt
				and column_name not like '%total%' 
				and column_name not like '%reseller%'
				and column_name not like '%user%'
				and column_name like '%count%'
				) t 
   FOR XML PATH('')
  ),1,1,'') b
  );

select @selectstmnt = @selectstmnt + ' from [tpb].['+ @currentTbl + ']
) p
UNPIVOT(AmtCount FOR Product IN (' + 
@columnstmnt
+')) AS unpvt
WHERE AmtCount <> 0
and len([Reseller]) >1'

--select @selectstmnt
--PRINT @selectstmnt
exec sp_executesql @selectstmnt

-- go to the next group in the table
select @g = @g + 1

if @g > @gr
 BREAK
ELSE CONTINUE

END

-- go to the next table
select @i = @i + 1

if @i > @r
 BREAK
ELSE CONTINUE

END

--select * from stg.TouchPassSalesCount


GO
