SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE   PROCEDURE [efare].[GET_CENTROID_RADIUS]

AS

begin try

/*
AUTHOR   : BEichberger
DATE     : 20250107
PURPOSE  : Data Extract from efar.FARE activity to plot higher use areas
		   this data takes 3-4 hours to refresh. There isn't an  
		   incremental option for this experiment.

USE		 : exec [efare].[GET_CENTROID_RADIUS]

*/

set nocount on

declare @SPROC VARCHAR(100)
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


SELECT distinct c.cardAccount_key
				 ,CAST(longitude AS DECIMAL(12,9)) longitude
				 ,CAST(latitude AS DECIMAL(12,9)) latitude
				into #thelats
				FROM [ltd_dw].[efare].[FARE_Extended] e
				join efare.card_account_xref c on e.cardNumber = c.cardNumber and e.cardAccount_key = c.cardAccount_key
				WHERE 1=1
				AND CAST(longitude AS DECIMAL(12,9)) <> 0
					 AND CAST(latitude AS DECIMAL(12,9)) <> 0
					 AND CAST(longitude AS DECIMAL(12,9))  BETWEEN -123.9999 AND -121.0000
					 AND CAST(latitude AS DECIMAL(12,9)) BETWEEN 43.9999 AND 45.0000


TRUNCATE TABLE [efare].[radius_views_efare_patrons]
DROP TABLE IF EXISTS ##points;
DROP TABLE IF EXISTS #distances;
CREATE TABLE ##points (row_key BIGINT IDENTITY(1,1)
,cardAccount_key BIGINT,grp INT, rn BIGINT, lon DECIMAL(12,9),lat DECIMAL(12,9)
,geog geography
)
INSERT ##points
( cardAccount_key,grp
	,rn
   ,lon
   ,lat
   ,geog
   )
		SELECT x.cardAccount_key, x.grp, ROW_NUMBER() OVER (PARTITION BY cardAccount_key,grp ORDER BY lon, lat ) AS rn, x.lon,x.lat, x.geog 
		FROM(
		SELECT cardAccount_key
		,grp = NTILE(4) OVER (PARTITION BY t.cardAccount_key ORDER BY CAST([Longitude] AS DECIMAL(12,9)), CAST([Latitude] AS DECIMAL(12,9)))
		,CAST([Longitude] AS DECIMAL(12,9)) lon, CAST([Latitude] AS DECIMAL(12,9)) lat
		,geography::Point(CAST([Latitude] AS DECIMAL(12,9)),CAST([Longitude] AS DECIMAL(12,9)), 4326) as geog
		 FROM #thelats t
	) x
INSERT ##points
(
cardAccount_key, grp
,rn
,lon
,lat
,geog
)
 SELECT cardAccount_key, grp
,rn
,lon
,lat
,geog FROM ##points WHERE rn = 1

--SELECT cardAccount_key,grp FROM ##points WHERE rn >= 4 GROUP BY cardAccount_key,grp

DROP TABLE IF EXISTS #accountGrps
CREATE TABLE #accountGrps (accountKey INT IDENTITY(1,1) NOT NULL,cardAccount_key BIGINT, grp INT )
INSERT #accountGrps(cardAccount_key, grp)
SELECT DISTINCT cardAccount_key, grp FROM ##points WHERE rn >= 4 GROUP BY cardAccount_key,grp


DECLARE @BuildString NVARCHAR(MAX)

DECLARE @i INT = 1
DECLARE @r INT = (SELECT max(accountKey) FROM #accountGrps)
WHILE @i <= @r 
BEGIN


DECLARE @currentAcct bigint = (SELECT DISTINCT cardAccount_key FROM #accountGrps WHERE accountKey = @i)
DECLARE @currentGrp INT = (SELECT DISTINCT grp FROM #accountGrps WHERE accountKey = @i)



DROP TABLE IF EXISTS #distances;
SET @BuildString = ''
SELECT @BuildString = COALESCE(@BuildString + ',', '') + CAST(lon AS VARCHAR(32))  + ' ' + CAST(lat AS VARCHAR(32))
FROM ##points p
WHERE p.cardAccount_key = @currentAcct AND grp = @currentGrp
ORDER BY p.row_key

SET @BuildString = SUBSTRING(@BuildString,2,999999)
SET @BuildString = 'POLYGON((' + @BuildString + '))';  
DECLARE @PolygonFromPoints GEOGRAPHY = GEOGRAPHY::STPolyFromText(@BuildString, 4326).MakeValid();
--SELECT @BuildString


DECLARE @centroid GEOGRAPHY = (SELECT @PolygonFromPoints.EnvelopeCenter())

-- compare the centroid to all rows in distances
SELECT @centroid centroid,
@centroid.STDistance(geog) distance
, cardAccount_key, lat, lon
INTO #distances
FROM ##points WHERE cardAccount_key = @currentAcct AND grp = @currentGrp

INSERT [efare].[radius_views_efare_patrons](
accountId
,[lat]
,[lon]
,[radius])
SELECT cardAccount_key, lat, lon, (distance)/1609.34 AS radius
FROM #distances where distance = ( SELECT MAX(distance) FROM #distances )

DROP TABLE IF EXISTS #distances
--END

SELECT @i = @i + 1
IF @i > @r
BREAK
	ELSE CONTINUE	

END



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
