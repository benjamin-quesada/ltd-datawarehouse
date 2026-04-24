SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [efare].[OUTPUT_REPORT_ACCOMODATIONS]

@rptDate DATE = NULL
as
-- =============================================
-- Author:		B. Eichberger
-- Create date: 20200310
-- Parameter:   Enter a date, (Power BI will offer default current month) and it will translate to end of month date.
-- Change date: 
-- Description:	Receive Date Parameter from Power BI Report, Load Data to File and display for approval on Power Bi
-- Example:		exec efare.[OUTPUT_REPORT_ACCOMODATIONS] '1/25/2020'
-- 
-- =============================================


SET NOCOUNT ON

if @rptDate is null 
BEGIN
select @rptDate = getdate()
END


/*------------------LTD_GLOSSARY---------------
UPDATED BY:	Sopheap Suy
UPDATED DT:  10/31/2024
purpose	 :  Add object activities on who, what, when call this object
			write this data to aud.object_activity table everytime it's called */


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


SELECT SalesUser AS customerId
, lineCode = right(cast(txYr AS VARCHAR(32)),2) + right('00' + cast(txmo AS VARCHAR(32)), 2)
, (TsInLocalTime) tsInLocalTime
, SalesUser, [FareType], Cost, SalesUsername
, CASE WHEN [Type] = 'SV_ADDED' THEN 'Stored Value Added' WHEN [Cost] = 135
			AND faretype = 'Adult' THEN 'Adult 3-Month Pass' WHEN [Cost] = 50
			AND faretype = 'Adult' THEN 'Adult Monthly Pass' WHEN [Cost] = 25
			AND faretype = 'Youth' THEN 'Youth Monthly Pass' WHEN [Cost] = 67.50
			AND faretype = 'Youth' THEN 'Youth 3-Month Pass' WHEN [Cost] = 25
			AND faretype <> 'Youth' THEN 'Half Fare Monthly Pass' WHEN [Cost] = 67.50
			AND faretype <> 'Youth' THEN 'Half Fare 3-Month Pass' WHEN [Cost] = 3.50
			AND faretype = 'Adult' THEN 'Day Pass Adult' WHEN [Cost] = 1.75
			AND faretype = 'Adult' THEN 'One Ride Pass Adult' WHEN [Cost] = 1.75
			AND faretype = 'Youth' THEN 'Day Pass Youth' WHEN [Cost] = .85
			AND faretype = 'Youth' THEN 'One Ride Pass Youth' WHEN [Cost] = 5.25
			AND faretype = 'Half Fare' THEN 'Half Fare Six Ride' WHEN [Cost] = 10.50
			AND faretype = 'Adult' THEN 'Adult Six Ride' END SalesDescription
			, count(*) Transactions
			, sum(cost) salesLineTotal
			, sum(CASE WHEN SalesUser LIKE 'NP %' THEN cost * .75 ELSE 0 END) AS discount
			, sum(cost) - sum(CASE WHEN SalesUser LIKE 'NP %' THEN cost * .75 ELSE 0 END) AS NetCharge
INTO #TPsalesTtl
FROM (
	SELECT datepart(year, cast(DATEADD(mi, DATEDIFF(mi, GETUTCDATE(), GETDATE()), ts) AS DATE)) TxYr, datepart(month, cast(DATEADD(mi, DATEDIFF(mi, GETUTCDATE(), GETDATE()), ts) AS DATE)) TxMo, '' ACCTCODE, cast(DATEADD(mi, DATEDIFF(mi, GETUTCDATE(), GETDATE()), ts) AS DATE) TsInLocalTime, [Type], [FareType], [SalesUser], [Cost], SalesUsername
	FROM [ltd_dw].[efare].[SALE]
	WHERE 1 = 1
		AND (SalesUser LIKE '%NP %' or SalesChannel like 'THIRD%'
			--OR SalesUser LIKE 'PS DHS%'
			)
		AND [type] IN ('SV_ADDED', 'PASS_ADDED')
	) Q
