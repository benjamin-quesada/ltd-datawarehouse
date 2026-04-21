SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [efare].[get_multistop_travel_analysis]
AS 

/************LTD_GLOSSARY*********

CREATED ON	: 20250924
CREATED BY	: B. Eichberger
Purpose		: Populate a table to support travel flow analysis for efare
			  where does travel start and what is the last stop and route 
			  a rider selected in the span of a day (or days). CHecks for 
			  values in [efare].[multistop_analysis] that need added to 
			  [efare].[multistop_analysis]	

USE			: exec [efare].[get_multistop_travel_analysis]
*/
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

BEGIN TRY

set nocount on;


drop table if exists #TMInfo
declare @lastDt date
select @lastDt = (select isnull(dateadd(day,-25,max(ts_dt)),'7/1/2022') from efare.multistop_travel_distance)
declare @sdt datetime2 = sysdatetime()
declare @outputTbl2 table (actionNm varchar(32))

select distinct [ROUTE_ABBR]
,[ROUTE_NAME]
,[STOP_ABBR]
,[STOP_NAME]
,[STOP_LATITUDE]
,[STOP_LONGITUDE]
into #TMInfo
from [ltd_dw].[model].[ROUTE_DIR_STOP_TP]
where route_name <> ROUTE_ABBR

insert [efare].[multistop_analysis]		(
[transaction_card_account_key]
,[ts_dt]
,[fareType]
,[route]
,[stopId]
,[latitude]
,[longitude]
,[next_stopid]
,[next_stopid_lat]
,[next_stopid_lon]
,[next_board_time]
,[seconds_to_next_board]
,[first_board]
,[last_board]
,[seconds_first_to_last_board] 
,[manhattan_miles]
,[straight_distance_miles]
,[tsInLocalTimeCalId]
,[tsInLocalTimeSPM]
,tsinlocalTime
,[tripSequence]
,[ROUTE_NAME]
,[STOP_NAME]
,[STOP_LATITUDE]
,[STOP_LONGITUDE]
,[distance_to_geostop]
)
output 'INSERT' into @outputTbl2
-- 309389
select q2.transaction_card_account_key
	 , q2.ts_dt
     , q2.fareType
     , q2.route
	 , q2.stopId
     , q2.latitude
     , q2.longitude
     , q2.next_stopid
      ,q2.next_stopid_lat
      ,q2.next_stopid_lon
      ,q2.next_board_time
	  ,q2.seconds_to_next_board
      ,q2.first_board
      ,q2.last_board
	  ,q2.seconds_first_to_last_board
      , q2.manhattan_miles 
	 , q2.straight_distance_miles 
      ,q2.tsInLocalTimeCalId
      ,q2.tsInLocalTimeSPM
	  ,q2.tsInLocalTime
     , q2.tripSequence
     , q2.ROUTE_NAME
     , q2.STOP_NAME
     , q2.STOP_LATITUDE
     , q2.STOP_LONGITUDE
     , distance_to_geostop = 
		case
			when q2.isAtGeoStop1 <= q2.isAtGeoStop2 and q2.isAtGeoStop2 <= q2.isAtGeoStop3 then 1
			when q2.isAtGeoStop2 <= q2.isAtGeoStop3 then 2
			when q2.isAtGeoStop3 = 3 then 3
			else null 
		end
