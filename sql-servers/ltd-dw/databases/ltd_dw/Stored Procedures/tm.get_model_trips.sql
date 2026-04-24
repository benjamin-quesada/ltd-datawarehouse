SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   PROCEDURE [tm].[get_model_trips] as

/*
CREATED ON	: 20221020
CREATED BY	: B Eichberger
PURPOSE		: To build up a localized and prepared set of data for models related to Transit Master Trips
USE EXAMPLE	: exec tm.get_model_trips

------------------LTD_GLOSSARY---------------
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

drop table if exists #pac
drop table if exists #adh

declare @rdt int = (
	select min(rcd) from (
		select [dbo].[F_DATE_TO_CALENDAR_ID](max(record_created_date)) rcd from model.tm_trips
		union
		select max(calendar_id) from model.tm_trips
	) t )


select r.CALENDAR_ID
     , r.[TRIP_ID]
     , [GEO_NODE_ID]
into #adh
from [LTD-TMDATA].[tmdatamart].[dbo].[ADHERENCE_BY_STOP] r
    join [LTD-TMDATA].tmdatamart.dbo.TRIP                t
        on t.TRIP_ID = r.TRIP_ID
where r.CALENDAR_ID >= isnull(@rdt,120190901)
      and t.TRIP_END_TIME is not null
group by r.CALENDAR_ID
       , r.[TRIP_ID]
       , [GEO_NODE_ID];

select CALENDAR_ID
     , r.[TRIP_ID]
     , [GEO_NODE_ID]
into #pac
from [LTD-TMDATA].[tmdatamart].[dbo].PASSENGER_COUNT r
    join [LTD-TMDATA].tmdatamart.dbo.TRIP            t
        on t.TRIP_ID = r.TRIP_ID
where r.CALENDAR_ID >= isnull(@rdt,120190901)
      and t.TRIP_END_TIME is not null
group by r.CALENDAR_ID
       , r.[TRIP_ID]
       , [GEO_NODE_ID];

insert model.tm_trips (calendar_id,trip_id,geo_node_id,TRIP_CAL_STOP_KEY)
select i.CALENDAR_ID
     , i.TRIP_ID
     , i.GEO_NODE_ID
     , i.TRIP_CAL_STOP_KEY 
from (
select CALENDAR_ID
     , TRIP_ID
     , GEO_NODE_ID
     , TRIP_CAL_STOP_KEY = cast(CALENDAR_ID as varchar(32)) + right('000000' + cast([GEO_NODE_ID] as varchar(32)), 6)
                           + right('000000000000' + cast([TRIP_ID] as varchar(32)), 12)
from #adh
union
select CALENDAR_ID
     , TRIP_ID
     , GEO_NODE_ID
     , TRIP_CAL_STOP_KEY = cast(CALENDAR_ID as varchar(32)) + right('000000' + cast([GEO_NODE_ID] as varchar(32)), 6)
                           + right('000000000000' + cast([TRIP_ID] as varchar(32)), 12)
from #pac
) i
where not exists (select 1 from model.tm_trips where trip_id = i.TRIP_ID and CALENDAR_ID = i.CALENDAR_ID and GEO_NODE_ID = i.GEO_NODE_ID)

END TRY


BEGIN CATCH

       DECLARE @profile VARCHAR(255) = (
                    SELECT TOP(1) [NAME]
                    FROM msdb.dbo.sysmail_profile ORDER BY [NAME]
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