WHERE 
TsInLocalTime between DATEADD(dd,  0, DATEADD(ww, DATEDIFF(ww, 0, DATEADD(dd, -1, @rptdate)) - 1, 0))
   and   DATEADD(dd,  6, DATEADD(ww, DATEDIFF(ww, 0, DATEADD(dd, -1, @rptdate)) - 1, 0))
   --eomonth(TsInLocalTime) = eomonth(@rptdate)
	AND cost > 0
GROUP BY SalesUser, (TsInLocalTime), SalesUser, [FareType],
right(cast(txYr AS VARCHAR(32)),2) + right('00' + cast(txmo AS VARCHAR(32)), 2)
,Cost,SalesUsername
, CASE WHEN [Type] = 'SV_ADDED' THEN 'Stored Value Added' WHEN [Cost] = 135
			AND faretype = 'Adult' THEN 'Adult 3-Month Pass' WHEN [Cost] = 50
			AND faretype = 'Adult' THEN 'Adult Monthly Pass' WHEN [Cost] = 25
			AND faretype = 'Youth' THEN 'Youth Monthly Pass' WHEN [Cost] = 67.50
			AND faretype = 'Youth' THEN 'Youth 3-Month Pass' WHEN [Cost] = 25
			AND faretype <> 'Youth' THEN 'Half Fare Monthly Pass' WHEN [Cost] = 67.50
			AND faretype <> 'Youth' THEN 'Half Fare 3-Month Pass' WHEN [Cost] = 3.50
			AND faretype = 'Adult' THEN 'Day Pass Adult' WHEN [Cost] = 1.75
			AND faretype = 'Adult' THEN 'One Ride Pass Adult' WHEN [Cost] = 1.75
			AND faretype = 'Youth' THEN 'Day Pass Youth' WHEN [Cost] = .85
			AND faretype = 'Youth' THEN 'One Ride Pass Youth' WHEN [Cost] = 5.25
			AND faretype = 'Half Fare' THEN 'Half Fare Six Ride' WHEN [Cost] = 10.50
			AND faretype = 'Adult' THEN 'Adult Six Ride' END


select k.customerId,lineCode,CONVERT(varchar,Dt1,101) as Dt1,ServiceType,lineNbr,
replace(k.[Description],'z ','') [Description],noNote,CONVERT(varchar,dt2,101) as Dt2,quantity,rate
,discountRate,AmountTtl,DiscountLine,gcPro,revcode,SalesUsername
 ,case when k.[Description] like '%discount%' then '010.000.00.41121' else g.GLNumber end as AcctCode
into -- drop table 
#summaryAR 
from (
	select customerId, lineCode 
	,Dt1
	,ServiceType
	,lineNbr
	,invNbr
	,[Description],NoNote,Amount,DT2,SalesUsername,
	case when [Description] like '%discount%' then 1 else Quantity end Quantity,
	case when [Description] like '%discount%' then Amount  
	--(amount*.75) 
	else Price end Rate

	,0 as DiscountRate
	,AmountTtl = 
	case when [Description] like '%discount%' then (amount)
				else 
				cast((rate * Quantity) as decimal(14,2)) 
				end
	,DiscountLine = 0 --case when [Description] like '%discount%' then (amount*.75) else 0 end 
	,GCPro = 0 ,RevCode
 from (
		SELECT customerId,lineCode,tsInLocalTime as DT1
		,'np_accom' as ServiceType
		, rank() OVER (
				PARTITION BY customerId ORDER BY customerId 
				) invNbr
		, row_number() OVER (
				PARTITION BY customerId, lineCode ORDER BY customerId, lineCode 
				, rate DESC, amount DESC
				) lineNbr
				, Rate, case when customerId like 'NP %' then .75 else 0 end discountRate
			,[Description],' ' as NoNote,Amount,tsInLocalTime as DT2,Quantity,Rate  as Price,'R' as RevCode,SalesUsername
			FROM (
		
				SELECT customerId, lineCode, tsInLocalTime   , 'z NP Discount 75%' as [Description], SalesUsername
						, sum(Transactions) Quantity, - sum(cast(discount as decimal(15,2))) Amount ,null as Rate
						FROM #TPsalesTtl
						where customerId like 'NP %'
						GROUP BY customerId, lineCode,  SalesUsername,
						tsInLocalTime

						UNION
	
						SELECT customerId, lineCode, tsInLocalTime
						, SalesDescription, SalesUsername
						, sum(Transactions) Quantity, sum(cast(salesLineTotal as decimal(15,2))) ,Cost as Rate 
						FROM #TPsalesTtl
						GROUP BY customerId, lineCode, SalesUsername, tsInLocalTime, SalesDescription, Cost
					) p
			) i
	) k
	LEFT JOIN efare.PRODUCT_GL g on g.[Description] = k.[Description]