from (
select q.transaction_card_account_key
     , q.tsInLocalTime
     , q.ts_dt
     , q.fareType
     , q.route
     , q.stopId
     , q.latitude
     , q.longitude
     , q.umoStopPoint
     , q.next_stopid
     , q.next_stopid_lat
     , q.next_stopid_lon
     , q.umoNextStopPoint
	 , manhattan_miles = (abs(q.latitude - q.next_stopid_lat)*111.32 
								+ abs(q.longitude - q.next_stopid_lon) *111.32)/1.609 -- 111.32 converts degrees to kilometers 
	 , straight_distance_miles = 
			case when q.latitude is not null and q.longitude is not null and q.next_stopid_lat is not null and q.next_stopid_lon is not null 
			and isnull(sin(radians(q.latitude)) * sin(radians(q.next_stopid_lat)) +
					cos(radians(q.latitude)) * cos(radians(q.next_stopid_lat)) *
						cos(radians(q.longitude) - radians(q.next_stopid_lon)),999999999) between -1 and 1  then
			   acos(
			  	sin(radians(q.latitude)) * sin(radians(q.next_stopid_lat)) +
					cos(radians(q.latitude)) * cos(radians(q.next_stopid_lat)) *
						cos(radians(q.longitude) - radians(q.next_stopid_lon))

				) 
				* 3959 else null end
     , q.next_board_time
     , q.seconds_to_next_board
     , q.first_board
     , q.last_board
     , q.seconds_first_to_last_board
     , q.tsInLocalTimeCalId
     , q.tsInLocalTimeSPM
     , q.tripSequence
     , q.ROUTE_ABBR
     , q.ROUTE_NAME
     , q.STOP_ABBR
     , q.STOP_NAME
     , q.STOP_LATITUDE
     , q.STOP_LONGITUDE
, isAtGeoStop1 = case when q.geoStopCircle1.STIntersection(q.umoStopPoint).ToString() like '%empty%' then null else 1 end
, isAtGeoStop2 = case when q.geoStopCircle2.STIntersection(q.umoStopPoint).ToString() like '%empty%' then null else 2 end
, isAtGeoStop3 = case when q.geoStopCircle3.STIntersection(q.umoStopPoint).ToString() like '%empty%' then null else 3 end
    from 
	(
	select d.transaction_card_account_key
      ,d.tsInLocalTime
      ,d.ts_dt
      ,d.fareType
      ,d.route
      ,d.stopId
      ,[latitude] = case when d.latitude is not null 
							then cast(d.latitude as decimal(12,8))
							else null end
      ,[longitude] = case when d.longitude is not null 
							then cast(d.longitude as decimal(12,8))
							else null end
	  ,umoStopPoint = case when d.latitude is not null then 
							geography::Point(d.latitude, d.longitude ,4326)
							else null end
	  ,d.next_stopid
      ,[next_stopid_lat] = case when d.next_stopid_lat is not null and d.next_stopid_lat <> 'end' 
							then cast(d.next_stopid_lat as decimal(12,8))
							else null end
      ,[next_stopid_lon] =  case when d.next_stopid_lon is not null and d.next_stopid_lon <> 'end' 
							then cast(d.next_stopid_lon as decimal(12,8))
							else null end
	  ,umoNextStopPoint = case when d.next_stopid_lat is not null and d.next_stopid_lat <> 'end'  then 
							geography::Point(d.next_stopid_lat, d.next_stopid_lon ,4326)
							else null end
      ,d.next_board_time
	  ,seconds_to_next_board = datediff(second,d.tsInLocalTime,d.next_board_time)
      ,d.first_board
      ,d.last_board
	  ,seconds_first_to_last_board = d.first_to_last_board_seconds
      ,d.tsInLocalTimeCalId
      ,d.tsInLocalTimeSPM
      ,d.tripSequence	
	  ,s.ROUTE_ABBR
      ,s.ROUTE_NAME
      ,s.STOP_ABBR
      ,s.STOP_NAME
      ,s.STOP_LATITUDE
      ,s.STOP_LONGITUDE
	  ,geoStopCircle1 = case when s.STOP_LATITUDE is not null then 
							geography::Point(s.STOP_LATITUDE, s.STOP_LONGITUDE ,4326).STBuffer(1)
							else null end
	  ,geoStopCircle2 = case when s.STOP_LATITUDE is not null then 
							geography::Point(s.STOP_LATITUDE, s.STOP_LONGITUDE ,4326).STBuffer(2)
							else null end
	  ,geoStopCircle3 = case when s.STOP_LATITUDE is not null then 
							geography::Point(s.STOP_LATITUDE, s.STOP_LONGITUDE ,4326).STBuffer(3)
							else null end
  FROM efare.multistop_travel_distance d 
  left join #TMInfo s on d.route = s.ROUTE_ABBR and d.stopId = s.STOP_ABBR
where d.ts_dt >= @lastDt
and not exists (select 1 from [efare].[multistop_analysis]
					where transaction_card_account_key = d.transaction_card_account_key
					  and tsInLocalTime = d.tsInLocalTime
					  and ts_dt = d.ts_dt
					  and fareType = d.fareType
					  and route = d.route
					  and stopId = d.stopId )
						) q 

) q2


DECLARE @ins INT = (SELECT COUNT(*) FROM @outputTbl2 WHERE actionNm = 'INSERT')
DECLARE @upd INT = (SELECT COUNT(*) FROM @outputTbl2 WHERE actionNm = 'UPDATE')
DECLARE @del INT = (SELECT COUNT(*) FROM @outputTbl2 WHERE actionNm = 'DELETE')
DECLARE @prg varchar(90) = @@SERVERNAME + '.ltd_dw.efare.multistop_travel_distance_by_day_stop_rte'

insert process.mergeLogs
(		[MergeCode]
           ,[ObjectDestination]
           ,[ObjectSource]
           ,[ObjectProgram]
           ,[recInsert]
           ,[recUpdate]
           ,[recDelete]
           ,[MergeBeginDatetime]
           ,[MergeEndDatetime])
select 'EFARE',
'ltd_dw.efare.multistop_analysis',
'EFARE',
@prg,
isnull(@ins,0) ,ISNULL(@upd,0),ISNULL(@del,0),
@sdt,
sysdatetime()





END TRY
BEGIN CATCH

	DECLARE @profile VARCHAR(255) =
			(SELECT name FROM msdb .dbo.sysmail_profile)  ;
	DECLARE @errormsg VARCHAR(MAX)
		   ,@error INT
		   ,@message VARCHAR(MAX)
		   ,@xstate INT
		   ,@errsev INT
		   ,@sub VARCHAR(255) ;

	SELECT	@error = ERROR_NUMBER()
		   ,@errsev = ERROR_SEVERITY()
		   ,@message = ERROR_MESSAGE()
		   ,@xstate = XACT_STATE() ;

	SELECT	@errormsg = 'Error in ' + ISNULL(@SPROC, '') + ': ' + CAST(ISNULL(@error, '') AS NVARCHAR(32)) + '|' + COALESCE(@message, '') + '|' + CAST(ISNULL(@xstate, '') AS NVARCHAR(32)) + '|' + CAST(ISNULL(@errsev, '') AS NVARCHAR(32)) ;

	SELECT	@sub = 'ERROR: ' + @SPROC ;

	EXEC msdb.dbo.sp_send_dbmail @profile_name = @profile
								,@recipients = 'barb.eichberger@ltd.org'
								,@subject = @sub
								,@body = @errormsg ;

	RAISERROR(@errormsg, @errsev, 1) ;
END CATCH ;

GO
