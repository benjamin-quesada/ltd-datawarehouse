SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [efare].[z_UMODataforImport_NP_test_deprecate_20270101] 
@yyyymm varchar(32) ,
@nonprofitDiscount DECIMAL(3, 3) = .75
AS

/*
output files formatted for import to EDEN
specifically for non profit invoicing as 
this procedure features discount amount

grant execute on efare.[UMODataforImport_NP_test] to rpt_reader

AUTHOR:  B. EICHBERGER
CREATED: 20230406
TICKET:  RID 17212

example: exec efare.[UMODataforImport_NP_test] '202305',.75

*/
SET FMTONLY OFF

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

BEGIN TRY


if (len(cast(@yyyymm as varchar(12)))) <> 6
BEGIN
declare @msg varchar(255)
select @msg = '"YYYYMM" format required for LTD-DW.ltd_dw sproc '+ @SPROC  
RAISERROR (15600,-1,-1, @msg)
END

if @nonprofitDiscount >= 1
BEGIN
declare @msg2 varchar(255)
select @msg2 = 'Nonprofit Discount must be less than 1, example: ".75" for 75%" '+ @SPROC  
RAISERROR (15600,-1,-1, @msg2)
END

---------- TEST
--DECLARE @yyyymm varchar(32) = 202305
--DECLARE @nonprofitDiscount DECIMAL(3, 3) = .75
---------- TEST


if (select count(*) from tempdb.sys.tables where name like '%TPsalesDetail_NP%') <>0
BEGIN
DROP TABLE #exTPsalesDetail_NP
END

if (select count(*) from tempdb.sys.tables where name like '%TPdiscLines_NP%') <>0
BEGIN
DROP TABLE #exTPdiscLines_NP
END

if (select count(*) from tempdb.sys.tables where name like '%TPsalesDetail_NP%') =0
BEGIN
CREATE TABLE #exTPsalesDetail_NP(
	[YYYYMM] [varchar](6) NOT NULL,
	[lineCode] [varchar](4) NULL,
	[Reseller] [varchar](120) NULL,
	[cust_no] [varchar](4) NULL,
	[Product] [nvarchar](4000) NULL,
	[CountSales] [int] NULL,
	[AmtSales] [decimal](13,2) NULL,
	[Pricing] [decimal](13,2) NULL,
	[NonProfitDiscount] [decimal](4, 3) NULL,
	[OriginalLineTotal] [decimal](13,2) NULL,
	[InvoiceLineTotal] [decimal](24, 7) NULL
) ON [PRIMARY]
END

if (select count(*) from tempdb.sys.tables where name like '%TPdiscLine%') =0
BEGIN
CREATE TABLE #exTPdiscLines_NP(
	[cust_no] [varchar](4) NULL,
	[inv_no] [varchar](36) NULL,
	[Dt1] [varchar](10) NULL,
	[Service_Type] [nvarchar](46) NULL,
	[LineCategory] [varchar](6) NOT NULL,
	[Description] [varchar](25) NULL,
	[noNote] [varchar](1) NOT NULL,
	[AmtTtl] [decimal](13,2) NULL,
	[Dt2] [varchar](10) NULL,
	[Qty] [int] NOT NULL,
	[discRate] decimal(13,2) NOT NULL,
	[Rate] [decimal](13,2) NOT NULL,
	[DiscAmount] decimal(13,2) NOT NULL,
	[gcpro] [int] NOT NULL,
	[RevCode] [varchar](1) NOT NULL,
	[acctcode] [varchar](16) NOT NULL
	) ON [PRIMARY]
END

INSERT -- select * from 
#exTPsalesDetail_NP (
       [YYYYMM]
      ,[lineCode]
      ,[Reseller]
      ,[cust_no]
      ,[Product]
      ,[CountSales]
      ,[AmtSales]
      ,[Pricing]
      ,[NonProfitDiscount]
      ,[OriginalLineTotal]
      ,[InvoiceLineTotal])
