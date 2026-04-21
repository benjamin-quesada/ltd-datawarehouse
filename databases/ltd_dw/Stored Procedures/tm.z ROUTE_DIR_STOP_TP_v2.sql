SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [tm].[z ROUTE_DIR_STOP_TP_v2]
AS

/***********************************
CREATED ON: 20221229
CREATED BY: B. Eichberger
PURPOSE   : To populate a table that can be used in TM_MODEL
			This is a cross reference table
			select * from model.ROUTE_DIR_STOP_TP

exec tm.ROUTE_DIR_STOP_TP_v2 -- 304446
************************************/
SET NOCOUNT ON;

  DECLARE @SPROC VARCHAR(100)
  SET @SPROC = OBJECT_SCHEMA_NAME(@@PROCID) + '.' + OBJECT_NAME(@@PROCID)


BEGIN TRY

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
	[RTE_DIR_STOP_KEY] [VARCHAR](30) NULL,
	[STOP_LATITUDE] [NUMERIC](21, 9) NULL,
	[STOP_LONGITUDE] [NUMERIC](21, 9) NULL,
	[TIME_POINT_ABBR] [VARCHAR](8) NULL,
	[TIME_PT_NAME] [VARCHAR](50) NULL,
	[significant_tp] [NVARCHAR](4) NOT NULL
) ON [PRIMARY]



