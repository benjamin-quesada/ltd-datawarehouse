SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [apc].[get_apc_projection_source]
AS 

/*-----------LTD_GLOSSARY---------------
 CREATED BY :  B. Eichberger
 CREATED DT	:  20260707
 PURPOSE	:  collect and stage data to be used by R Scripts that project ridership
 USE		:  exec apc.get_apc_projections

*/

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

--- next step - make sproc
DROP TABLE IF EXISTS #dw_time
SELECT *
INTO #dw_time 
FROM reporting.tm.[DW_TIME]

DROP TABLE IF EXISTS [wrk].[apc_projection_stage]
CREATE TABLE [wrk].[apc_projection_stage](
	[CALENDAR_ID] [NUMERIC](10, 0) NOT NULL,
	[TIME_TABLE_VERSION_ID] [NUMERIC](5, 0) NOT NULL,
	[BLOCK_ID] [NUMERIC](10, 0) NULL,
	[ROUTE_ID] [INT] NULL,
	[ROUTE_DIRECTION_ID] [NUMERIC](5, 0) NULL,
	[GEO_NODE_ID] [NUMERIC](10, 0) NULL,
	[MESSAGE_TIME] [INT] NULL,
	[TRIP_ID] [INT] NOT NULL,
	[HH] [VARCHAR](2) NULL,
	[MM] [VARCHAR](2) NULL,
	[SS] [VARCHAR](2) NULL,
	[BOARD] [INT] NULL,
	[ALIGHT] [INT] NULL,
	[DEPARTURE_LOAD] [INT] NULL,
	[calendar_date] [DATETIME] NULL
) ON [PRIMARY]

-- All Vehicles route and stop counts,
DROP TABLE IF EXISTS #yearLoops 
SELECT rn = ROW_NUMBER() OVER (ORDER BY year), MIN(calendar_id) calendar_id,[Year] 
INTO #yearLoops
FROM [LTD-DW].Reporting.tm.DW_CALENDAR 
WHERE calendar_date >= CAST(DATEADD(YEAR, -2,GETDATE()) AS DATE) 
AND CALENDAR_ID LIKE '%0101'
GROUP BY [Year]
ORDER BY CALENDAR_ID