SELECT YYYYMM
	,lineCode
	,Reseller = substring(Reseller, 1, CASE WHEN CHARINDEX('|', Reseller) = 0 THEN '9999' ELSE CHARINDEX('|', Reseller) END)
	,cust_no = CASE WHEN Reseller like '%|%' then RIGHT(Reseller,4) else '9999' end
	,Product = rtrim(ltrim(Replace(Replace(Product, ' Count', ''), '  Count', '') ))
	,CountSales
	,AmtSales
	,Pricing = CASE WHEN CountSales = 0 THEN 0 ELSE ROUND((AmtSales/CountSales),2) END
	,NonProfitDiscount = --0.00
	CASE WHEN reseller LIKE 'NP%' 
						 AND rtrim(ltrim(Replace(Replace(Product, ' Count', ''), '  Count', '') )) not like '%card%'
						 THEN @nonprofitDiscount
						 ELSE 0 END 
	,OriginalLineTotal = (AmtSales)
	,InvoiceLineTotal = CASE WHEN reseller LIKE 'NP%' 
			AND rtrim(ltrim(Replace(Replace(Product, ' Count', ''), '  Count', '') )) not like '%card%'
			THEN (AmtSales - (AmtSales * @nonprofitDiscount)) ELSE (AmtSales) END
FROM (
	SELECT replace(YYYYMM,'-','') YYYYMM
		,left(YYYYMM, 4) AS TxYr
		,right(YYYYMM, 2) AS TxMo
		,right(cast(left(YYYYMM, 4) AS VARCHAR(32)), 2) + right('00' + cast(right(YYYYMM, 2) AS VARCHAR(32)), 2) AS lineCode
		,SUM([AmtSales]) [AmtSales]
		,SUM([CountSales]) [CountSales]
		--,Pricing = AmtSales
		,Product
		,Reseller
		,eomonth(right(YYYYMM, 2) + '/01/' + cast(right(YYYYMM, 2) AS VARCHAR(3))) YearMonthBilled
	FROM ltd_dw.efare.TouchPassSales_Extendedv2
	WHERE reseller like 'NP%'
	--and product not like '%new card%' and Product not like '%replaced card%'
	AND ISNULL(AmtSales,0) <> 0
	AND replace(YYYYMM,'-','') = 202305 -- @yyyymm
	AND Reseller LIKE '%0106%'
	GROUP BY 
	 replace(YYYYMM,'-','')
		,left(YYYYMM, 4) 
		,right(YYYYMM, 2) 
		,right(cast(left(YYYYMM, 4) AS VARCHAR(32)), 2) + right('00' + cast(right(YYYYMM, 2) AS VARCHAR(32)), 2) 
		,Product
		,Reseller
		,eomonth(right(YYYYMM, 2) + '/01/' + cast(right(YYYYMM, 2) AS VARCHAR(3)))
	) o 

	

INSERT #exTPdiscLines_NP (
	   [cust_no]
      ,[inv_no]
      ,[Dt1]
      ,[Service_Type]
      ,[LineCategory]
      ,[Description]
      ,[noNote]
      ,[AmtTtl]
      ,[Dt2]
      ,[Qty]
      ,[discRate]
      ,[Rate]
      ,[DiscAmount]
      ,[gcpro]
      ,[RevCode]
      ,[acctcode])
	SELECT cust_no
	,inv_no = cast(YYYYMM AS VARCHAR(32)) + cust_no
	,Dt1 = right('00' + cast(YYYYMM as varchar(12)),2 ) +'/'
	     + right('00' + cast(datepart(day, EOMONTH(cast(right('00' + cast(YYYYMM as varchar(12)),2 )+'/01/'+ left(cast(YYYYMM as varchar(12)),4) as date))) as varchar(3)),2) +'/'
		 + left(cast(YYYYMM as varchar(12)),4)
	,Service_Type = FORMAT(EOMONTH(cast(YYYYMM + '01' AS DATE)),'MMM') + ' ' + cast(YEAR(EOMONTH(cast(YYYYMM + '01' AS DATE))) AS VARCHAR(12)) + ' ' + LEFT(Reseller, 2)
	--,line_no = row_number() OVER (PARTITION BY Cust_No ORDER BY AmtSales DESC)
	,LineCategory = 'tpacct'
	,[Description] = 'NP Discount '+ cast(cast((@nonprofitDiscount*100) as INT) as varchar(12)) + '%' 
	,' ' AS noNote
	,AmtTtl = cast(Round( -SUM(OriginalLineTotal*@nonprofitDiscount),2) as DECIMAL(13,2))
	,Dt2 = right('00' + cast(YYYYMM as varchar(12)),2 ) +'/'
	     + right('00' + cast(datepart(day, EOMONTH(cast(right('00' + cast(YYYYMM as varchar(12)),2 )+'/01/'+ left(cast(YYYYMM as varchar(12)),4) as date))) as varchar(3)),2) +'/'
		 + left(cast(YYYYMM as varchar(12)),4)
	,Qty = 1
	,discRate = 0
	,Rate = @nonprofitDiscount
	,DiscAmount = 0
	,gcpro = 0
	,RevCode = 'R'
	,acctcode = '010.000.00.41121'
