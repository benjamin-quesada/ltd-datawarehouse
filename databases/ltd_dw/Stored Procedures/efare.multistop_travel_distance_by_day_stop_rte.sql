SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE   procedure [efare].[multistop_travel_distance_by_day_stop_rte]
as 

/************LTD_GLOSSARY*********

CREATED ON	: 20240711
CREATED BY	: B. Eichberger
Purpose		: Populate a table to support travel flow views for efare
			  where does travel start and what is the last stop and route 
			  a rider selected in the span of a day (or days).

USE			: exec [efare].[multistop_travel_distance_by_day_stop_rte]


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

BEGIN TRY

declare @lastDt date
select @lastDt = (select isnull(dateadd(day,-5,max(ts_dt)),'7/1/2022') from -- truncate table 
		efare.multistop_travel_distance)
declare @sdt datetime2 = sysdatetime()
declare @outputTbl1 table (actionNm varchar(32));
DECLARE @outputTbl2 TABLE (actionNm VARCHAR(32));

;
drop table if exists #rawdt
select e.tsInLocalTime
, cast(e.tsInLocalTime as date) ts_dt
,e.transaction_card_account_key
,e.[fareType]
,e.[stopId]
,e.latitude
,e.longitude
,e.[routeName] [route]
into #rawdt
from [ltd_dw].[efare].vw_FARE_Extended e 
WHERE stopid IS NOT null and e.latitude <> '0.0' and e.longitude <> '0.0'
and e.tsInLocalTime >= @lastDt

truncate table efare.stage_multistop_travel_distance
insert efare.stage_multistop_travel_distance(
[tsInLocalTime]
,[ts_dt]
,[transaction_card_account_key]
,[fareType]
,[route]
,[stopId]
,[latitude]
,[longitude]
,[next_stopid]
,[next_stopid_lat]
,[next_stopid_lon]
,[next_board_time]
,[tsInLocalTimeCalId]
,[tsInLocalTimeSPM]
,[tripSequence]
)
select distinct b.tsInLocalTime
     , b.ts_dt
     , b.transaction_card_account_key
     , b.fareType
     , b.route
     , b.stopId
     , b.latitude
     , b.longitude
     , b.next_stopid
     , b.next_stopid_lat
     , b.next_stopid_lon
     , b.next_board_time
     , b.tsInLocalTimeCalId
     , b.tsInLocalTimeSPM
     , b.tripSequence 
from (
SELECT t.tsInLocalTime
, t.ts_dt
, t.transaction_card_account_key
, t.fareType
, t.[route]
, t.stopId
, t.latitude
, t.longitude
, next_stopid = ISNULL(LEAD(t.stopId) OVER (PARTITION BY transaction_card_account_key,t.ts_dt ORDER BY t.tsInLocalTime) , 'end')
, next_stopid_lat = ISNULL(LEAD(t.latitude) OVER (PARTITION BY transaction_card_account_key,t.ts_dt ORDER BY t.tsInLocalTime) , 'end')
, next_stopid_lon = ISNULL(LEAD(t.longitude) OVER (PARTITION BY transaction_card_account_key,t.ts_dt ORDER BY t.tsInLocalTime) , 'end')
, LEAD(tsInLocalTime)  OVER (PARTITION BY t.transaction_card_account_key,ts_dt ORDER BY tsInLocalTime) next_board_time
, tsInLocalTimeCalId = [dbo].[F_DATE_TO_CALENDAR_ID](tsInLocalTime)
, tsInLocalTimeSPM = [dbo].[F_DATE_TO_SEC_SINCE_MIDNITE](tsInLocalTime)
, tripSequence = ROW_NUMBER() OVER (PARTITION BY t.transaction_card_account_key,t.ts_dt ORDER BY t.tsInLocalTime)
FROM #rawdt t 
) b

drop table if exists #first_last
select  transaction_card_account_key,ts_dt,min(tsInLocalTime) first_board, max(tsInLocalTime) last_board
into #first_last 
from efare.stage_multistop_travel_distance
group by transaction_card_account_key,ts_dt order by ts_dt


insert into [efare].[multistop_travel_distance]
([transaction_card_account_key]
,[tsInLocalTime]
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
,[first_board]
,[last_board]
,[first_to_last_board_seconds]
,[tsInLocalTimeCalId]
,[tsInLocalTimeSPM]
,[tripSequence])
OUTPUT 'INSERT' INTO @outputTbl1
select
x.transaction_card_account_key
,x.tsInLocalTime
,x.ts_dt
,x.fareType
,x.route
,x.stopId
,x.latitude
,x.longitude
,x.next_stopid
,x.next_stopid_lat
,x.next_stopid_lon
,x.next_board_time
,f.[first_board]
,f.[last_board]
,[first_to_last_board_seconds] = datediff(second,f.first_board, f.last_board)
,x.tsInLocalTimeCalId
,x.tsInLocalTimeSPM
,x.tripSequence
FROM efare.stage_multistop_travel_distance x 
left join #first_last f on f.transaction_card_account_key = x.transaction_card_account_key and f.ts_dt = x.ts_dt
where NOT EXISTS (SELECT 1 FROM efare.multistop_travel_distance d
		where x.[transaction_card_account_key] = d.transaction_card_account_key
		and x.[tsInLocalTime] = d.tsInLocalTime)
order by x.tsInLocalTime


DECLARE @ins INT = (SELECT COUNT(*) FROM @outputTbl1 WHERE actionNm = 'INSERT')
DECLARE @upd INT = (SELECT COUNT(*) FROM @outputTbl1 WHERE actionNm = 'UPDATE')
DECLARE @del INT = (SELECT COUNT(*) FROM @outputTbl1 WHERE actionNm = 'DELETE')
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
'ltd_dw.efare.multistop_travel_distance',
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
