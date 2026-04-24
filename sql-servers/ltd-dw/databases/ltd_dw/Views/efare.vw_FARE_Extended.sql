SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




/**************************************

CREATED BY	: B Eichberger
CREATED ON	: 
PURPOSE		: To merge legacy efare data that did not have good geo location information (like stop id)
			  with newer API sourced data that includes better location information.
			  The primary source for the tabular model for Umo/eFare data
CHANGED ON	: 20250805
REASON		: Add security option to expose de-identifier transaction_card_account_key
			  from [efare].[card_account_xref] instead of card and account explicit

*/

CREATE view [efare].[vw_FARE_Extended]
as
select h.txId
     , h.ts
	 , h.model_partition
     , h.type
	 , h.fareTxDescription
	 , h.FareTx
     , h.mediaUsed
     , h.mediaType
     , cardNumber
     , accountId
	 , coalesce([cardAccount_key],0) as transaction_card_account_key
     , h.fareType
	 , h.stopName
     , h.stopId
     , h.routeName
     , h.latitude
     , h.longitude
     , h.reader
	 , h.Vehicle
     , h.passUsed
     , h.productAbbreviation
     , h.trip
     , h.readerPosition
     , h.fare
     , h.routeTypeId
     , h.routeTypeName
     --, h.fileloaded
     , h.tsInLocalTime
     , h.ts_spm_key	
	 , [dbo].[F_DATE_TO_SEC_SINCE_MIDNITE](tsInLocalTime) tsSPM
	 , tsCalId
	 ,ts_spm_route_stop_trip_key = 
		   h.ts_spm_key + right('000000000000'+ cast(TRIP as varchar(12)),12)
				+ right('000000'+ cast(routeName as varchar(12)),6)
				+ right('000000'+ cast(STOPID as varchar(12)),6)
from (
select q.txId
     , q.ts
	 , q.model_partition
     , q.type
     , q.mediaUsed
	 , q.mediaType
     , cardNumber
     , accountId
	 , cardAccount_key
     , q.fareType
	 , q.fareTxDescription
	 , q.fareTx
	 , q.stopName
     , q.stopId
     , q.routeName
     , q.latitude
     , q.longitude
     , q.reader
	 , q.vehicle
     , q.passUsed
     , q.productAbbreviation
     , q.trip
     , q.readerPosition
     , q.fare
     , q.routeTypeId
     , q.routeTypeName
     --, q.fileloaded
	 ,[postedTs]
	  ,[passFirstUsed]
	  ,[lastModifiedTs]
	  ,[stopGtfsId]
	  ,[stopGtfsCode]
     , q.tsInLocalTime
	 ,[dbo].F_DATE_TO_CALENDAR_ID(cast(q.tsInLocalTime as date)) tsCalId
	 , ts_spm_key = '1'+cast(convert(varchar(32),tsInLocalTime,112) as varchar(32)) + right('000000'+ cast([dbo].[F_DATE_TO_SEC_SINCE_MIDNITE](tsInLocalTime) as varchar(32)),6)
from (
select txId
     , ts
	 , model_partition
     , type
     , mediaUsed
     , mediaType
     , fareType
     , cardNumber
     , accountId
	 , cardAccount_key
     , stopName
     , stopId
     , routeName
     , latitude
     , longitude
     , reader
	 , vehicle
     , passUsed
     , productAbbreviation
     , trip
     , readerPosition
     , fare
     , routeTypeId
     , routeTypeName
     , fareTxDescription = n.[Description]
	 , FareTx = case when n.FareTx = 'true' then 1 else 0 end
	 ,[postedTs]
	  ,[passFirstUsed]
	  ,[lastModifiedTs]
	  ,[stopGtfsId]
	  ,[stopGtfsCode]
	 ,tsInLocalTime = convert(datetime, 
									switchoffset(convert(datetimeoffset, [ts]), 
												datename(tzoffset, sysdatetimeoffset()))) 
  from [ltd_dw].[efare].[FARE_Extended] d with (nolock)
left join efare.TXN n on n.name = d.type
  ) q
) h
 


GO