FROM #exTPsalesDetail_NP
WHERE Product not like '%new card%' and Product not like '%replaced card%'
AND YYYYMM = @yyyymm
group by cust_no
,cast(YYYYMM AS VARCHAR(32)) + cust_no
,right('00' + cast(YYYYMM as varchar(12)),2 ) +'/'
	     + right('00' + cast(datepart(day, EOMONTH(cast(right('00' + cast(YYYYMM as varchar(12)),2 )+'/01/'+ left(cast(YYYYMM as varchar(12)),4) as date))) as varchar(3)),2) +'/'
		 + left(cast(YYYYMM as varchar(12)),4)
,FORMAT(EOMONTH(cast(YYYYMM + '01' AS DATE)),'MMM') + ' ' + cast(YEAR(EOMONTH(cast(YYYYMM + '01' AS DATE))) AS VARCHAR(12)) + ' ' + LEFT(Reseller, 2)

	
if (select count(*) from tempdb.sys.tables where name like '%importTP_EDEN_fileData_NP%') <>0 
BEGIN
DROP TABLE -- select * from 
#importTP_EDEN_fileData_NP
END

if (select count(*) from tempdb.sys.tables where name like '%importTP_EDEN_fileData_NP%') = 0 
BEGIN
CREATE TABLE #importTP_EDEN_fileData_NP(
	[cust_no] [varchar](4) NULL,
	[inv_no] [varchar](36) NULL,
	[Dt1] [varchar](10) NULL,
	[Service_Type] [nvarchar](46) NULL,
	[line_no] [bigint] NULL,
	[LineCategory] [varchar](6) NOT NULL,
	[Description] [nvarchar](4000) NULL,
	[noNote] [varchar](1) NOT NULL,
	[AmtTtl] [decimal](13,2) NULL,
	[Dt2] [varchar](10) NULL,
	[Qty] [int] NULL,
	[discRate] [decimal](13,2) NULL,
	[Rate] [decimal](13,2) NULL,
	[DiscAmount] [int] NOT NULL,
	[gcpro] [int] NOT NULL,
	[RevCode] [varchar](1) NOT NULL,
	[acctcode] [varchar](16) NOT NULL
) ON [PRIMARY]
END

INSERT #importTP_EDEN_fileData_NP  ( [cust_no]
      ,[inv_no]
      ,[Dt1]
      ,[Service_Type]
      ,[line_no]
      ,[LineCategory]
      ,[Description]
      ,[noNote]
      ,[AmtTtl]
      ,[Dt2]
      ,[Qty]
      ,[discRate]
      ,[Rate]
      ,[DiscAmount]
      ,[gcpro]
      ,[RevCode]
      ,[acctcode]
	  )
