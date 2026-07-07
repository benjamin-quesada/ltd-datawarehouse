SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [tm].[z ROUTE_DIR_STOP_TP]
AS

/***********************************
CREATED ON: 20221201
CREATED BY: B. Eichberger
PURPOSE   : To populate a table that can be used in TM_MODEL
			This is a cross reference table
			select * from model.ROUTE_DIR_STOP_TP

exec tm.ROUTE_DIR_STOP_TP -- 304446
************************************/
SET NOCOUNT ON;

  DECLARE @SPROC VARCHAR(100)
  SET @SPROC = OBJECT_SCHEMA_NAME(@@PROCID) + '.' + OBJECT_NAME(@@PROCID)


BEGIN TRY

DROP TABLE IF EXISTS #routelist
CREATE TABLE #routelist (rn INT IDENTITY(1,1), route_id INT)
CREATE INDEX ix_route_id ON #routelist (route_id)
INSERT #routelist (route_id)
SELECT z.route_id
FROM (
SELECT Q.route_id --, Q.ROUTE_DIRECTION_ID, Q.GEO_NODE_ID
FROM (
  SELECT route_id,ROUTE_DIRECTION_ID,GEO_NODE_ID FROM [ltd-tmdata].tmdatamart.dbo.ADHERENCE 
		WHERE calendar_id >= 120170701 GROUP BY route_id,ROUTE_DIRECTION_ID,GEO_NODE_ID
  ) Q
LEFT JOIN model.ROUTE_DIR_STOP_TP t ON t.route_id = q.ROUTE_ID	
			AND t.ROUTE_DIRECTION_ID = q.ROUTE_DIRECTION_ID
			AND t.GEO_NODE_ID = q.GEO_NODE_ID
WHERE t.route_id IS NULL AND q.route_id IS NOT NULL
GROUP BY Q.route_id
) z

UPDATE STATISTICS #routelist
INSERT #routelist (route_id)
SELECT z3.route_id
FROM (
SELECT q2.route_id --, Q.ROUTE_DIRECTION_ID, Q.GEO_NODE_ID
FROM (
  SELECT route_id,ROUTE_DIRECTION_ID,GEO_NODE_ID FROM [ltd-tmdata].tmdatamart.dbo.ADHERENCE_BY_STOP WHERE calendar_id >= 120170701 GROUP BY route_id,ROUTE_DIRECTION_ID,GEO_NODE_ID
  ) q2
LEFT JOIN model.ROUTE_DIR_STOP_TP t ON t.route_id = q2.ROUTE_ID	
			AND t.ROUTE_DIRECTION_ID = q2.ROUTE_DIRECTION_ID
			AND t.GEO_NODE_ID = q2.GEO_NODE_ID
WHERE t.route_id IS NULL AND q2.route_id IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM #routelist WHERE route_id = q2.route_id)
GROUP BY q2.route_id
) z3


UPDATE STATISTICS #routelist
INSERT #routelist (route_id)
SELECT z1.route_id
FROM (
SELECT e.route_id --, Q.ROUTE_DIRECTION_ID, Q.GEO_NODE_ID
FROM (
  SELECT route_id,ROUTE_DIRECTION_ID,GEO_NODE_ID FROM [ltd-tmdata].tmdatamart.dbo.PASSENGER_COUNT WHERE calendar_id >= 120170701 GROUP BY route_id,ROUTE_DIRECTION_ID,GEO_NODE_ID
  ) e
LEFT JOIN model.ROUTE_DIR_STOP_TP t ON t.route_id = e.ROUTE_ID	
			AND t.ROUTE_DIRECTION_ID = e.ROUTE_DIRECTION_ID
			AND t.GEO_NODE_ID = e.GEO_NODE_ID
WHERE t.ROUTE_ID IS NULL AND e.route_id IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM #routelist WHERE route_id = e.route_id)
GROUP BY e.route_id
) z1


