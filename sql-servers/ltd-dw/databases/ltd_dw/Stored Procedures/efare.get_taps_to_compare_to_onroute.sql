SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [efare].[get_taps_to_compare_to_onroute]

as

/*******************************
CREATED BY	: B Eichberger and B Crowe
CREATED ON	: 20250606
PURPOSE		: analyze the dfifernces between fare taps 
			  and On Route boarding counts for 2020 forward

CHANGED BY	: B Eichberger
CHANGED ON	: 20250609
PURPOSE		: convert to load only latest data to table/ remove truncate

USE			: exec efare.get_taps_to_compare_to_onroute

*/

set nocount on

declare @SPROC varchar(100)
set @SPROC = object_schema_name(@@procid) + '.' + object_name(@@procid)

insert into DBA.[aud].[Object_Activity]
	([server_name], [database_name] ,[host_name], [System_User], [object_name]
	,[client_net_address], [local_net_address], [auth_Scheme], [last_read], [last_write]
	,[most_recent_sql_handle], [Timestamp], object_type)
SELECT DISTINCT @@SERVERNAME, DB_NAME(),HOST_NAME(),SYSTEM_USER, @SPROC,
	client_net_address, local_net_address , auth_Scheme, last_read, last_write 
	,most_recent_sql_handle, CURRENT_TIMESTAMP AS [Timestamp], 'PROC'
FROM sys.dm_exec_connections 
WHERE session_id = @@SPID ;

BEGIN TRY



drop table if exists ltd_dw.wrk.umo_compare_set
drop table if exists ltd_dw.wrk.or_compare_set 
;

declare @lastloadint int
declare @lastloaddt datetime
declare @lastloadstr varchar(42)
declare @todayDt datetime
declare @todaystr varchar(42)

select @lastloadint = (select max(calendar_id) -- select * 
						from efare.taps_compare_to_onroute_boarding)
select @lastloaddt = (select dateadd(day,-5,isnull([dbo].[F_CALENDAR_ID_TO_DATE](@lastloadint),'1/1/2020') ))
select @lastloadstr = (select convert(varchar,dateadd(day,-1,@lastloaddt),126) as [yyyy-mm-ddThh:mi:ss])

select @todayDt = (select dateadd(day,-1,isnull(max(calendar_date),'1/1/2020')) from tm.DW_CALENDAR )
select @todaystr = (select convert(varchar,@todayDt,126) as [yyyy-mm-ddThh:mi:ss])

--select @todaystr
--select @lastloadstr

--delete from efare.taps_compare_to_onroute_boarding where Calendar_ID > dbo.F_DATE_TO_CALENDAR_ID(@lastloadstr)

drop table if exists ltd_dw.wrk.umo_compare_set
declare @sqlcmd1 nvarchar(max)
select @sqlcmd1 = 'select cast("[FARE].[stopId].[stopId].[MEMBER_CAPTION]" as varchar(56)) as StopId,
case when cast("[FARE].[routeName].[routeName].[MEMBER_CAPTION]" as varchar(56))  = ''Emx'' then ''103'' else 
		  cast("[FARE].[routeName].[routeName].[MEMBER_CAPTION]" as varchar(56)) end as Route_Number,
cast("[CALENDAR].[CALENDAR_Id].[CALENDAR_Id].[MEMBER_CAPTION]" as varchar(56)) as Calendar_Id,
cast("[Measures].[Count Fare Transactions]" as varchar(56)) as FareTaps
into ltd_dw.wrk.umo_compare_set
from (
select * from openquery([UMO_ANALYSIS], 
'' SELECT NON EMPTY { [Measures].[Count Fare Transactions] } ON COLUMNS, NON EMPTY 
{ ([CALENDAR].[CALENDAR_ID].[CALENDAR_ID].ALLMEMBERS 
* [FARE].[routeName].[routeName].ALLMEMBERS 
* [FARE].[stopId].[stopId].ALLMEMBERS ) } DIMENSION PROPERTIES MEMBER_CAPTION
ON ROWS FROM ( SELECT ( [CALENDAR].[Calendar_Date].&['+@lastloadstr+'] : [CALENDAR].[CALENDAR_DATE].&['+@todaystr+'] ) ON COLUMNS 
	FROM [Model]) CELL PROPERTIES VALUE, BACK_COLOR, FORE_COLOR, FORMATTED_VALUE, FORMAT_STRING, FONT_NAME, FONT_SIZE, FONT_FLAGS''
)) q1'
--print @sqlcmd1
exec sp_executesql @sqlcmd1

