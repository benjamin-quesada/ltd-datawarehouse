SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [geo].[get_trip_polygons]
AS
/*-----------LTD_GLOSSARY---------------
 created by	:  b. eichberger
 created dt	:  2025-10-14 
 purpose	:  get the polygon geography and geometry data from trips
			   sourced from adherence and fills missing data from last known load
 use		:  exec [geo].[get_trip_polygons]

----------------------------------*/

set nocount on

declare @SPROC varchar(100)
set @SPROC = object_schema_name(@@procid) + '.' + object_name(@@procid)

insert into DBA.[aud].[Object_Activity]
	([server_name], [database_name] ,[host_name], [System_User], [object_name]
	,[client_net_address], [local_net_address], [auth_Scheme], [last_read], [last_write]
	,[most_recent_sql_handle], [Timestamp], object_type)
select distinct @@servername, DB_NAME(),HOST_NAME(),SYSTEM_USER, @SPROC,
	client_net_address, local_net_address , auth_Scheme, last_read, last_write 
	,most_recent_sql_handle, CURRENT_TIMESTAMP AS [Timestamp], 'PROC'
FROM sys.dm_exec_connections 
WHERE session_id = @@SPID ;

BEGIN TRY

DECLARE @sdt DATETIME2 = SYSDATETIME()
DECLARE @outputTbl TABLE (actionNm VARCHAR(32));

set nocount on;
declare @maxdt date = (select isnull(max([dbo].[F_CALENDAR_ID_TO_DATE](calendar_id)),'1/1/2019') from geo.trip_polygons)
declare @startdt date = (select min(calendar_date) from tm.DW_CALENDAR C where c.CALENDAR_DATE >= dateadd(day,-15,@maxdt))
declare @enddt date = (select max(calendar_date) from tm.DW_CALENDAR where CALENDAR_date <= dateadd(day,60,@startdt))
declare @startcal Int = (select [dbo].[F_DATE_TO_CALENDAR_ID](@startdt))
declare @endcal int = (select [dbo].[F_DATE_TO_CALENDAR_ID](@enddt))
--select @startcal st, @endcal en

		drop table if exists #templats
		select rn = row_number() over (order by s.CALENDAR_ID, s.TRIP_ID,s.TIME_TABLE_VERSION_ID, s.MESSAGE_TIME)
		, triprn = row_number() over (partition by s.CALENDAR_ID, s.TRIP_ID,s.TIME_TABLE_VERSION_ID order by s.CALENDAR_ID, s.TRIP_ID, s.MESSAGE_TIME)
		, s.MESSAGE_TIME, s.CALENDAR_ID,s.TIME_TABLE_VERSION_ID, s.BLOCK_ID, s.TRIP_ID, g.GEO_NODE_ID
		, cast(g.LATITUDE/10000000.0 as varchar(32)) lat, cast(g.LONGITUDE/10000000.0 as varchar(32)) lon
		into #templats
		from [LTD-TMDATA].tmdatamart.dbo.ADHERENCE s
		join [LTD-TMDATA].tmdatamart.dbo.GEO_NODE g on g.GEO_NODE_ID = s.GEO_NODE_ID
		where s.CALENDAR_ID >= @startcal
			and s.CALENDAR_ID <= @endcal
			and s.MESSAGE_TIME is not null 
			and g.LATITUDE is not null 
			and g.LONGITUDE is not null 
			and g.LATITUDE <> 0 
			and g.LONGITUDE <> 0
			and s.TRIP_ID is not null 
		order by s.CALENDAR_ID,lon,lat

--SELECT * FROM #templats order by rn, triprn

drop table if exists #qualifiedrows
	select CALENDAR_ID,trip_id, max(triprn) maxrows
	into #qualifiedrows
	from #templats group by CALENDAR_ID,trip_id having max(triprn) >= 3