UPDATE STATISTICS #routelist
INSERT #routelist (route_id)
SELECT z2.route_id
FROM (
SELECT x.route_id --, Q.ROUTE_DIRECTION_ID, Q.GEO_NODE_ID
FROM (
  SELECT tgn.ROUTE_ID,rd.ROUTE_DIRECTION_ID,g.GEO_NODE_ID
	FROM [LTD-TMDATA].tmmain.dbo.trip_geo_node_xref  tgn WITH (NOLOCK)
	 INNER JOIN [LTD-TMDATA].tmmain.dbo.[route]             r WITH (NOLOCK)  ON r.route_id                = tgn.route_id 
	 INNER JOIN [LTD-TMDATA].tmmain.dbo.geo_node            g WITH (NOLOCK)  ON g.geo_node_id             = tgn.geo_node_id
	 INNER JOIN [LTD-TMDATA].tmmain.dbo.ROUTE_DIRECTION	  rd WITH (NOLOCK)  ON rd.ROUTE_DIRECTION_ID = tgn.ROUTE_DIRECTION_ID
	 LEFT JOIN [LTD-TMDATA].tmmain.dbo.TIME_POINT		   p WITH (NOLOCK)	ON p.TIME_POINT_ID = g.GEO_NODE_ID
	 LEFT join [LTD-TMDATA].ltd_db.dbo.ltd_significant_tps_from_tmmain t on t.tp = g.GEO_NODE_ABBR and r.ROUTE_ABBR = t.[route] 
				AND left(upper(rd.ROUTE_DIRECTION_ABBR),1) = t.direction
	group by tgn.route_id,rd.ROUTE_DIRECTION_ID,g.GEO_NODE_ID) x
LEFT JOIN model.ROUTE_DIR_STOP_TP t ON t.route_id = x.ROUTE_ID	
			AND t.ROUTE_DIRECTION_ID = x.ROUTE_DIRECTION_ID
			AND t.GEO_NODE_ID = x.GEO_NODE_ID
WHERE t.ROUTE_ID IS NULL AND x.route_id IS NOT null
AND NOT EXISTS (SELECT 1 FROM #routelist WHERE route_id = x.route_id)
GROUP BY x.route_id
) z2


UPDATE STATISTICS #routelist

--SELECT rn,route_id FROM #routelist ORDER by route_id

DECLARE @currRoute INT
DECLARE @i INT = 1
DECLARE @r INT = (SELECT MAX(rn) FROM #routelist)

WHILE @i <= @r

BEGIN

SELECT @currRoute = (SELECT route_id FROM #routelist WHERE rn = @i)


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
,significant_tp FROM (
SELECT  a.ROUTE_ID, a.ROUTE_DIRECTION_ID,a.GEO_NODE_ID
,r.ROUTE_ABBR, r.ROUTE_NAME, g.GEO_NODE_ABBR STOP_ABBR
,ROUTE_DIRECTION_ABBR, ROUTE_DIRECTION_NAME, UPPER(LEFT(ROUTE_DIRECTION_NAME,1)) ROUTE_DIR
, g.GEO_NODE_NAME STOP_NAME,
RIGHT('000000'+ CAST(a.[ROUTE_ID] AS VARCHAR(32)),6)
      + RIGHT('000000'+ CAST(a.[ROUTE_DIRECTION_ID] AS VARCHAR(32)),6)
      + RIGHT('000000'+ CAST(a.[geo_node_id] AS VARCHAR(32)),6) as RTE_DIR_STOP_KEY
	  ,g.latitude/10000000 [STOP_LATITUDE]
	  ,g.longitude/10000000 [STOP_LONGITUDE]
	  ,p.TIME_POINT_ABBR
	  ,p.TIME_PT_NAME
	  ,isnull(t.significant,'n') significant_tp
	  FROM [LTD-TMDATA].tmdatamart.dbo.adherence a
	  JOIN [LTD-TMDATA].tmdatamart.dbo.[ROUTE] r ON r.ROUTE_ID = a.ROUTE_ID
	  JOIN [LTD-TMDATA].tmdatamart.dbo.ROUTE_DIRECTION rd ON rd.ROUTE_DIRECTION_ID = a.ROUTE_DIRECTION_ID
	  JOIN [LTD-TMDATA].tmdatamart.dbo.GEO_NODE g ON g.GEO_NODE_ID = a.GEO_NODE_ID
	  left join [LTD-TMDATA].ltd_db.dbo.ltd_significant_tps_from_tmmain t on t.tp = g.GEO_NODE_ABBR and r.ROUTE_ABBR = t.[route] and left(upper(rd.ROUTE_DIRECTION_ABBR),1) = t.direction
	  LEFT JOIN [LTD-TMDATA].tmdatamart.[dbo].[TIME_POINT] p ON p.TIME_POINT_ID = g.geo_node_id
	  WHERE r.route_id = @currRoute
	  --WHERE a.calendar_id >= 120190901
and r.route_id is not null
and rd.route_direction_id is not null
and g.geo_node_id is not null
GROUP BY a.ROUTE_ID, a.ROUTE_DIRECTION_ID,a.GEO_NODE_ID,	r.ROUTE_ABBR, r.ROUTE_NAME, g.GEO_NODE_ABBR 
,ROUTE_DIRECTION_ABBR, ROUTE_DIRECTION_NAME, UPPER(LEFT(ROUTE_DIRECTION_NAME,1)) 
, g.GEO_NODE_NAME
	 ,g.latitude/10000000 
	  ,g.longitude/10000000 
	  ,p.TIME_POINT_ABBR
	  ,p.TIME_PT_NAME
	  ,isnull(t.significant,'n') 
UNION
SELECT  a.ROUTE_ID, a.ROUTE_DIRECTION_ID,a.GEO_NODE_ID
,r.ROUTE_ABBR, r.ROUTE_NAME, g.GEO_NODE_ABBR STOP_ABBR
,ROUTE_DIRECTION_ABBR, ROUTE_DIRECTION_NAME, UPPER(LEFT(ROUTE_DIRECTION_NAME,1)) ROUTE_DIR
, g.GEO_NODE_NAME STOP_NAME,
RIGHT('000000'+ CAST(a.[ROUTE_ID] AS VARCHAR(32)),6)
      + RIGHT('000000'+ CAST(a.[ROUTE_DIRECTION_ID] AS VARCHAR(32)),6)
      + RIGHT('000000'+ CAST(a.[geo_node_id] AS VARCHAR(32)),6) as RTE_DIR_STOP_KEY
	  ,g.latitude/10000000 [STOP_LATITUDE]
	  ,g.longitude/10000000 [STOP_LONGITUDE]
	  ,p.TIME_POINT_ABBR
	  ,p.TIME_PT_NAME
	  ,isnull(t.significant,'n') significant_tp
	  FROM [LTD-TMDATA].tmdatamart.dbo.adherence_by_stop a
	  JOIN [LTD-TMDATA].tmdatamart.dbo.[ROUTE] r ON r.ROUTE_ID = a.ROUTE_ID
	  JOIN [LTD-TMDATA].tmdatamart.dbo.ROUTE_DIRECTION rd ON rd.ROUTE_DIRECTION_ID = a.ROUTE_DIRECTION_ID
	  JOIN [LTD-TMDATA].tmdatamart.dbo.GEO_NODE g ON g.GEO_NODE_ID = a.GEO_NODE_ID
	  left join [LTD-TMDATA].ltd_db.dbo.ltd_significant_tps_from_tmmain t on t.tp = g.GEO_NODE_ABBR and r.ROUTE_ABBR = t.[route] and left(upper(rd.ROUTE_DIRECTION_ABBR),1) = t.direction
	  LEFT JOIN [LTD-TMDATA].tmdatamart.[dbo].[TIME_POINT] p ON p.TIME_POINT_ID = g.geo_node_id
	  WHERE r.route_id = @currRoute
and r.route_id is not null
and rd.route_direction_id is not null
and g.geo_node_id is not null
GROUP BY a.ROUTE_ID, a.ROUTE_DIRECTION_ID,a.GEO_NODE_ID,	r.ROUTE_ABBR, r.ROUTE_NAME, g.GEO_NODE_ABBR 
,ROUTE_DIRECTION_ABBR, ROUTE_DIRECTION_NAME, UPPER(LEFT(ROUTE_DIRECTION_NAME,1)) 
, g.GEO_NODE_NAME
	 ,g.latitude/10000000 
	  ,g.longitude/10000000 
	  ,p.TIME_POINT_ABBR
	  ,p.TIME_PT_NAME
	  ,isnull(t.significant,'n') 
union
SELECT  a.ROUTE_ID, a.ROUTE_DIRECTION_ID,a.GEO_NODE_ID,r.ROUTE_ABBR, r.ROUTE_NAME, g.GEO_NODE_ABBR 
,ROUTE_DIRECTION_ABBR, ROUTE_DIRECTION_NAME, UPPER(LEFT(ROUTE_DIRECTION_NAME,1)) ROUTE_DIR
,g.GEO_NODE_NAME ,
RIGHT('000000'+ CAST(a.[ROUTE_ID] AS VARCHAR(32)),6)
      + RIGHT('000000'+ CAST(a.[ROUTE_DIRECTION_ID] AS VARCHAR(32)),6)
      + RIGHT('000000'+ CAST(a.[geo_node_id] AS VARCHAR(32)),6) as RTE_DIR_STOP_KEY
	  ,g.latitude/10000000 [STOP_LATITUDE]
	  ,g.longitude/10000000 [STOP_LONGITUDE]
	  ,p.TIME_POINT_ABBR
	  ,p.TIME_PT_NAME
	  ,isnull(t.significant,'n') 
	  FROM [LTD-TMDATA].tmdatamart.dbo.PASSENGER_COUNT a
	  JOIN [LTD-TMDATA].tmdatamart.dbo.[ROUTE] r ON r.ROUTE_ID = a.ROUTE_ID
	  JOIN [LTD-TMDATA].tmdatamart.dbo.ROUTE_DIRECTION rd ON rd.ROUTE_DIRECTION_ID = a.ROUTE_DIRECTION_ID
	  JOIN [LTD-TMDATA].tmdatamart.dbo.GEO_NODE g ON g.GEO_NODE_ID = a.GEO_NODE_ID
	  left join [LTD-TMDATA].ltd_db.dbo.ltd_significant_tps_from_tmmain t on t.tp = g.GEO_NODE_ABBR and r.ROUTE_ABBR = t.[route] and left(upper(rd.ROUTE_DIRECTION_ABBR),1) = t.direction
	  LEFT JOIN [LTD-TMDATA].tmdatamart.[dbo].[TIME_POINT] p ON p.TIME_POINT_ID = g.geo_node_id
WHERE r.route_id = @currRoute
--WHERE a.calendar_id >= 120190901
and r.route_id is not null
and rd.route_direction_id is not null
and g.geo_node_id is not NULL
GROUP BY   a.ROUTE_ID, a.ROUTE_DIRECTION_ID,a.GEO_NODE_ID,	r.ROUTE_ABBR, r.ROUTE_NAME, g.GEO_NODE_ABBR 
,ROUTE_DIRECTION_ABBR, ROUTE_DIRECTION_NAME, UPPER(LEFT(ROUTE_DIRECTION_NAME,1)) 
, g.GEO_NODE_NAME
	  ,g.latitude/10000000 
	  ,g.longitude/10000000 
	  ,p.TIME_POINT_ABBR
	  ,p.TIME_PT_NAME
	  ,isnull(t.significant,'n')
UNION

SELECT tgn.ROUTE_ID,tgn.ROUTE_DIRECTION_ID,tgn.GEO_NODE_ID,r.ROUTE_ABBR, r.ROUTE_NAME, g.GEO_NODE_ABBR
,route_direction_abbr,rd.ROUTE_DIRECTION_NAME, UPPER(LEFT(ROUTE_DIRECTION_NAME,1)) ROUTE_DIR
,g.GEO_NODE_NAME ,
RIGHT('000000'+ CAST(tgn.[ROUTE_ID] AS VARCHAR(32)),6)
      + RIGHT('000000'+ CAST(tgn.[ROUTE_DIRECTION_ID] AS VARCHAR(32)),6)
      + RIGHT('000000'+ CAST(tgn.[geo_node_id] AS VARCHAR(32)),6) as RTE_DIR_STOP_KEY
	  ,g.latitude/10000000 [STOP_LATITUDE]
	  ,g.longitude/10000000 [STOP_LONGITUDE]
	  ,p.TIME_POINT_ABBR
	  ,p.TIME_PT_NAME
	  ,isnull(t.significant,'n') 
FROM [LTD-TMDATA].tmmain.dbo.trip_geo_node_xref  tgn WITH (NOLOCK)
 INNER JOIN [LTD-TMDATA].tmmain.dbo.[route]             r WITH (NOLOCK)  ON r.route_id                = tgn.route_id 
 INNER JOIN [LTD-TMDATA].tmmain.dbo.geo_node            g WITH (NOLOCK)  ON g.geo_node_id             = tgn.geo_node_id
 INNER JOIN [LTD-TMDATA].tmmain.dbo.ROUTE_DIRECTION	  rd WITH (NOLOCK)  ON rd.ROUTE_DIRECTION_ID = tgn.ROUTE_DIRECTION_ID
 LEFT JOIN [LTD-TMDATA].tmmain.dbo.TIME_POINT		   p WITH (NOLOCK)	ON p.TIME_POINT_ID = g.GEO_NODE_ID
 LEFT join [LTD-TMDATA].ltd_db.dbo.ltd_significant_tps_from_tmmain t 
 ON t.tp = g.GEO_NODE_ABBR and r.ROUTE_ABBR = t.[route] and left(upper(rd.ROUTE_DIRECTION_ABBR),1) = t.direction
WHERE r.route_id = @currRoute  
GROUP BY 
  tgn.ROUTE_ID,tgn.ROUTE_DIRECTION_ID,tgn.GEO_NODE_ID,r.ROUTE_ABBR, r.ROUTE_NAME, g.GEO_NODE_ABBR
,route_direction_abbr,rd.ROUTE_DIRECTION_NAME, UPPER(LEFT(ROUTE_DIRECTION_NAME,1)) 
,g.GEO_NODE_NAME ,
RIGHT('000000'+ CAST(tgn.[ROUTE_ID] AS VARCHAR(32)),6)
      + RIGHT('000000'+ CAST(tgn.[ROUTE_DIRECTION_ID] AS VARCHAR(32)),6)
      + RIGHT('000000'+ CAST(tgn.[geo_node_id] AS VARCHAR(32)),6) 
	  ,g.latitude/10000000 
	  ,g.longitude/10000000 
	  ,p.TIME_POINT_ABBR
	  ,p.TIME_PT_NAME
	  ,isnull(t.significant,'n')
) u --WHERE r.route_id = @currRoute
WHERE NOT EXISTS (
	SELECT 1 FROM model.ROUTE_DIR_STOP_TP
		WHERE
		(	ROUTE_ID = u.ROUTE_ID	
		AND	ROUTE_DIRECTION_ID = u.ROUTE_DIRECTION_ID	
		AND	GEO_NODE_ID = u.GEO_NODE_ID	
		AND	ROUTE_ABBR = u.ROUTE_ABBR	
		AND	ROUTE_NAME = u.ROUTE_NAME	
		AND	STOP_ABBR = u.STOP_ABBR	
		AND	ROUTE_DIRECTION_ABBR = u.ROUTE_DIRECTION_ABBR	
		AND	ROUTE_DIRECTION_NAME = u.ROUTE_DIRECTION_NAME	
		AND	ROUTE_DIR = u.ROUTE_DIR	
		AND	STOP_NAME = u.STOP_NAME	
		AND	RTE_DIR_STOP_KEY = u.RTE_DIR_STOP_KEY	
		AND	STOP_LATITUDE = u.STOP_LATITUDE	
		AND	STOP_LONGITUDE = u.STOP_LONGITUDE	
		AND	TIME_POINT_ABBR = u.TIME_POINT_ABBR	
		AND	TIME_PT_NAME = u.TIME_PT_NAME	
		AND	significant_tp = u.significant_tp	))
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