DECLARE @i INT = 1
DECLARE @r INT = (SELECT MAX(rn) FROM #yearLoops)
DECLARE @currYear INT
DECLARE @endBefore INT

WHILE @i <= @r
BEGIN

SELECT @currYear = (SELECT calendar_id FROM #yearLoops WHERE rn = @i)
SELECT @endBefore = @currYear + 1130

INSERT wrk.[apc_projection_stage] 
([CALENDAR_ID]
      ,[TIME_TABLE_VERSION_ID]
      ,[BLOCK_ID]
      ,[ROUTE_ID]
      ,[ROUTE_DIRECTION_ID]
      ,[GEO_NODE_ID]
      ,[MESSAGE_TIME]
      ,TRIP_ID
      ,[HH]
      ,[MM]
      ,[SS]
      ,[BOARD]
      ,[ALIGHT]
      ,[DEPARTURE_LOAD]
      ,[calendar_date])
select *, 
case when q.MESSAGE_TIME > 86399 then 
    dateadd(day, 1, [dbo].[F_CALENDAR_ID_TO_DATE](CALENDAR_ID))
    else [dbo].[F_CALENDAR_ID_TO_DATE](CALENDAR_ID) end 
calendar_date
from (    
select CALENDAR_ID
     , TIME_TABLE_VERSION_ID
     , BLOCK_ID
     , ROUTE_ID
     , ROUTE_DIRECTION_ID
     , GEO_NODE_ID
     , p.MESSAGE_TIME
     , p.TRIP_ID
     , d.HH
     , d.MM
     , d.SS
     , sum(BOARD) BOARD
     , sum(ALIGHT) ALIGHT
     , sum(DEPARTURE_LOAD) DEPARTURE_LOAD
from [ltd-tmdata].tmdatamart.dbo.PASSENGER_COUNT p
left join #dw_time d on d.spm = p.MESSAGE_TIME
where CALENDAR_ID between @currYear and @endBefore and TRIP_ID is not null and MESSAGE_TIME is not null AND p.TRIP_ID IS NOT NULL 
group by 
CALENDAR_ID
     , TIME_TABLE_VERSION_ID
     , BLOCK_ID
     , ROUTE_ID
     , ROUTE_DIRECTION_ID
     , GEO_NODE_ID
     , p.MESSAGE_TIME
     , p.TRIP_ID
     , d.HH
     , d.MM
     , d.SS
     ) q


select @i = @i + 1

if @i > @r
break
	else continue

end

drop table if exists [wrk].[apc_projection]
CREATE TABLE [wrk].[apc_projection](
	[CALENDAR_ID] [numeric](10, 0) NOT NULL,
	[TIME_TABLE_VERSION_ID] [numeric](5, 0) NOT NULL,
	[BLOCK_ID] [numeric](10, 0) NULL,
	[ROUTE_ID] [int] NULL,
	[ROUTE_DIRECTION_ID] [numeric](5, 0) NULL,
	[GEO_NODE_ID] [numeric](10, 0) NULL,
	[MESSAGE_TIME] [int] NULL,
	[TRIP_ID] [int] NOT NULL,
	[HH] [varchar](2) NULL,
	[MM] [varchar](2) NULL,
	[SS] [varchar](2) NULL,
	[BOARD] [int] NULL,
	[ALIGHT] [int] NULL,
	[DEPARTURE_LOAD] [int] NULL,
	[calendar_date] [date] NULL,
	[calendar_datetime] [datetime] NULL,
	[BLOCK_ABBR] [varchar](9) NOT NULL,
	[ROUTE_ABBR] [varchar](8) NOT NULL,
	[ROUTE_NAME] [varchar](75) NOT NULL,
	[ROUTE_DIRECTION_NAME] [varchar](15) NOT NULL,
	[rdir_abbr] [varchar](1) NULL,
	[GEO_NODE_ABBR] [varchar](8) NOT NULL,
	[GEO_NODE_NAME] [varchar](75) NOT NULL,
	[temp] [float] NULL,
	[clouds] [float] NULL,
	[visibility] [float] NULL,
	[wind_speed] [float] NULL,
	[isHoliday] [int] NOT NULL,
	[DayOfWeekNbr] [int] NULL,
	record_created_date datetime2 default sysdatetime() not null
) ON [PRIMARY]

INSERT wrk.[apc_projection]
(
	CALENDAR_ID
   ,TIME_TABLE_VERSION_ID
   ,BLOCK_ID
   ,ROUTE_ID
   ,ROUTE_DIRECTION_ID
   ,GEO_NODE_ID
   ,MESSAGE_TIME
   ,TRIP_ID
   ,HH
   ,MM
   ,SS
   ,BOARD
   ,ALIGHT
   ,DEPARTURE_LOAD
   ,calendar_date
   ,calendar_datetime
   ,BLOCK_ABBR
   ,ROUTE_ABBR
   ,ROUTE_NAME
   ,ROUTE_DIRECTION_NAME
   ,rdir_abbr
   ,GEO_NODE_ABBR
   ,GEO_NODE_NAME
   ,temp
   ,clouds
   ,visibility
   ,wind_speed
   ,isHoliday
   ,DayOfWeekNbr
)
select c.CALENDAR_ID
	  ,c.TIME_TABLE_VERSION_ID
	  ,c.BLOCK_ID
	  ,c.ROUTE_ID
	  ,c.ROUTE_DIRECTION_ID
	  ,c.GEO_NODE_ID
	  ,c.MESSAGE_TIME
      ,c.TRIP_ID
	  ,c.HH
	  ,c.MM
      ,c.SS
	  ,c.BOARD
	  ,c.ALIGHT
	  ,c.DEPARTURE_LOAD
	  ,calendar_date = CAST(c.calendar_date AS date)
      ,calendar_datetime = CAST(CAST(c.calendar_date AS date) AS VARCHAR(32)) + ' ' + c.HH + ':' + c.MM + ':' + c.SS
     , b.BLOCK_ABBR
     , r.ROUTE_ABBR
     , r.ROUTE_NAME
     , rd.ROUTE_DIRECTION_NAME
     , upper(left(rd.ROUTE_DIRECTION_NAME, 1)) rdir_abbr
     , g.GEO_NODE_ABBR
     , g.GEO_NODE_NAME
     , h.temp
     , h.clouds
     , h.visibility
     , h.wind_speed
     , a.isHoliday
     , a.DayOfWeekNbr
from ltd_dw.wrk.[apc_projection_stage] c
    join Reporting.tm.DW_CALENDAR a on a.CALENDAR_ID = c.CALENDAR_ID
    join [LTD-TMDATA].tmdatamart.dbo.ROUTE r on r.ROUTE_ID = c.ROUTE_ID
    join [LTD-TMDATA].tmdatamart.dbo.ROUTE_DIRECTION rd on rd.ROUTE_DIRECTION_ID = c.ROUTE_DIRECTION_ID
    join [LTD-TMDATA].tmdatamart.dbo.GEO_NODE g on g.GEO_NODE_ID = c.GEO_NODE_ID
    join [LTD-TMDATA].tmdatamart.dbo.BLOCK b on b.BLOCK_ID = c.BLOCK_ID
    left join
    (
        select calendar_id = [dbo].F_DATE_TO_CALENDAR_ID(cast(w.dt as date))
             , datepart(hour, w.dt) the_hour
             , avg(w.temp) temp
             , avg(w.clouds) clouds
             , avg(w.visibility) visibility
             , avg(w.wind_speed) wind_speed
        from [LTD-DW].ltd_dw.dbo.weather w
        group by [dbo].F_DATE_TO_CALENDAR_ID(cast(w.dt as date))
               , datepart(hour, w.dt)
    ) h on h.calendar_id = c.CALENDAR_ID
           and h.the_hour = c.HH
order by b.TIME_TABLE_VERSION_ID,r.ROUTE_ID,rd.ROUTE_DIRECTION_ID,calendar_date,c.HH,c.MM, ss
;


DROP TABLE if exists [wrk].[apc_projection_stage]
drop table if exists #yearLoops 
drop table if exists #dw_time



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