drop table if exists ltd_dw.wrk.or_compare_set
declare @sqlcmd2 nvarchar(max)
select @sqlcmd2 =
'select cast("[DW CALENDAR].[Calendar_Id].[Calendar_Id].[MEMBER_CAPTION]"as varchar(56))  as Calendar_ID,
cast("[ROUTE DIR STOP TP and TRIP].[ROUTE_ABBR].[ROUTE_ABBR].[MEMBER_CAPTION]"as varchar(56))  as Route_ABBR,
cast("[ROUTE DIR STOP TP and TRIP].[STOP_ABBR].[STOP_ABBR].[MEMBER_CAPTION]"as varchar(56))  as Stop_ABBR,
cast("[Measures].[Total Passenger Board]"as varchar(56))  as TM_Boarding
into ltd_dw.wrk.or_compare_set
from (
select * from openquery([TM_ANALYSIS], ''SELECT NON EMPTY { [Measures].[Total Passenger Board] } 
ON COLUMNS, NON EMPTY { ([DW CALENDAR].[Calendar_Id].[Calendar_Id].ALLMEMBERS 
* [ROUTE DIR STOP TP and TRIP].[ROUTE_ABBR].[ROUTE_ABBR].ALLMEMBERS 
* [ROUTE DIR STOP TP and TRIP].[STOP_ABBR].[STOP_ABBR].ALLMEMBERS ) } DIMENSION PROPERTIES MEMBER_CAPTION 
ON ROWS FROM ( SELECT ( [DW CALENDAR].[Calendar_Date].&['+@lastloadstr+'] : [DW CALENDAR].[CALENDAR_DATE].&['+@todaystr+'] ) 
ON COLUMNS FROM [Model]) CELL PROPERTIES VALUE, BACK_COLOR, FORE_COLOR, FORMATTED_VALUE, FORMAT_STRING, FONT_NAME, FONT_SIZE, FONT_FLAGS
'')) q2'
--print @sqlcmd2
exec sp_executesql @sqlcmd2

drop table if exists #mergesource
select distinct t.Calendar_Id
	 , route_ABBR = isnull(t.route_ABBR,'Other')
     , Stop_ABBR = isnull(t.Stop_ABBR,'Other')
     , TM_Boarding = sum(isnull(cast(t.TM_Boarding as int),0))
     , FareTaps = sum(isnull(cast(f.FareTaps as int) ,0))
into #mergesource
from ltd_dw.wrk.or_compare_set t  
left join ltd_dw.wrk.umo_compare_set f 
		on t.route_ABBR = f.Route_Number and t.stop_abbr = f.stopId and t.Calendar_Id = f.Calendar_Id
where t.Route_ABBR <> 'swap'  
group by t.Calendar_Id
	 , t.route_ABBR
     , t.Stop_ABBR



--SELECT top(100) * FROM efare.taps_compare_to_onroute_boarding order by calendar_id desc
insert efare.taps_compare_to_onroute_boarding 
(	  Calendar_ID
      ,[Route_ABBR]
      ,[Stop_ABBR]
      ,[TM_Boarding]
      ,[FareTaps])
select 
	  m.[Calendar_ID]
      ,m.[Route_ABBR]
      ,m.[Stop_ABBR]
      ,m.[TM_Boarding]
      ,m.[FareTaps]
from #mergesource m 
where not exists 
	(select 1 from efare.taps_compare_to_onroute_boarding e
		where m.calendar_id = e.Calendar_ID
		  and m.route_ABBR = e.Route_ABBR
		  and m.stop_ABBR = e.Stop_ABBR
		  and m.TM_Boarding = e.TM_Boarding
		  and m.FareTaps = e.FareTaps)

		  
drop table if exists ltd_dw.wrk.umo_compare_set
drop table if exists ltd_dw.wrk.or_compare_set 


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
