SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE VIEW [apc].[apc_projections_for_r_clean]
AS
WITH wthr
AS (SELECT calendar_date,
           AVG(temp) daytemp,
           AVG(clouds) dayclouds,
           AVG(VISIBILITY) dayvis,
           AVG(wind_speed) avgwind
    FROM ltd_dw.[wrk].[apc_projection] 
    GROUP BY calendar_date)
SELECT 
       r.[calendar_date],
       calendar_datetime = CAST(LEFT(CONVERT(VARCHAR(32),r.calendar_datetime,21),19) + '.'+ CAST(r.TRIP_ID AS VARCHAR(32)) AS DATETIME2),
       r.block_abbr,
       r.route_abbr,
       r.rdir_abbr,
       r.GEO_NODE_ABBR AS stop_abbr,
       r.DayOfWeekNbr AS day_of_week_nbr,
       r.trip_id,
       r.HH,
       r.MM,
       r.SS,
       board = SUM(ISNULL(r.BOARD, 0)) ,
       COALESCE(r.temp, w.daytemp) temp,
       COALESCE(r.clouds, w.dayclouds) clouds,
       COALESCE(r.VISIBILITY, w.dayvis) visibility,
       COALESCE(r.wind_speed, w.avgwind) wind,
       ISNULL(r.isHoliday, 'N') isHoliday
FROM ltd_dw.[wrk].[apc_projection] r
    LEFT JOIN wthr w
        ON w.calendar_date = r.calendar_date
WHERE 1=1 
AND r.ROUTE_ABBR NOT IN ('FLT', 'swap', '25')
AND r.GEO_NODE_ABBR NOT LIKE 'ss%'
AND r.GEO_NODE_ABBR NOT LIKE 'ann%'
AND r.GEO_NODE_ABBR NOT LIKE 'arr%'
AND r.GEO_NODE_ABBR NOT LIKE 'es%'
AND r.GEO_NODE_ABBR NOT LIKE 'anx%'
AND r.GEO_NODE_ABBR NOT LIKE 'garage%'
AND ISNULL(HH,0) <> 0
AND ISNULL(MM,0) <> 0
GROUP BY 
r.[calendar_date],
       CAST(LEFT(CONVERT(VARCHAR(32),r.calendar_datetime,21),19) + '.'+ CAST(r.TRIP_ID AS VARCHAR(32)) AS DATETIME2),
       r.block_abbr,
       r.route_abbr,
       r.rdir_abbr,
       r.GEO_NODE_ABBR ,
       r.DayOfWeekNbr ,
       r.TRIP_ID,
       r.HH,
       r.MM,
       r.SS,
       COALESCE(r.temp, w.daytemp) ,
       COALESCE(r.clouds, w.dayclouds) ,
       COALESCE(r.visibility, w.dayvis) ,
       COALESCE(r.wind_speed, w.avgwind) ,
       ISNULL(r.isHoliday, 'N') 
--ORDER BY calendar_datetime

GO