select cust_no,inv_no,Dt1,Service_Type,line_no = row_number() OVER (PARTITION BY Cust_No ORDER BY AmtTtl Desc)
,LineCategory,[Description],noNote,AmtTtl,Dt2,Qty,discRate,Rate,DiscAmount,gcpro,RevCode,acctcode
from (
	SELECT cust_no
	,cast(YYYYMM AS VARCHAR(32)) + cust_no AS inv_no
	,Dt1 = right('00' + cast(YYYYMM as varchar(12)),2 ) +'/'
	     + right('00' + cast(datepart(day, EOMONTH(cast(right('00' + cast(YYYYMM as varchar(12)),2 )+'/01/'+ left(cast(YYYYMM as varchar(12)),4) as date))) as varchar(3)),2) +'/'
		 + left(cast(YYYYMM as varchar(12)),4)
	,Service_Type = FORMAT(EOMONTH(cast(YYYYMM + '01' AS DATE)),'MMM') + ' ' + cast(YEAR(EOMONTH(cast(YYYYMM + '01' AS DATE))) AS VARCHAR(12)) + ' ' + LEFT(Reseller, 2)
	,LineCategory = case when product like '%card%' then '855' else 'tpacct' end
	,[Description] = Product
	,' ' AS noNote
	,AmtTtl = cast(OriginalLineTotal as [decimal](13,2))
	,Dt2 = right('00' + cast(YYYYMM as varchar(12)),2 ) +'/'
	     + right('00' + cast(datepart(day, EOMONTH(cast(right('00' + cast(YYYYMM as varchar(12)),2 )+'/01/'+ left(cast(YYYYMM as varchar(12)),4) as date))) as varchar(3)),2) +'/'
		 + left(cast(YYYYMM as varchar(12)),4)
	,Qty = sum(CountSales) OVER (PARTITION BY cust_no,Product ORDER BY AmtSales DESC)
	,Rate = Pricing
	,discRate = CAST(@nonprofitDiscount as DECIMAL(13,2))
	,DiscAmount = 0
	,gcpro = 0
	,RevCode = 'R'
	,acctcode = case when Product like '%card%' then '010.000.00.41024'
				else '010.000.00.41030' end
FROM #exTPsalesDetail_NP
where product not like '%new card%' and Product not like '%replaced card%'
UNION
select cust_no
     , inv_no
     , Dt1
     , Service_Type
     , LineCategory
     , Description
     , noNote
     , AmtTtl
     , Dt2
     , Qty
     , @nonprofitDiscount
     , @nonprofitDiscount
     , DiscAmount
     , gcpro
     , RevCode
     , acctcode from #exTPdiscLines_NP
) o
order by 2,1,17


--select * from #exTPdiscLines_NP where cust_no in ('0106','0163','0168')
--select * from #exTPsalesDetail_NP where cust_no in ('0106','0163','0168')
--select * from #importTP_EDEN_fileData_NP order by 1, 3, 5 --where cust_no in ('0106','0163','0168')


select [cust_no]
      +'|'+cast([inv_no] as varchar(255))
      +'|'+cast([Dt1] as varchar(255))
      +'|'+cast([Service_Type] as varchar(255))
      +'|'+cast([line_no] as varchar(255))
      +'|'+cast([LineCategory] as varchar(255))
      +'|'+cast([Description] as varchar(255))
      +'|'+cast([noNote] as varchar(255))
      +'|'+cast([AmtTtl] as varchar(255))
      +'|'+cast([Dt2] as varchar(255))
      +'|'+cast([Qty] as varchar(255))
      +'|'+CAST(CASE WHEN CAST([Rate] AS DECIMAL(13,2)) = CAST([discRate] AS [decimal](13,2)) THEN 0 ELSE [Rate] end as varchar(255))
      +'|'+CAST(CASE WHEN CAST([Rate] AS DECIMAL(13,2)) = CAST([discRate] AS [decimal](13,2)) THEN Rate ELSE 0  END AS varchar(255))
      +'|'+cast([DiscAmount] as varchar(255))
      +'|'+cast([gcpro] as varchar(255))
      +'|'+cast([RevCode] as varchar(255))
      +'|'+cast([acctcode] as varchar(255)) as outputline from #importTP_EDEN_fileData_NP 


if (select count(*) from tempdb.sys.tables where name like '%TPsalesDetail_NP%') <>0
BEGIN
DROP TABLE #exTPsalesDetail_NP
END

if (select count(*) from tempdb.sys.tables where name like '%TPdiscLines_NP%') <>0
BEGIN
DROP TABLE #exTPdiscLines_NP
END

if (select count(*) from tempdb.sys.tables where name like '%importTP_EDEN_fileData_NP%') <>0 
BEGIN
DROP TABLE #importTP_EDEN_fileData_NP
END

END TRY	  

BEGIN CATCH

       DECLARE @profile VARCHAR(255) = 'SQLData'
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
