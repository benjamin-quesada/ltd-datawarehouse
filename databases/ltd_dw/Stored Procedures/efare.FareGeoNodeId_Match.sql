SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE   PROCEDURE [efare].[FareGeoNodeId_Match]
as


/*------------------LTD_GLOSSARY---------------
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

DROP TABLE IF EXISTS #geoSource
SELECT GEO_NODE_ID
	  ,GEO_NODE_ABBR
	  ,GEO_NODE_NAME
	  ,LATITUDE
	  ,LONGITUDE
	 INTO #geoSource
	 FROM [LTD-TMDATA].tmdatamart.dbo.GEO_NODE

drop table if EXISTS #stageFareMatch
SELECT	x.[fareLoadKey]
	   ,x.txID
	   ,x.ts
	   ,x.type
	   ,x.mediaUsed
	   ,x.mediaType
	   ,x.cardNumber
	   ,x.fareType
	   ,x.accountId
	   ,x.routeName
	   ,x.routeNumber
	   ,x.fare_lat
	   ,x.fare_lon
	   ,x.reader
	   ,x.passUsed
	   ,x.readerPosition
	   ,x.fare
	   ,x.geo_node_id
	   ,x.geo_node_lat
	   ,x.geo_node_lon	
	   ,x.radius
	   ,x.GeoNodeDistanceToFarePoint
	   ,x.IsLocated
	   ,x.Distance4326
INTO -- select * from 
#stageFareMatch
FROM
(	SELECT	b.geo_node_id
		   ,b.fareLoadKey
		   ,b.geo_node_lat
		   ,b.geo_node_lon
		   ,b.radius
		   ,b.txID
		   ,b.ts
		   ,b.type
		   ,b.mediaUsed
		   ,b.mediaType
		   ,b.cardNumber
		   ,b.fareType
		   ,b.accountId
		   ,b.routeName
		   ,b.routeNumber
		   ,b.fare_lat
		   ,b.fare_lon
		   ,b.reader
		   ,b.passUsed
		   ,b.readerPosition
		   ,b.fare
		   ,b.circle
		   ,b.pointFare
		   ,b.GeoNodeDistanceToFarePoint
		   ,IsLocated = pointFare.STIntersection(circle).ToString()
		   ,Distance4326 = b.pointFare.STDistance(b.pointGeo)
	FROM
	(	SELECT geo_node_id,f.fareLoadKey
			,CAST(g.LATITUDE / 10000000 as DECIMAL(18, 14)) geo_node_lat
			,CAST(g.LONGITUDE / 10000000 as DECIMAL(18, 14)) geo_node_lon
			,r.radius
			,f.[txID]
			,f.[ts]
			,f.[type]
			,f.[mediaUsed]
			,f.[mediaType]
			,f.[cardNumber]
			,f.[fareType]
			,f.[accountId]
			,f.[routeName]
			,f.[routeNumber]
			,f.[reader]
			,f.[passUsed]
			,f.[readerPosition]
			,f.[fare]
			,CAST(f.latitude AS DECIMAL(18, 14)) fare_lat
			,CAST(f.longitude AS DECIMAL(18, 14)) fare_lon
			,circle = geography::Point(g.LATITUDE / 10000000.0, g.LONGITUDE / 10000000.0, 4326).STBuffer(r.radius)
			,pointFare = geography::Point(f.latitude, f.longitude, 4326) -- select * 
			,pointGeo = geography::Point(g.LATITUDE / 10000000.0, g.LONGITUDE / 10000000.0, 4326) -- select * 
			,GeoNodeDistanceToFarePoint = (SQRT(POWER(69.1 * ( g.LATITUDE / 10000000.0 - f.latitude),  
							2) + POWER(69.1 * ( g.LONGITUDE / 10000000  
							- f.longitude )  
							* COS(f.longitude / 57.3), 2))  )
		FROM
		#geoSource g
		CROSS APPLY
		(	SELECT CONVERT(FLOAT, value) AS radius
			FROM STRING_SPLIT('12,6,3,1', ',')	-- 4326 = feet so these radii are 12,6,3,1 feet radius of the circle at a point (lat/lon, a stop)
			) r
		CROSS APPLY (SELECT top(1000)
					 [fareLoadKey]
					,f.[txID]
					,f.[ts]
					,f.[type]
					,f.[mediaUsed]
					,f.[mediaType]
					,f.[cardNumber]
					,f.[fareType]
					,f.[accountId]
					,f.[routeName]
					,f.[routeNumber]
					,f.[reader]
					,f.[passUsed]
					,f.[readerPosition]
					,f.[fare]
					,CAST(latitude AS DECIMAL(32, 18)) latitude
					,CAST(longitude AS DECIMAL(32, 18)) longitude	
					FROM efare.FARE f
						LEFT JOIN [efare].[TxProcessedFaresToGeo] e ON e.txID = f.txID
					WHERE CAST(latitude AS DECIMAL(32, 18 )) <> 0.00 
					AND CAST(f.[ts] AS DATE)  BETWEEN '8/1/2019' AND '9/15/2022' 
					AND e.txID IS null
					 ) f
		WHERE g.LATITUDE IS NOT NULL
	) b 
) x


 
INSERT [efare].[FareGeoMatch]
(
[fareLoadKey]
,[txID]
,[ts]
,[type]
,[mediaUsed]
,[mediaType]
,[cardNumber]
,[fareType]
,[accountId]
,[routeName]
,[routeNumber]
,[fare_lat]
,[fare_lon]
,[reader]
,[readerPosition]
,[passUsed]
,[fare]
,[geo_node_id]
,[geo_node_lat]
,[geo_node_lon]
,[radius]
,GeoNodeDistanceToFarePoint
,IsLocated
,Distance4326
)
SELECT fareLoadKey
	  ,txID
	  ,ts
	  ,type
	  ,mediaUsed
	  ,mediaType
	  ,cardNumber
	  ,fareType
	  ,accountId
	  ,routeName
	  ,routeNumber
	  ,fare_lat
	  ,fare_lon
	  ,reader
	  ,readerPosition
	  ,passUsed
	  ,fare
	  ,GEO_NODE_ID
	  ,geo_node_lat
	  ,geo_node_lon
	  ,radius
	  ,GeoNodeDistanceToFarePoint
	  ,IsLocated
	  ,Distance4326
FROM #stageFareMatch h
WHERE IsLocated <> 'GEOMETRYCOLLECTION EMPTY' 
OR GeoNodeDistanceToFarePoint < 1
OR Distance4326 <= 1000

INSERT [efare].[TxProcessedFaresToGeo] (Txid)
SELECT txid FROM #stageFareMatch a
	WHERE NOT EXISTS (SELECT 1 FROM [efare].[TxProcessedFaresToGeo] WHERE txID = a.txID)


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
             ,@recipients = 'barb.eichberger@ltd.org'--;servicedesk@ltd.org' 
             ,@subject = @sub
             ,@body = @errormsg;

       RAISERROR (
                    @errormsg
                    ,@errsev
                    ,1
                    )
END CATCH
GO
