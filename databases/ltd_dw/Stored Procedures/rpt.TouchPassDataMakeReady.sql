SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [rpt].[TouchPassDataMakeReady]
as
set NOCOUNT on

/*
run the sprocs to output data from csv staged data
then execute the insert statement for touchpasssales

AUTHOR:  B. EICHBERGER
CREATED: 20200619
TICKET:  RID 8569 - Fare Management - Touch pass integration with Eden 
TICKET:  RID 10100 - Add Try Catch
TICKET:  RID 14669 - Pass Sales/Non-Profit Data Discrepancy (duplicates when there are more than one finance account for same vendor)

exec [rpt].[TouchPassDataMakeReady]

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
       
  
declare @startRcnt INT = (select count(*) from rpt.[TouchPassSales])

exec rpt.TouchPassBillingAmount
exec rpt.TouchPassBillingCount

--TRUNCATE TABLE rpt.TouchPassResellerErrors
--INSERT rpt.TouchPassResellerErrors
--select YYYYMM, reseller 
--from stg.TouchPassSalesCount where reseller like 'NP%' and Reseller Not like '%|%'
--UNION
--select YYYYMM, reseller from stg.TouchPassSalesAmount
--	where reseller like 'NP%' and Reseller Not like '%|%'
--UNION
--select YYYYMM, reseller from rpt.TouchPassSales
--	where reseller like 'NP%' and Reseller Not like '%|%'

DELETE from rpt.TouchPassSales where Reseller like 'NP%' and Reseller not like '%|%'
DELETE from stg.TouchPassSalesAmount where Reseller like 'NP%' and Reseller not like '%|%'
DELETE from stg.TouchPassSalesCount where Reseller like 'NP%' and Reseller not like '%|%'

INSERT [rpt].[TouchPassSales] (YYYYMM, Reseller, Product, AmtSales, CountSales)
select YYYYMM, Reseller, Product, AmtSales, SalesCount from (
SELECT 
COALESCE(a.[YYYYMM], c.[YYYYMM]) YYYYMM
,CASE 
  WHEN ISNULL(a.[Reseller],'') LIKE '%^%' AND ISNULL(c.[Reseller],'') = ''
	THEN LEFT(a.[Reseller],CHARINDEX('^',a.[Reseller],1)-1) 
  WHEN ISNULL(c.[Reseller],'') LIKE '%^%' AND ISNULL(a.[Reseller],'') = ''
	THEN LEFT(c.[Reseller],CHARINDEX('^',c.[Reseller],1)-1) 
	ELSE COALESCE(LEFT(a.[Reseller],CHARINDEX('^',a.[Reseller],1)-1) ,LEFT(a.[Reseller],CHARINDEX('^',c.[Reseller],1)-1) ) END AS Reseller 
      ,coalesce(a.[Product], c.Product) Product
      ,sum(isnull([AmtSales],0)) [AmtSales]
	  ,sum(isnull(c.SalesCount,0)) SalesCount -- select * 
  FROM [ltd_dw].[stg].[TouchPassSalesAmount] a
  full join (select * from 
  [ltd_dw].[stg].[TouchPassSalesCount] ) c on c.YYYYMM = a.YYYYMM
		and replace(c.Reseller,' ','') = replace(a.Reseller,' ','')
		and replace(replace(c.Product,' Count',''),'  Count','') = a.Product
group by 
		coalesce(a.[YYYYMM], c.[YYYYMM]) 
      ,CASE 
  WHEN ISNULL(a.[Reseller],'') LIKE '%^%' AND ISNULL(c.[Reseller],'') = ''
	THEN LEFT(a.[Reseller],CHARINDEX('^',a.[Reseller],1)-1) 
  WHEN ISNULL(c.[Reseller],'') LIKE '%^%' AND ISNULL(a.[Reseller],'') = ''
	THEN LEFT(c.[Reseller],CHARINDEX('^',c.[Reseller],1)-1) 
	ELSE COALESCE(LEFT(a.[Reseller],CHARINDEX('^',a.[Reseller],1)-1) ,LEFT(a.[Reseller],CHARINDEX('^',c.[Reseller],1)-1) ) END
      ,coalesce(a.[Product], c.Product) 
      ) q
where not exists
	  (select yyyymm, Reseller, Product FROM [rpt].[TouchPassSales] 
		where yyyymm = q.yyyymm and reseller = q.Reseller and product = q.Product)

UPDATE t
set t.amtsales = u.amtsales
,	t.CountSales = u.salescount
,	t.UpdatedDate = sysdatetime()
from rpt.TouchPassSales t
INNER JOIN (SELECT coalesce(a.[YYYYMM], c.[YYYYMM]) YYYYMM
,CASE 
  WHEN ISNULL(a.[Reseller],'') LIKE '%^%' AND ISNULL(c.[Reseller],'') = ''
	THEN LEFT(a.[Reseller],CHARINDEX('^',a.[Reseller],1)-1) 
  WHEN ISNULL(c.[Reseller],'') LIKE '%^%' AND ISNULL(a.[Reseller],'') = ''
	THEN LEFT(c.[Reseller],CHARINDEX('^',c.[Reseller],1)-1) 
	ELSE COALESCE(LEFT(a.[Reseller],CHARINDEX('^',a.[Reseller],1)-1) ,LEFT(a.[Reseller],CHARINDEX('^',c.[Reseller],1)-1) ) END AS Reseller
				  ,coalesce(a.[Product], c.Product) Product
				  ,sum(isnull([AmtSales],0)) [AmtSales]
				  ,sum(isnull(c.SalesCount,0)) SalesCount
			  FROM [ltd_dw].[stg].[TouchPassSalesAmount] a
			  full join (select * from 
			  [ltd_dw].[stg].[TouchPassSalesCount] ) c on c.YYYYMM = a.YYYYMM
					and replace(c.Reseller,' ','') = replace(a.Reseller,' ','')
					and replace(replace(c.Product,' Count',''),'  Count','') = a.Product
			group by 
					coalesce(a.[YYYYMM], c.[YYYYMM]) 
			,CASE 
				WHEN ISNULL(a.[Reseller],'') LIKE '%^%' AND ISNULL(c.[Reseller],'') = ''
				THEN LEFT(a.[Reseller],CHARINDEX('^',a.[Reseller],1)-1) 
				WHEN ISNULL(c.[Reseller],'') LIKE '%^%' AND ISNULL(a.[Reseller],'') = ''
				THEN LEFT(c.[Reseller],CHARINDEX('^',c.[Reseller],1)-1) 
				ELSE COALESCE(LEFT(a.[Reseller],CHARINDEX('^',a.[Reseller],1)-1) ,LEFT(a.[Reseller],CHARINDEX('^',c.[Reseller],1)-1) ) END
			,coalesce(a.[Product], c.Product) ) u
		on t.yyyymm = u.yyyymm and t.reseller = u.Reseller and t.product = u.Product
where t.AmtSales <> u.AmtSales
or t.CountSales <> u.SalesCount


--create table #deltables (rnbr int identity(1,1),table_schema varchar(32), table_name varchar(32))
--insert #deltables (table_schema, table_name)
--select s.name table_schema, t.name table_name from sys.tables t
--join sys.schemas s on s.schema_id = t.schema_id
--where s.name = 'tpb'

--declare @dropstmnt nvarchar(max)
--declare @currentTbl nvarchar(32)
--declare @currentSch nvarchar(32)
--declare @i INT
--declare @r INT

--select @r = (select max(rnbr) from #deltables)
--select @i = 1

--WHILE @i <= @r
--BEGIN

--select @currentTbl = (select table_name from #deltables where rnbr = @i)
--select @currentSch = (select table_schema from #deltables where rnbr = @i)
--select @dropstmnt = '
--if (select count(*) from sys.tables where name = '''+ @currentTbl + ''') > 0
--BEGIN
--DROP Table ' + @currentSch + '.[' + @currentTbl+ ']
--END'
--exec sp_executesql @dropstmnt

--select @i = @i + 1
--if @i > @r
--  BREAK
--Else CONTINUE

--END

DECLARE @profile VARCHAR(255) = 'SQLData'
declare @endRcnt INT = (select count(*) FROM rpt.[TouchPassSales] )


IF @endRcnt > @startRcnt
BEGIN

declare @lastYYYYMM INT = (select max(YYYYMM) from rpt.[TouchPassSales])
DECLARE @bodtxt varchar(max) = 'New TouchPass files have been processed. You may now generate Eden Import files through: ' + cast(@lastYYYYMM as varchar(12))+'.'
       EXEC msdb.dbo.sp_send_dbmail @profile_name = @profile
             ,@recipients = 'nooshi.ghasedi@ltd.org;ar@ltd.org;' --'barb.eichberger@ltd.org' --
			 ,@copy_recipients = 'barb.eichberger@ltd.org;'
             ,@subject = 'TouchPass Monthly Data Ready'
             ,@body = @bodtxt;

END


END TRY	  

BEGIN CATCH

       
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
             ,@recipients = 'servicedesk@ltd.org'
             ,@subject = @sub
             ,@body = @errormsg;

       RAISERROR (
                    @errormsg
                    ,@errsev
                    ,1
                    )
END CATCH
GO