select 'TouchPass' as InvSource, RTRIM(cast(c.cust_no as varchar(6))) cust_no,lineCode+RTRIM(cast(c.cust_no as varchar(6))) inv_no,Dt1
,DATENAME(MONTH, cast(dt1 as date)) + ' ' + CAST(YEAR(cast(dt1 as date)) AS VARCHAR(4)) + ' NP' AS 
 ServiceType,lineNbr
, 'tpacct'  as LineCategory
,[Description],NoNote,isnull(AmountTtl,0) AmountTtl,dt2,isnull(quantity,0) Qty,isnull(rate,0) Rate
,isnull(discountRate,0) discRate,isnull(DiscountLine,0) DiscAmount
,isnull(gcpro,0) gcpro,isnull(revCode,0)RevCode,acctcode,cast(getdate() as date) the_date
,salesUsername
into #AccomodationsRpt
 from #summaryAR a join efare.CUSTOMER_XW c on c.TOUCHPASS_CUSTOMER_NAME = a.customerId 
 WHERE cust_no is not null 
 
 union

select 'POS CSC', cust_no,inv_no,cast(inv_date as date) inv_date,
[description], line_no, cat_code, item_desc_1,item_desc_2,amount,due_date,fld_1, fld_2, fld_3, 
fld_4, fld_5,acct_type,acct_no, the_date,drawer_name from [LTD-FINANCE].pos_dw.[dbo].[ltd_pos_on_account_invoices]
where inv_date between DATEADD(dd,  0, DATEADD(ww, DATEDIFF(ww, 0, DATEADD(dd, -1, @rptdate)) - 1, 0))
   and   DATEADD(dd,  6, DATEADD(ww, DATEDIFF(ww, 0, DATEADD(dd, -1, @rptdate)) - 1, 0))


SELECT [InvSource]
      ,a.[cust_no]
	  ,replace(replace(replace(replace(replace(replace( UPPER(e.CUST_TYPE_CODE)  + ' ' + isnull(RTRIM(LTRIM(e.last_name)),' ') + 
		case when isnull(LTRIM(RTRIM(e.FIRST_NAME)),' ') = '' then '' else ' ' end + isnull(LTRIM(RTRIM(e.FIRST_NAME)),' '),' ',' '),' ',' ') ,' ',' ') ,' ',' ') ,' ',' ') ,' ',' ')  
Customer
      ,[inv_no]
      ,[Dt1]
      ,[ServiceType]
      ,[lineNbr]
      ,[LineCategory]
      ,[Description]
      ,[NoNote]
      ,[AmountTtl]
      ,[dt2]
      ,[Qty]
      ,[Rate]
      ,[discRate]
      ,[DiscAmount]
      ,[gcpro]
      ,[RevCode]
      ,[acctcode]
      ,[the_date]
	  ,SalesUsername
  FROM #AccomodationsRpt a
  left join [LTD-FINANCE].GoldStandard.dbo.esrcustr e on e.cust_no = a.cust_no
 
END TRY


BEGIN CATCH
       DECLARE @profile VARCHAR(255) = (
                    SELECT NAME
                    FROM msdb.dbo.sysmail_profile
                    )
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
             ,@recipients = 'barb.eichberger@ltd.org' 
             ,@subject = @sub
             ,@body = @errormsg;

       RAISERROR (
                    @errormsg
                    ,@errsev
                    ,1
                    )
END CATCH
GO
