SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





/**************************************

CREATED BY	: B Eichberger
CREATED ON	: 
PURPOSE		: security: mask user details from electronic fare activity
			  from tabular model and other reporting structures
			  contains all sales activity
			  NOTE: API naming point: column passUsed = pass object purchased

*/



CREATE view [efare].[vw_SALE]
as
select '1'+cast(convert(varchar(32),tsInLocalTime,112) as varchar(32)) + right('000000'+ cast([dbo].[F_DATE_TO_SEC_SINCE_MIDNITE](tsInLocalTime) as varchar(32)),6) ts_spm_key
,'1'+cast(convert(varchar(32),tsInLocalTime,112) as varchar(32)) tsCalId
,[dbo].[F_DATE_TO_SEC_SINCE_MIDNITE](tsInLocalTime) tsSPM
, h.TxId
,h.Ts
,h.tsInLocalTime
,model_partition = datepart(year,getdate())
,h.Type
,h.FareType
--,h.AccountId
,coalesce(c.cardAccount_key,0) transaction_card_account_key
,isnull(h.passUsed, 'Other') passUsed
--,salesuser
,case when h.resellerShortName in ('Delerrok','Umo')  then 'efare Service Provider'
	  when h.SalesUserName like '+%[0-9]%' then 'Communication Device'
	  when h.SalesChannel = 'PROGRAMS' then upper(SalesUserName)
	  when rtrim(ltrim(h.SalesUser)) = '' and h.SalesUser not like '+%[0-9]%' then 'Other'  
	  when resellerShortName = 'LTD CSC' and h.SalesUser like 'Guest%' then 'LTD CSC'
	  when h.SalesChannel = 'Agency' or h.resellerShortName like '%LTD%' or salesChannel = 'Unknown' then SalesUser
	  when h.saleschannel like 'THIRD%'  then upper(SalesUserName)
	  when h.salesChannel like '%admin%' and salesUserName = SalesUser then (SalesUser)
	  when salesChannel = 'Passenger' then 'Passenger'
	  --when isnull(h.passUsed, 'Other') = 'Other' and 
	  end SalesUser
--,case when rtrim(ltrim(h.SalesUsername)) = '' then 'Other' else [dbo].[fn_ProperCase](h.SalesUsername) end SalesUserName
,h.SalesChannel
,h.resellerShortName
,h.FundingSourceType
,h.LocationDescription
,h.Cost
from (
select distinct s.TxId
	  ,s.Ts
	  ,convert(datetime, 
		switchoffset(convert(datetimeoffset, s.[ts]), 
				datename(tzoffset, sysdatetimeoffset()))) 
		as tsInLocalTime
	  ,s.Type
	  ,s.FareType
	  ,s.AccountId
	  ,s.passUsed
	  ,s.SalesUser
	  ,s.SalesUsername
	  ,s.SalesChannel
	  ,s.resellerShortName
	  ,s.FundingSourceType
	  ,s.LocationDescription
	  ,s.Cost
  from [ltd_dw].[efare].[SALE_Extendedv2] s with (nolock)
  ) h
left join (select distinct cast(cardAccount_key as varchar(32)) cardAccount_key, AccountId from [efare].[card_account_xref]) c on c.accountId = h.AccountId

GO
GRANT SELECT ON  [efare].[vw_SALE] TO [public]
GO