--SELECT * FROM #qualifiedrows

		drop table if exists #preplats
		select v.triprn
             , v.MESSAGE_TIME
             , v.CALENDAR_ID
			 , v.TIME_TABLE_VERSION_ID
			 , v.BLOCK_ID
             , v.TRIP_ID
             , v.lat
             , v.lon 
			 into #preplats from (
		select t.triprn
             , t.MESSAGE_TIME
             , t.CALENDAR_ID
			 , t.TIME_TABLE_VERSION_ID
			 , t.BLOCK_ID
             , t.TRIP_ID
             , t.lat
             , t.lon
             from  #templats t
		join #qualifiedrows q on q.CALENDAR_ID = t.CALENDAR_ID
					and q.TRIP_ID = t.TRIP_ID

		union
		select triprn = 99999
             , t.MESSAGE_TIME
             , t.CALENDAR_ID
			 , t.TIME_TABLE_VERSION_ID
			 , t.BLOCK_ID
             , t.TRIP_ID
             , lat
             , lon from  #templats t
			 join #qualifiedrows q on q.CALENDAR_ID = t.CALENDAR_ID
					and q.TRIP_ID = t.TRIP_ID
					where t.triprn = 1 
	)	v

--SELECT * FROM #preplats order by CALENDAR_ID,trip_id,triprn,MESSAGE_TIME

drop table if exists #polys 
select p.CALENDAR_ID
,p.TIME_TABLE_VERSION_ID
,P.BLOCK_ID
     , p.TRIP_ID
	 , p.MESSAGE_TIME
     , polylat = 'POLYGON (( '+p.loc + '))'
	 into #polys -- select * 
	 from (
		SELECT t2.CALENDAR_ID,TIME_TABLE_VERSION_ID, t2.TRIP_ID,BLOCK_ID, t2.MESSAGE_TIME, loc = STUFF(
             (SELECT ', ' + lonlat 
              FROM (SELECT distinct triprn
				  ,CALENDAR_ID,TIME_TABLE_VERSION_ID,BLOCK_ID
                  , TRIP_ID
				  , message_time
                  , cast(lon as varchar(32)) +' '+ cast(lat as varchar(32)) lonlat
				 from #preplats ) t1
              WHERE t1.CALENDAR_ID= t2.CALENDAR_ID and t1.TRIP_ID = t2.TRIP_ID
              FOR XML PATH (''))
             , 1, 1, '') from (SELECT distinct triprn
				  ,CALENDAR_ID,TIME_TABLE_VERSION_ID,block_id
                  , TRIP_ID
				  , message_time
                  , cast(lon as varchar(32)) +' '+ cast(lat as varchar(32)) lonlat
				 from #preplats ) t2
group by t2.CALENDAR_ID, t2.trip_id, t2.TIME_TABLE_VERSION_ID, t2.BLOCK_ID, t2.MESSAGE_TIME) p;


insert [geo].[trip_polygons]
(
    CALENDAR_ID
  , TIME_TABLE_VERSION_ID
  , BLOCK_ID
  , TRIP_ID
  , polywkt
  , polygeog
)
OUTPUT 'INSERT' INTO @outputTbl(actionNm)
select y.CALENDAR_ID
     , y.TIME_TABLE_VERSION_ID
     , y.BLOCK_ID
     , y.TRIP_ID
     , y.polylat
     , polygeog = geography::STPolyFromText(y.polylat, 4326)
from #polys y 
where not exists (select 1 from [geo].[trip_polygons]
					where  CALENDAR_ID = y.CALENDAR_ID
				  AND TIME_TABLE_VERSION_ID = y.TIME_TABLE_VERSION_ID
				  AND BLOCK_ID = y.BLOCK_ID
				  AND TRIP_ID = y.TRIP_ID
				  AND polywkt = y.polylat) 
and geometry::STGeomFromText(y.polylat,0).STIsValid() = 1				  ;


				  
DECLARE @ins INT = (SELECT COUNT(*) FROM @outputTbl ) --WHERE actionNm = 'INSERT'
--DECLARE @upd INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'UPDATE')
--DECLARE @del INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'DELETE')
DECLARE @prg varchar(90) = @@SERVERNAME + '.ltd_dw.geo.get_trip_polygons'

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
select 'GEOP',
'ltd_dw.geo.trip_polygons',
'TM',
@prg,
isnull(@ins,0) ,0,0,
@sdt,
sysdatetime()


DROP TABLE IF EXISTS #polys
DROP TABLE IF EXISTS #preplats
DROP TABLE IF EXISTS #qualifiedrows
DROP TABLE IF EXISTS #templats


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
