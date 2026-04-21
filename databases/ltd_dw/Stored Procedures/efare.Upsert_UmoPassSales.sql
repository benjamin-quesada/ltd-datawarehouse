SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   PROCEDURE [efare].[Upsert_UmoPassSales]
as

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

	
INSERT [efare].[TouchPassSales_Extended] (YYYYMM, [Reseller], Product, AmtSales, CountSales)
select YYYYMM, ResellerShortName, Product, AmtSales, SalesCount  from (
select 
coalesce(a.[SaleYYYYMM], c.[SaleYYYYMM]) YYYYMM
,c.[ResellerShortName] as ResellerShortName 
      ,coalesce(a.FareType, c.FareType) Product
      ,sum(isnull(a.[Cost],0)) AmtSales
	  ,sum(isnull(c.Qty,0)) SalesCount -- select * 
  from efare.SalesbyReseller a
  full join (select * from 
		efare.SalesbyReseller ) c on c.SaleYYYYMM = a.SaleYYYYMM
		and replace(c.ResellerShortName,' ','') = replace(a.ResellerShortName,' ','')
		and replace(replace(c.FareType,' Count',''),'  Count','') = a.FareType
group by 
		coalesce(a.[SaleYYYYMM], c.[SaleYYYYMM]) 
      ,c.[ResellerShortName]
      ,coalesce(a.FareType, c.FareType) 
      ) q
where not exists
	  (select yyyymm, ResellerShortName, Product from [efare].[TouchPassSales_Extended]
		where yyyymm = q.yyyymm and reseller = q.ResellerShortName and product = q.Product)

update t
set t.amtsales = u.amtsales
,	t.CountSales = u.salescount
,	t.UpdatedDate = sysdatetime()
from rpt.TouchPassSales t
INNER JOIN (SELECT 
COALESCE(a.[SaleYYYYMM], c.[SaleYYYYMM]) YYYYMM
,c.[ResellerShortName] AS ResellerShortName 
      ,COALESCE(a.FareType, c.FareType) Product
      ,SUM(ISNULL(a.[Cost],0)) AmtSales
	  ,SUM(ISNULL(c.Qty,0)) SalesCount -- select * 
  FROM efare.SalesbyReseller a
  FULL JOIN (SELECT * FROM efare.SalesbyReseller ) c ON c.SaleYYYYMM = a.SaleYYYYMM
		AND REPLACE(c.ResellerShortName,' ','') = REPLACE(a.ResellerShortName,' ','')
		AND REPLACE(REPLACE(c.FareType,' Count',''),'  Count','') = a.FareType
GROUP BY 
		COALESCE(a.[SaleYYYYMM], c.[SaleYYYYMM]) 
      ,c.[ResellerShortName]
      ,coalesce(a.FareType, c.FareType) 
      ) u
on t.yyyymm = u.yyyymm and t.reseller = u.ResellerShortName and t.Product = u.Product
where t.AmtSales <> u.AmtSales
or t.CountSales <> u.SalesCount


END TRY	  


BEGIN CATCH

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
             ,@recipients = 'barb.eichberger@ltd.org'--;servicedesk@ltd.org' 
             ,@subject = @sub
             ,@body = @errormsg;

       RAISERROR (
                    @errormsg
                    ,@errsev
                    ,1
                    )
END CATCH
GO
