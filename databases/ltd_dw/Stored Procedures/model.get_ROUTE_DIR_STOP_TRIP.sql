SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [model].[get_ROUTE_DIR_STOP_TRIP]
as

/***********************
CREATED ON	: 20251210
CREATED BY	: B. Eichberger
PURPOSE		: To populate DW model.ROUTE_DIR_STOP_TRIP correcting problem with having tried
			  to tie time points to this data; not possible. timepoints need to be discerned
			  from adherence data. Removing previous iterations of this data.

USE			: exec model.[get_ROUTE_DIR_STOP_TRIP
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

begin try

DROP TABLE IF EXISTS -- select * from 
#allMain

-- delete from 
CREATE TABLE #allMain(
	[ROUTE_ID] [INT] NULL,
	[ROUTE_DIRECTION_ID] [NUMERIC](5, 0) NULL,
	[GEO_NODE_ID] [NUMERIC](10, 0) NULL,
	[ROUTE_ABBR] [VARCHAR](8) NOT NULL,
	[ROUTE_NAME] [VARCHAR](75) NOT NULL,
	[STOP_ABBR] [VARCHAR](8) NOT NULL,
	[ROUTE_DIRECTION_ABBR] [VARCHAR](3) NULL,
	[ROUTE_DIRECTION_NAME] [VARCHAR](15) NOT NULL,
	[ROUTE_DIR] [VARCHAR](1) NULL,
	[STOP_NAME] [VARCHAR](75) NOT NULL,
	[RTE_DIR_STOP_KEY] VARCHAR(42) NULL,
	[ROUTE_DIR_STOP_TRIP_KEY] VARCHAR(90) NULL,
	[TRIP_END_TIME] VARCHAR(32) NULL,
	TIME_TABLE_VERSION_ID INT NULL,
	[STOP_LATITUDE] [NUMERIC](21, 9) NULL,
	[STOP_LONGITUDE] [NUMERIC](21, 9) NULL,
) ON [PRIMARY]



insert #allMain
(ROUTE_ID, ROUTE_DIRECTION_ID, GEO_NODE_ID, ROUTE_ABBR, ROUTE_NAME, STOP_ABBR, ROUTE_DIRECTION_ABBR
, ROUTE_DIRECTION_NAME, ROUTE_DIR, STOP_NAME
, RTE_DIR_STOP_KEY, ROUTE_DIR_STOP_TRIP_KEY, TRIP_END_TIME
, TIME_TABLE_VERSION_ID
, STOP_LATITUDE, STOP_LONGITUDE
)
select 	ROUTE_ID
,	ROUTE_DIRECTION_ID
,	GEO_NODE_ID
,	ROUTE_ABBR
,	ROUTE_NAME
,	STOP_ABBR
,	ROUTE_DIRECTION_ABBR
,	ROUTE_DIRECTION_NAME
,	ROUTE_DIR
,	STOP_NAME
,	RTE_DIR_STOP_KEY
,	ROUTE_DIR_STOP_TRIP_KEY
,	TRIP_END_TIME
,	TIME_TABLE_VERSION_ID
,	STOP_LATITUDE
,	STOP_LONGITUDE
FROM OPENQUERY([LTD-TMDATA],

	'SELECT	f.ROUTE_ID
		   ,f.ROUTE_DIRECTION_ID
		   ,f.GEO_NODE_ID
		   ,r.ROUTE_ABBR
		   ,left(r.ROUTE_NAME,75) ROUTE_NAME
		   ,LEFT(g.GEO_NODE_ABBR,75) STOP_ABBR
		   ,ROUTE_DIRECTION_ABBR
		   ,rd.ROUTE_DIRECTION_NAME
		   ,UPPER(LEFT(ROUTE_DIRECTION_NAME, 1)) ROUTE_DIR
		   ,LEFT(g.GEO_NODE_NAME,75) STOP_NAME
		   ,RIGHT(''000000'' + CAST(f.[ROUTE_ID] AS VARCHAR(32)), 6) 
				  + RIGHT(''000000'' + CAST(f.[ROUTE_DIRECTION_ID] AS VARCHAR(32)), 6) 
				  + RIGHT(''000000'' + CAST(f.[GEO_NODE_ID] AS VARCHAR(32)), 6) AS RTE_DIR_STOP_KEY
		   ,RIGHT(''000000''+ CAST(f.[ROUTE_ID] AS VARCHAR(32)),6)
				  + RIGHT(''000000''+ CAST(f.[ROUTE_DIRECTION_ID] AS VARCHAR(32)),6)
				  + RIGHT(''000000''+ CAST(f.[geo_node_id] AS VARCHAR(32)),6)
				  + RIGHT(''0000000000''+ CAST(f.TRIP_ID AS VARCHAR(32)),10) AS ROUTE_DIR_STOP_TRIP_KEY
		   ,cast(replace(str(ti.TRIP_END_TIME/3600,2,0),'' '',''0'') as varchar)
            + '':'' + cast(replace(str(ti.TRIP_END_TIME%3600/60,2,0),'' '',''0'') as varchar) TRIP_END_TIME
		   ,f.TIME_TABLE_VERSION_ID
	       ,g.LATITUDE / 10000000.0 [STOP_LATITUDE]
		   ,g.LONGITUDE / 10000000.0 [STOP_LONGITUDE]	
	FROM	tmmain.dbo.TRIP_GEO_NODE_XREF f WITH (NOLOCK)
	INNER JOIN tmmain.dbo.TRIP ti on ti.trip_id = f.trip_id 
	INNER JOIN tmmain.dbo.TIME_TABLE_VERSION ttv on ttv.time_table_version_id = f.time_table_version_id 
	INNER JOIN tmmain.dbo.[ROUTE] r WITH (NOLOCK) ON r.ROUTE_ID = f.ROUTE_ID
	INNER JOIN tmmain.dbo.GEO_NODE g WITH (NOLOCK)ON g.GEO_NODE_ID = f.GEO_NODE_ID
	INNER JOIN tmmain.dbo.ROUTE_DIRECTION rd WITH (NOLOCK) ON rd.ROUTE_DIRECTION_ID = f.ROUTE_DIRECTION_ID
	WHERE 1=1
	AND ttv.activation_date >= ''1/1/2018'' 
	AND	f.ROUTE_ID IS NOT NULL
	and f.TRIP_ID IS NOT NULL
	GROUP BY f.ROUTE_ID
			,f.ROUTE_DIRECTION_ID
			,f.GEO_NODE_ID
			,r.ROUTE_ABBR
			,r.ROUTE_NAME
			,g.GEO_NODE_ABBR
			,ROUTE_DIRECTION_ABBR
			,rd.ROUTE_DIRECTION_NAME
			,UPPER(LEFT(ROUTE_DIRECTION_NAME, 1))
			,g.GEO_NODE_NAME
			,f.TRIP_ID
			,RIGHT(''000000'' + CAST(f.[ROUTE_ID] AS VARCHAR(32)), 6) 
				  + RIGHT(''000000'' + CAST(f.[ROUTE_DIRECTION_ID] AS VARCHAR(32)), 6) 
				  + RIGHT(''000000'' + CAST(f.[GEO_NODE_ID] AS VARCHAR(32)), 6)
			,RIGHT(''000000''+ CAST(f.[ROUTE_ID] AS VARCHAR(32)),6)
				  + RIGHT(''000000''+ CAST(f.[ROUTE_DIRECTION_ID] AS VARCHAR(32)),6)
				  + RIGHT(''000000''+ CAST(f.[geo_node_id] AS VARCHAR(32)),6)
				  + RIGHT(''0000000000''+ CAST(f.TRIP_ID AS VARCHAR(32)),10)
			,ti.TRIP_END_TIME
			,f.TIME_TABLE_VERSION_ID
			,g.LATITUDE / 10000000.0
			,g.LONGITUDE / 10000000.0
			
')

CREATE INDEX temp_index_5380 ON #allMain ([ROUTE_ID], [TRIP_END_TIME]) 
INCLUDE ([ROUTE_DIRECTION_ID], [GEO_NODE_ID], [ROUTE_ABBR], [ROUTE_NAME], [STOP_ABBR], [ROUTE_DIRECTION_ABBR]
, [ROUTE_DIRECTION_NAME], [ROUTE_DIR], [STOP_NAME], [RTE_DIR_STOP_KEY], [ROUTE_DIR_STOP_TRIP_KEY]
, [STOP_LATITUDE], [STOP_LONGITUDE])	

 CREATE INDEX temp_index_5355 ON #allMain ([ROUTE_ID]) INCLUDE ([ROUTE_DIRECTION_ID], [GEO_NODE_ID]
 , [ROUTE_ABBR], [ROUTE_NAME], [STOP_ABBR], [ROUTE_DIRECTION_ABBR], [ROUTE_DIRECTION_NAME], [ROUTE_DIR]
 , [STOP_NAME], [RTE_DIR_STOP_KEY], [STOP_LATITUDE], [STOP_LONGITUDE])	


DROP TABLE IF EXISTS -- select * from 
#routetriplist
CREATE TABLE #routetriplist (rn INT IDENTITY(1,1), route_id INT, trip_end_time VARCHAR(32))
CREATE INDEX ix_route_id ON #routetriplist (route_id,trip_end_time)			

INSERT #routetriplist (route_id,trip_end_time)
SELECT z2.route_id, trip_end_time
FROM (
SELECT	x.ROUTE_ID, x.TRIP_END_TIME
FROM #allMain x
LEFT JOIN -- select * from 
model.ROUTE_DIR_STOP_TRIP t ON t.ROUTE_ID = x.ROUTE_ID AND	t.ROUTE_DIRECTION_ID = x.ROUTE_DIRECTION_ID AND t.GEO_NODE_ID = x.GEO_NODE_ID AND t.TRIP_END_TIME = x.TRIP_END_TIME
WHERE	t.ROUTE_ID IS NULL AND x.ROUTE_ID IS NOT NULL
GROUP BY x.ROUTE_ID, x.TRIP_END_TIME
) z2
 GROUP BY route_id,z2.TRIP_END_TIME
 ORDER BY route_id,z2.TRIP_END_TIME


CREATE INDEX temp_index_5383 ON #routetriplist ([rn]) INCLUDE ([route_id])	
CREATE INDEX temp_index_5385 ON #routetriplist ([rn]) INCLUDE ([trip_end_time])	


DECLARE @currRoute2 INT
DECLARE @currTrip2 VARCHAR(32)
DECLARE @i2 INT = 1
DECLARE @r2 INT = (SELECT COUNT(*) FROM #routetriplist)

WHILE @i2 <= @r2

BEGIN

SELECT @currRoute2 = (SELECT route_id FROM #routetriplist WHERE rn = @i2)
SELECT @currTrip2 = (SELECT trip_end_time FROM #routetriplist WHERE rn = @i2)


INSERT INTO -- truncate table 
model.ROUTE_DIR_STOP_TRIP (
 ROUTE_ID
,ROUTE_DIRECTION_ID
,GEO_NODE_ID
,ROUTE_ABBR
,ROUTE_NAME
,STOP_ABBR
,ROUTE_DIRECTION_ABBR
,ROUTE_DIRECTION_NAME
,ROUTE_DIR
,STOP_NAME
,RTE_DIR_STOP_KEY
,ROUTE_DIR_STOP_TRIP_KEY
,TRIP_END_TIME
,STOP_LATITUDE
,STOP_LONGITUDE
)
SELECT ROUTE_ID
,ROUTE_DIRECTION_ID
,GEO_NODE_ID
,LEFT(ROUTE_ABBR,8) ROUTE_ABBR
,LEFT(ROUTE_NAME,75) ROUTE_NAME
,LEFT(STOP_ABBR,8) STOP_ABBR
,ROUTE_DIRECTION_ABBR
,LEFT(ROUTE_DIRECTION_NAME,75)
,ROUTE_DIR
,STOP_NAME
,RTE_DIR_STOP_KEY
,d.ROUTE_DIR_STOP_TRIP_KEY
,d.TRIP_END_TIME
,STOP_LATITUDE
,STOP_LONGITUDE
	from (
		SELECT r.ROUTE_ID,
               r.ROUTE_DIRECTION_ID,
               r.GEO_NODE_ID,
               r.ROUTE_ABBR,
               r.ROUTE_NAME,
               r.STOP_ABBR,
               r.ROUTE_DIRECTION_ABBR,
               r.ROUTE_DIRECTION_NAME,
               r.ROUTE_DIR,
               r.STOP_NAME,
               r.RTE_DIR_STOP_KEY,
               r.ROUTE_DIR_STOP_TRIP_KEY,
               r.TRIP_END_TIME,
               r.STOP_LATITUDE,
               r.STOP_LONGITUDE
		FROM #allMain r 
		WHERE NOT EXISTS (
				SELECT 1 FROM model.ROUTE_DIR_STOP_TRIP
					WHERE ROUTE_ID = r.ROUTE_ID	
					AND	ROUTE_DIRECTION_ID = r.ROUTE_DIRECTION_ID	
					AND	GEO_NODE_ID = r.GEO_NODE_ID 
					AND TRIP_END_TIME = r.TRIP_END_TIME ) 
		AND r.ROUTE_ID = @currRoute2 AND r.TRIP_END_TIME = @currTrip2
		) d
GROUP BY 
ROUTE_ID
,ROUTE_DIRECTION_ID
,GEO_NODE_ID
,LEFT(ROUTE_ABBR,8) 
,LEFT(ROUTE_NAME,75) 
,LEFT(STOP_ABBR,8) 
,ROUTE_DIRECTION_ABBR
,LEFT(ROUTE_DIRECTION_NAME,75)
,ROUTE_DIR
,STOP_NAME
,RTE_DIR_STOP_KEY
,ROUTE_DIR_STOP_TRIP_KEY
,TRIP_END_TIME
,STOP_LATITUDE
,STOP_LONGITUDE
	OPTION (MAXDOP 2)

SELECT @i2 = @i2 + 1

IF @i2 > @r2
BREAK
ELSE CONTINUE


END


DROP TABLE IF EXISTS #allMain
DROP TABLE IF EXISTS #routelist
DROP TABLE IF EXISTS #routetriplist

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
