SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   PROCEDURE [efare].[Upsert_UmoPassSalesv2]
as
 --exec [efare].[Upsert_UmoPassSalesv2]

/*------------------LTD_GLOSSARY---------------
UPDATED BY:	Sopheap Suy
UPDATED DT:  10/31/2024
purpose	 :  Add object activities on who, what, when call this object
			write this data to aud.object_activity table everytime it's called */

set nocount on

declare @SPROC varchar(100)
set @SPROC = object_schema_name(@@procid) + '.' + object_name(@@procid)

insert into DBA.[aud].[Object_Activity]
	([server_name], [database_name] ,[host_name], [System_User], [object_name]
	,[client_net_address], [local_net_address], [auth_Scheme], [last_read], [last_write]
	,[most_recent_sql_handle], [Timestamp], object_type)
select distinct @@servername, db_name(),host_name(),system_user, @SPROC,
	client_net_address, local_net_address , auth_Scheme, last_read, last_write 
	,most_recent_sql_handle, current_timestamp as [Timestamp], 'PROC'
from sys.dm_exec_connections 
where session_id = @@spid ;

begin try

insert [efare].[TouchPassSales_Extendedv2] (txId,YYYYMM, saleTs, saleLocalTs, [Reseller], Product, AmtSales, CountSales)
select distinct txId,YYYYMM, saleTs,saleLocalTs, isnull(ResellerShortName,'Not Named') ResellerShortName,
isnull(Product,'Not Named') Product, AmtSales, SalesCount 
from (
select a.txid
,coalesce(a.[SaleYYYYMM], c.[SaleYYYYMM]) YYYYMM
,coalesce(a.saleTs,c.saleTs) saleTs
,coalesce(a.saleLocalTs,c.saleLocalTs) saleLocalTs
,c.[ResellerShortName] as ResellerShortName 
      ,coalesce(a.FareType, c.FareType) Product
      ,sum(isnull(a.[Cost],0)) AmtSales
	  ,sum(isnull(c.Qty,0)) SalesCount -- select * 
  from efare.SalesbyResellerv2 a
	  full outer join (select txId,shortName
					   ,resellerShortName
					   ,EdenCode
					   ,SaleYYYYMM
					   ,saleTs
					   ,saleLocalTs
					   ,FareType
					   ,cost
					   ,qty from 
					efare.SalesbyResellerv2
				) c 
		on c.SaleYYYYMM = a.SaleYYYYMM
		and replace(c.ResellerShortName,' ','') = replace(a.ResellerShortName,' ','')
		and replace(replace(c.FareType,' Count',''),'  Count','') = a.FareType
		and c.txId = a.txId
		group by a.txId,
			coalesce(a.[SaleYYYYMM], c.[SaleYYYYMM]) 
			,coalesce(a.saleTs,c.saleTs)
			,coalesce(a.saleLocalTs,c.saleLocalTs)
			,c.[ResellerShortName]
			,coalesce(a.FareType, c.FareType )		
			) q 
where not exists
	  (select 1 -- select * 
	  from [efare].[TouchPassSales_Extendedv2]
		where txId = q.txId  
			)
		and isnull(q.AmtSales,0) <> 0
	
end try	  


begin catch

       declare @profile varchar(255) = (
                    select NAME
                    from msdb.dbo.sysmail_profile
                    )
       declare @errormsg varchar(max)
             ,@error int
             ,@message varchar(max)
             ,@xstate int
             ,@errsev int
             ,@sub varchar(255);

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
