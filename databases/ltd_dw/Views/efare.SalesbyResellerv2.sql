SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



create view [efare].[SalesbyResellerv2]
as


select y.shortName, txId
     , s.resellerShortName
     , case
           when y.shortName like '%|%' then
               right(y.Name, 4)
           when y.shortName not like '%|%'
                and s.resellerShortName like '%|%' then
               right(s.resellerShortName, 4)
	   else null
       end as EdenCode
	   ,Ts as saleTs
	   ,dateadd("hh",-7,s.Ts) as saleLocalTs
     , left(convert(varchar(32), dateadd("hh",-7,s.Ts) , 112), 6) SaleYYYYMM
     , s.casePass as FareType
     , sum(s.Cost) cost
     , count(*) qty
from
(
    select r.resellLoadKey
         , r.Name
         , case
               when r.Name like '%|%' then
                   left(r.Name, charindex('|', r.Name) - 1)
               else
                   r.Name
           end shortName
 , case
                   when r.Name like '%|%' then
                       right(r.Name,4)
                   else
                       r.Name
               end custCode
         , r.Id 
	from [ltd_dw].[efare].[RESELL] r 
    where r.Name like 'NP %'
          or r.Name like 'PS %'
          or r.Name like 'AP %'
)     y
   inner join (
        select saleLoadKey
			  ,TxId
			  ,Ts
			  ,Type
			  ,FareType
			  ,AccountId
			  ,passUsed
			  ,SalesUser
			  ,SalesUsername
			  ,SalesChannel
			  ,resellerShortName
			  ,FundingSourceType
			  ,LocationDescription
			  ,Cost
			  ,fileloaded
			 , case when passUsed is null and [Type] = 'SV_Added' then 'Stored Value' 
					else passUsed end as casePass
             , case
                   when resellerShortName like '%|%' then
                       left(resellerShortName, charindex('|', resellerShortName) - 1)
                   else
                       resellerShortName
               end shortName
			 , case
                   when resellerShortName like '%|%' then
                       right(resellerShortName,4)
                   else
                       resellerShortName
               end custCode
        from efare.SALE_Extendedv2
		
    ) s
        on s.custCode = y.custCode
where s.resellerShortName is not null
group by y.Name,txid,s.Ts,dateadd("hh",-7,s.Ts) 
       , left(convert(varchar(32), s.Ts, 112), 6)
       , s.shortName
       , s.casePass
       , s.resellerShortName
       , y.shortName;


GO
