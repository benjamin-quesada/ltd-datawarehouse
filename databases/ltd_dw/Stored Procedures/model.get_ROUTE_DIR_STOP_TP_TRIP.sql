SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   PROCEDURE [model].[get_ROUTE_DIR_STOP_TP_TRIP]
AS

/***********LTD_GLOSSARY************
CREATED ON	: 20240816
CREATED BY	: B. Eichberger
PURPOSE		: To populate tables that can be used in TM_MODEL
			  Loads two tables. Eventually ROUTE_DIR_STOP_TP
			  will be deprecated in favor of ROUTE_DIR_STOP_TP_TRIP

CHANGED ON	: 20240816
CHANGED BY	: B. Eichberger
PURPOSE		: increase number of segments in the ROUTE_DIR_STOP_TP_TRIP_KEY
              and use MERGE to avoid duplicates

exec model.[get_ROUTE_DIR_STOP_TP_TRIP
************************************

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

drop table if exists #dtgrp
select rn = ntile(240) OVER ( ORDER BY CALENDAR_ID desc) , CALENDAR_ID 
into #dtgrp  
from tm.DW_CALENDAR 
--where CALENDAR_ID >= 120190129 and CALENDAR_DATE < dateadd(day, -1, getdate())
where CALENDAR_DATE > dateadd(day, -21, getdate()) 
  and CALENDAR_DATE < dateadd(day, -1, getdate())


declare @i int = 1
declare @r int = (select max(rn) from #dtgrp)


while @i < = @r
begin


drop table if exists #loadtrips
select rn = row_number() over (order by TIME_TABLE_VERSION_ID, o.TRIP_ID)
, o.TIME_TABLE_VERSION_ID
, o.ROUTE_ID
, o.ROUTE_DIRECTION_ID
, o.GEO_NODE_ID
, o.TIME_POINT_ID
, o.SERVICE_TYPE_ID
, o.TRIP_ID 
into
#loadtrips
from (
select distinct s.[TIME_TABLE_VERSION_ID] 
       ,s.[ROUTE_ID] 
       ,s.[ROUTE_DIRECTION_ID] 
       ,s.[GEO_NODE_ID] 
       ,isnull(s.TIME_POINT_ID,0) TIME_POINT_ID
       ,s.[SERVICE_TYPE_ID]
       ,s.TRIP_ID
from [LTD-TMDATA].tmdatamart.dbo.ADHERENCE_BY_STOP s
join #dtgrp dg on dg.CALENDAR_ID = s.CALENDAR_ID
where dg.rn = @i
--and s.TRIP_ID is not null -- for adherence get all places and times and mileage
union
select distinct p.[TIME_TABLE_VERSION_ID] 
       ,p.[ROUTE_ID] 
       ,p.[ROUTE_DIRECTION_ID] 
       ,p.[GEO_NODE_ID] 
       ,isnull(p.TIME_POINT_ID,0) TIME_POINT_ID
       ,p.[SERVICE_TYPE_ID]
       ,p.TRIP_ID
from [LTD-TMDATA].tmdatamart.dbo.PASSENGER_COUNT p
join #dtgrp d on d.CALENDAR_ID = p.CALENDAR_ID
where d.rn = @i
and p.TRIP_ID is not null 
union
select distinct d.[TIME_TABLE_VERSION_ID] 
       ,d.[ROUTE_ID] 
       ,d.[ROUTE_DIRECTION_ID] 
       ,d.[GEO_NODE_ID] 
       ,isnull(d.TIME_POINT_ID,0) TIME_POINT_ID
       ,d.[SERVICE_TYPE_ID]
       ,d.TRIP_ID
from [LTD-TMDATA].tmdatamart.dbo.SCHEDULE d
join #dtgrp dg on dg.CALENDAR_ID = d.CALENDAR_ID
where dg.rn = @i
and d.TRIP_ID is not null 

) o
where not exists (select 1 from model.ROUTE_DIR_STOP_TP_TRIP q
                    where o.[TIME_TABLE_VERSION_ID]  = q.[TIME_TABLE_VERSION_ID]
                        and o.[ROUTE_ID]  = q.[ROUTE_ID]
                        and o.[ROUTE_DIRECTION_ID]  = q.[ROUTE_DIRECTION_ID]
                        and o.[GEO_NODE_ID]  = q.[GEO_NODE_ID]
                        and o.[SERVICE_TYPE_ID] = q.[SERVICE_TYPE_ID]
                        and o.TRIP_ID = q.TRIP_ID )

--select * from #loadtrips
drop table if exists #allprep
select distinct s.TIME_TABLE_VERSION_ID
     , s.SERVICE_TYPE_ID
     , s.ROUTE_ID
     , s.ROUTE_DIRECTION_ID
     , s.GEO_NODE_ID
     , r.ROUTE_ABBR
     , r.ROUTE_NAME
     , g.GEO_NODE_ABBR as STOP_ABBR
     , g.GEO_NODE_NAME as STOP_NAME
     , rd.ROUTE_DIRECTION_ABBR
     , rd.ROUTE_DIRECTION_NAME
     , upper(left(rd.ROUTE_DIRECTION_NAME, 1)) ROUTE_DIR
     , right('000000' + cast(s.[TIME_TABLE_VERSION_ID] as varchar(32)), 6)
       + right('000000' + cast(isnull(s.[ROUTE_ID],0) as varchar(32)), 6)
       + right('000000' + cast(isnull(s.[ROUTE_DIRECTION_ID],0) as varchar(32)), 6)
       + right('000000' + cast(isnull(s.[GEO_NODE_ID],0) as varchar(32)), 6)
       + right('000000' + cast(isnull(s.[SERVICE_TYPE_ID],0) as varchar(32)), 6)
       + right('0000000000' + cast(isnull(s.TRIP_ID,0) as varchar(32)), 10) as RTE_DIR_STOP_TP_TRIP_KEY
     , s.TRIP_ID
     , m.HHMM as TRIP_END_TIME
     , g.LATITUDE / 10000000.0 [STOP_LATITUDE]
     , g.LONGITUDE / 10000000.0 [STOP_LONGITUDE]
     , p.TIME_POINT_ABBR
     , p.TIME_PT_NAME as TIME_POINT_NAME

into #allprep
  from #loadtrips s 
    left join [LTD-TMDATA].tmdatamart.dbo.[ROUTE] r on r.ROUTE_ID = s.ROUTE_ID -- and r.TIME_TABLE_VERSION_ID = s.TIME_TABLE_VERSION_ID   
    left join [LTD-TMDATA].tmdatamart.dbo.TRIP t on t.TRIP_ID = s.TRIP_ID
                                  and t.TIME_TABLE_VERSION_ID = s.TIME_TABLE_VERSION_ID
    left join [LTD-TMDATA].tmdatamart.dbo.ROUTE_DIRECTION rd on rd.ROUTE_DIRECTION_ID = s.ROUTE_DIRECTION_ID
    left join [LTD-TMDATA].tmdatamart.dbo.TIME_TABLE_VERSION v on v.TIME_TABLE_VERSION_ID = s.TIME_TABLE_VERSION_ID
    left join [LTD-TMDATA].tmdatamart.dbo.TIME_POINT p on p.TIME_POINT_ID = isnull(s.TIME_POINT_ID,0)
    left join [LTD-TMDATA].tmdatamart.dbo.GEO_NODE g on g.GEO_NODE_ID = s.GEO_NODE_ID
    left join Reporting.tm.DW_TIME m on m.SPM = t.TRIP_END_TIME
 


merge [model].ROUTE_DIR_STOP_TP_TRIP t
using #allprep s
on t.RTE_DIR_STOP_TP_TRIP_KEY = s.RTE_DIR_STOP_TP_TRIP_KEY
when not matched by target
then insert     
(
 [TIME_TABLE_VERSION_ID]
,[SERVICE_TYPE_ID]
,[ROUTE_ID]
,[ROUTE_DIRECTION_ID]
,[GEO_NODE_ID]
,[ROUTE_ABBR]
,[ROUTE_NAME]
,[STOP_ABBR]
,[STOP_NAME]
,[ROUTE_DIRECTION_ABBR]
,[ROUTE_DIRECTION_NAME]
,[ROUTE_DIR]
,[RTE_DIR_STOP_TP_TRIP_KEY]
,[TRIP_ID]
,[TRIP_END_TIME]
,[STOP_LATITUDE]
,[STOP_LONGITUDE]
,[TIME_POINT_ABBR]
,[TIME_POINT_NAME]
)
values(
s.[TIME_TABLE_VERSION_ID]
,s.[SERVICE_TYPE_ID]
,s.[ROUTE_ID]
,s.[ROUTE_DIRECTION_ID]
,s.[GEO_NODE_ID]
,s.[ROUTE_ABBR]
,s.[ROUTE_NAME]
,s.[STOP_ABBR]
,s.[STOP_NAME]
,s.[ROUTE_DIRECTION_ABBR]
,s.[ROUTE_DIRECTION_NAME]
,s.[ROUTE_DIR]
,s.[RTE_DIR_STOP_TP_TRIP_KEY]
,s.[TRIP_ID]
,s.[TRIP_END_TIME]
,s.[STOP_LATITUDE]
,s.[STOP_LONGITUDE]
,s.[TIME_POINT_ABBR]
,s.[TIME_POINT_NAME]
);

						
drop table if exists #loadtrips
drop table if exists #allprep

select @i = @i + 1

if @i > @r
break
else
    continue

end

drop table if exists #ttv
select TIME_TABLE_VERSION_ID
     , TIME_TABLE_VERSION_NAME
    into #ttv from [LTD-TMDATA].tmdatamart.dbo.TIME_TABLE_VERSION 

UPDATE r 
SET significant_tp = m.significant
 -- select * 
FROM model.[ROUTE_DIR_STOP_TP_TRIP] r
INNER JOIN tm.significant_tps m 
ON m.direction = r.ROUTE_DIR
AND m.route = r.ROUTE_ABBR
AND m.tp = r.TIME_POINT_ABBR
inner join #ttv v on v.TIME_TABLE_VERSION_ID = cast(left(r.[RTE_DIR_STOP_TP_TRIP_KEY],6) as int)
WHERE 1=1 and r.significant_tp is null 


UPDATE r 
SET significant_tp = 'n' 
FROM model.[ROUTE_DIR_STOP_TP_TRIP] r
WHERE ISNULL(r.[significant_tp],'n') = 'n' or r.significant_tp is null 

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
