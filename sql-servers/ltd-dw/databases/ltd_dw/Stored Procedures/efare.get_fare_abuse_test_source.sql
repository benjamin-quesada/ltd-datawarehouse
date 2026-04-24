SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [efare].[get_fare_abuse_test_source]
as

/*******************************
CREATED BY	: B Eichberger
CREATED ON	: 20250620
PURPOSE		: analyze for possible fare card/account abuse

USE			: exec efare.get_fare_abuse_test_source

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

begin try


declare @maxCalId varchar(32) = (select isnull(max(calendar_id),120250101) from efare.tap_count_summaries)
declare @fillToCalId varchar(32) = (select max(calendar_id) from tm.DW_CALENDAR where calendar_date < dateadd(day,-2,getdate()))

drop table if exists efare.stage_fare_taps

if (select count(*) from sys.objects where name = 'stage_fare_taps' and type = 'U') = 0
BEGIN
create table efare.stage_fare_taps(
calendar_id int not null,
route_name varchar(90),
stopId varchar(32),
RN int,
card_holder_key int,
transaction_count int
)
END

--select @maxCalId, @fillToCalId
declare @sqlcmd nvarchar(max)

Select @sqlcmd = '
insert efare.stage_fare_taps
(
   card_holder_key
  , calendar_id
  , route_name
  , stopId
  , RN
  , transaction_count
)
select distinct * from (
select 
 cast("[FARE].[transaction_card_account_key].[transaction_card_account_key].[MEMBER_CAPTION]" as varchar(56)) as card_holder_key
,cast("[CALENDAR].[CALENDAR_Id].[CALENDAR_Id].[MEMBER_CAPTION]" as varchar(56)) as calendar_id
,cast("[FARE].[routeName].[routeName].[MEMBER_CAPTION]" as varchar(90)) route_name
,cast("[FARE].[StopId].[StopId].[MEMBER_CAPTION]" as varchar(32)) stop_id
,cast("[DW_TIME].[RN].[RN].[MEMBER_CAPTION]" as varchar(90)) as TxSec
,cast("[Measures].[Count all Transaction Ids]" as varchar(56)) as FareTaps
from (select * from openquery([UMO_ANALYSIS], 
''SELECT NON EMPTY { [Measures].[Count all Transaction Ids] } ON COLUMNS
, NON EMPTY { ([FARE].[transaction_card_account_key].[transaction_card_account_key].ALLMEMBERS 
* [FARE].[routeName].[routeName].ALLMEMBERS
* [FARE].[StopId].[StopId].ALLMEMBERS
* [CALENDAR].[CALENDAR_ID].[CALENDAR_ID].ALLMEMBERS 
* [DW_TIME].[RN].[RN].ALLMEMBERS ) } DIMENSION PROPERTIES MEMBER_CAPTION ON ROWS
FROM ( SELECT ( [CALENDAR].[CALENDAR_ID].&['+ @maxCalId +'] : [CALENDAR].[CALENDAR_ID].&['+ @fillToCalId +'] ) 
 ON COLUMNS FROM [Model])
CELL PROPERTIES VALUE, BACK_COLOR, FORE_COLOR, FORMATTED_VALUE, FORMAT_STRING, FONT_NAME, FONT_SIZE, FONT_FLAGS'')
) q
where cast("[FARE].[transaction_card_account_key].[transaction_card_account_key].[MEMBER_CAPTION]" as varchar(56)) <> 0
and isnull(cast("[FARE].[routeName].[routeName].[MEMBER_CAPTION]" as varchar(90)),'''') <> ''''
and cast("[CALENDAR].[CALENDAR_Id].[CALENDAR_Id].[MEMBER_CAPTION]" as varchar(56)) is not null 
) i
'


exec sp_executesql @sqlcmd

create index ix_stage_fare_taps_calendar_id_card_holder_key on efare.stage_fare_taps(calendar_id,card_holder_key) include(RN, route_name, stopId, transaction_count)

   
insert efare.fare_taps_detail(
	   calendar_id
     , route_name
     , stopId
     , RN
     , card_holder_key
     , transaction_count
)
select calendar_id
     , route_name
     , stopId
     , RN
     , card_holder_key
     , transaction_count 
from efare.stage_fare_taps t
where not exists (select 1 from efare.fare_taps_detail d 
						where d.calendar_id = t.calendar_id
						and isnull(d.route_name,'') = isnull(t.route_name,'')
						and isnull(d.stopId,'') = isnull(t.stopId,'')
						and isnull(d.RN,0) = isnull(t.RN,0)
						and isnull(d.card_holder_key,0) = isnull(t.card_holder_key,0)
						and isnull(d.transaction_count,0) = isnull(t.transaction_count,0)
						)

insert efare.tap_count_summaries(
[testsource]
,[calendar_id]
,card_holder_key
,[testinfo]
,[transaction_count]
)
select 'daytaps' as testsource, calendar_id,card_holder_key
,datename(weekday,dbo.F_CALENDAR_ID_TO_DATE(calendar_id)) as testinfo
,count(transaction_count) transaction_count
from efare.stage_fare_taps s
where not exists (select 1 from efare.[tap_count_summaries] t where t.testsource = 'daytaps'
		and t.calendar_id = s.calendar_id
		and t.card_holder_key = s.card_holder_key )
and s.route_name <> 'Default'
group by  calendar_id,card_holder_key,datename(day,dbo.F_CALENDAR_ID_TO_DATE(calendar_id))
having count(transaction_count) > 4


insert efare.tap_count_summaries(
[testsource]
      ,[calendar_id]
      ,card_holder_key
      ,[testinfo]
      ,[transaction_count]
)
select 'hourtaps' as testsource, calendar_id,card_holder_key
,t.[H] as testinfo
,sum(transaction_count) 
from efare.stage_fare_taps s  
join [efare].[reporting_time] t on t.[rn] = s.rn
where not exists (select 1 from efare.[tap_count_summaries] x where x.testsource = 'hourtaps' 
		and x.calendar_id = s.calendar_id
		and x.card_holder_key = s.card_holder_key
		and x.[testinfo] = t.[H] )
and s.route_name <> 'Default'
group by calendar_id,card_holder_key,t.[H] 
having count(transaction_count) > 3

-- greater than 2 taps a minute
insert efare.tap_count_summaries(
[testsource]
      ,[calendar_id]
      ,card_holder_key
      ,[testinfo]
      ,[transaction_count]
)
select 'minutetaps' as testsource, calendar_id,card_holder_key
,t.[M] as testinfo
,count(transaction_count) 
from efare.stage_fare_taps s 
join [efare].[reporting_time] t on t.[rn] = s.rn
where not exists (select 1 from efare.[tap_count_summaries] x where x.testsource = 'minutetaps' and x.calendar_id = s.calendar_id
		and x.card_holder_key = s.card_holder_key
		and x.testsource = cast(t.[M] as varchar(32)))
and s.route_name <> 'Default'
group by calendar_id,card_holder_key,t.[M] 
having count(transaction_count) > 2



drop table if exists efare.stage_fare_taps

END TRY	  

BEGIN CATCH

       DECLARE @profile VARCHAR(255) = (
                    SELECT [NAME]
                    FROM msdb.dbo.sysmail_profile
                    )
       DECLARE @errormsg VARCHAR(MAX)
             ,@error INT
             ,@message VARCHAR(MAX)
             ,@xstate INT
             ,@errsev INT
             ,@sub VARCHAR(255);

       SELECT @error = ERROR_NUMBER()
             ,@errsev = ERROR_SEVERITY()
             ,@message = ERROR_MESSAGE()
             ,@xstate = XACT_STATE();

       SELECT @errormsg = 'Error in ' + ISNULL(@SPROC, '') + ': ' + CAST(ISNULL(@error, '') AS NVARCHAR(32)) + '|' + COALESCE(@message, '') + '|' + CAST(ISNULL(@xstate, '') AS NVARCHAR(32)) + '|' +CAST(ISNULL(@errsev, '') AS NVARCHAR(32))

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