INSERT #allMain
(ROUTE_ID, ROUTE_DIRECTION_ID, GEO_NODE_ID, ROUTE_ABBR, ROUTE_NAME, STOP_ABBR, ROUTE_DIRECTION_ABBR, ROUTE_DIRECTION_NAME, ROUTE_DIR, STOP_NAME, RTE_DIR_STOP_KEY, STOP_LATITUDE, STOP_LONGITUDE, TIME_POINT_ABBR, TIME_PT_NAME, significant_tp)
SELECT 	ROUTE_ID
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
,	STOP_LATITUDE
,	STOP_LONGITUDE
,	TIME_POINT_ABBR
,	TIME_PT_NAME
,	significant_tp
FROM OPENQUERY([LTD-TMDATA],'
	SELECT	f.ROUTE_ID
		   ,f.ROUTE_DIRECTION_ID
		   ,f.GEO_NODE_ID
		   ,r.ROUTE_ABBR
		   ,left(r.ROUTE_NAME,75) ROUTE_NAME
		   ,LEFT(g.GEO_NODE_ABBR,75) STOP_ABBR
		   ,ROUTE_DIRECTION_ABBR
		   ,rd.ROUTE_DIRECTION_NAME
		   ,UPPER(LEFT(ROUTE_DIRECTION_NAME, 1)) ROUTE_DIR
		   ,LEFT(g.GEO_NODE_NAME,75) STOP_NAME
		   ,RIGHT(''000000'' + CAST(f.[ROUTE_ID] AS VARCHAR(32)), 6) + RIGHT(''000000'' + CAST(f.[ROUTE_DIRECTION_ID] AS VARCHAR(32)), 6) + RIGHT(''000000'' + CAST(f.[GEO_NODE_ID] AS VARCHAR(32)), 6) AS RTE_DIR_STOP_KEY
		   ,g.LATITUDE / 10000000 [STOP_LATITUDE]
		   ,g.LONGITUDE / 10000000 [STOP_LONGITUDE]
		   ,p.TIME_POINT_ABBR
		   ,p.TIME_PT_NAME
		   ,ISNULL(t.significant, ''n'') significant_tp
	FROM	tmmain.dbo.TRIP_GEO_NODE_XREF f WITH (NOLOCK)
	INNER JOIN tmmain.dbo.[ROUTE] r WITH (NOLOCK) ON r.ROUTE_ID = f.ROUTE_ID
	INNER JOIN tmmain.dbo.GEO_NODE g WITH (NOLOCK)ON g.GEO_NODE_ID = f.GEO_NODE_ID
	INNER JOIN tmmain.dbo.ROUTE_DIRECTION rd WITH (NOLOCK) ON rd.ROUTE_DIRECTION_ID = f.ROUTE_DIRECTION_ID
	LEFT JOIN tmmain.dbo.TIME_POINT p WITH (NOLOCK) ON p.TIME_POINT_ID = g.GEO_NODE_ID
	LEFT JOIN ltd_db.dbo.ltd_significant_tps_from_tmmain t ON t.tp = g.GEO_NODE_ABBR  AND r.ROUTE_ABBR = t.[route] AND LEFT(UPPER(rd.ROUTE_DIRECTION_ABBR), 1) = t.direction
	WHERE 1=1
	AND	f.ROUTE_ID IS NOT NULL
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
			,RIGHT(''000000'' + CAST(f.[ROUTE_ID] AS VARCHAR(32)), 6) + RIGHT(''000000'' + CAST(f.[ROUTE_DIRECTION_ID] AS VARCHAR(32)), 6) + RIGHT(''000000'' + CAST(f.[GEO_NODE_ID] AS VARCHAR(32)), 6)
			,g.LATITUDE / 10000000
			,g.LONGITUDE / 10000000
			,p.TIME_POINT_ABBR
			,p.TIME_PT_NAME
			,t.significant')

--select * from #allMain WHERE ROUTE_ID = 6042 ORDER BY route_id

DROP TABLE IF EXISTS -- select * from 
#routelist
CREATE TABLE #routelist (rn INT IDENTITY(1,1), route_id INT)
CREATE INDEX ix_route_id ON #routelist (route_id)			

INSERT #routelist (route_id)
SELECT z2.route_id
FROM (
SELECT	x.ROUTE_ID
FROM #allMain x
LEFT JOIN model.ROUTE_DIR_STOP_TP t ON t.ROUTE_ID = x.ROUTE_ID AND	t.ROUTE_DIRECTION_ID = x.ROUTE_DIRECTION_ID AND t.GEO_NODE_ID = x.GEO_NODE_ID
WHERE	t.ROUTE_ID IS NULL AND x.ROUTE_ID IS NOT NULL
 ) z2
 GROUP BY route_id
 ORDER BY route_id

--SELECT rn,route_id FROM #routelist ORDER by route_id

DECLARE @currRoute INT
DECLARE @i INT = 1
DECLARE @r INT = (SELECT MAX(rn) FROM #routelist)

WHILE @i <= @r

BEGIN

SELECT @currRoute = (SELECT route_id FROM #routelist WHERE rn = @i)
DELETE FROM model.ROUTE_DIR_STOP_TP WHERE ROUTE_ID = @currRoute

INSERT INTO model.ROUTE_DIR_STOP_TP (
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
,STOP_LATITUDE
,STOP_LONGITUDE
,TIME_POINT_ABBR
,TIME_PT_NAME
,significant_tp
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
,STOP_LATITUDE
,STOP_LONGITUDE
,TIME_POINT_ABBR
,TIME_PT_NAME
,significant_tp FROM (
	SELECT  ROUTE_ID
	,ROUTE_DIRECTION_ID
	,GEO_NODE_ID
	,ROUTE_ABBR
	,ROUTE_NAME
	,r.STOP_ABBR
	,ROUTE_DIRECTION_ABBR
	,ROUTE_DIRECTION_NAME
	,ROUTE_DIR
	,STOP_NAME
	,RTE_DIR_STOP_KEY
	,STOP_LATITUDE
	,STOP_LONGITUDE
	,TIME_POINT_ABBR
	,TIME_PT_NAME
	,significant_tp 
FROM #allMain r 
WHERE NOT EXISTS (
		SELECT 1 FROM model.ROUTE_DIR_STOP_TP
			WHERE ROUTE_ID = r.ROUTE_ID	
			AND	ROUTE_DIRECTION_ID = r.ROUTE_DIRECTION_ID	
			AND	GEO_NODE_ID = r.GEO_NODE_ID ) ) d
	OPTION (MAXDOP 2)

SELECT @i = @i + 1

IF @i > @r
BREAK
ELSE CONTINUE


END


UPDATE r 
SET significant_tp = 'y' 
-- select *
FROM model.[ROUTE_DIR_STOP_TP] r
INNER JOIN [LTD-TMDATA].ltd_db.dbo.ltd_significant_tps_from_tmmain m 
ON m.route = r.route_abbr
AND m.dir = r.[ROUTE_DIR] 
AND m.tp = r.TIME_POINT_ABBR
WHERE m.significant = 'y' AND r.[significant_tp] = 'n'


UPDATE r 
SET significant_tp = 'n' 
-- select *
FROM model.[ROUTE_DIR_STOP_TP] r
LEFT JOIN [LTD-TMDATA].ltd_db.dbo.ltd_significant_tps_from_tmmain m 
ON m.route = r.route_abbr
AND m.dir = r.[ROUTE_DIR] 
AND m.tp = r.TIME_POINT_ABBR
WHERE m.significant IS null AND r.[significant_tp] = 'y'



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
