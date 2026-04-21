SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






CREATE   VIEW [tm].[ALL_MILE_ACTIVITY_STAGE]
AS
/*

CREATED ON	: 20241002
CREATED BY	: B. Eichberger
PURPOSE		: capture vehicle distances from tmdatamart and tmdailylog logged messages
			  for analytical alignment with EAM among other uses

*/

WITH calStart
AS (
   SELECT CALENDAR_ID
   FROM [LTD-TMDATA].tmdatamart.dbo.CALENDAR
   WHERE CAST(CALENDAR_DATE AS DATE) >= CAST(GETDATE() - 31 AS DATE)
)
,tdy
AS (SELECT [dbo].[F_DATE_TO_CALENDAR_ID](CAST(GETDATE() AS DATE)) AS tdy)
,prep
AS (
SELECT LABEL_NAME = 'TMDATAMART;VEHICLE_DISTANCE;' + CAST(ISNULL(d.REVENUE_ID, 'N') AS VARCHAR(21)) + ';' + ISNULL(t.REVENUE_DESCRIPTION, 'OTHER') + +CASE WHEN IS_GARAGE = 1 THEN ';IS_GARAGE' ELSE '' END
   ,the_date = d.CALENDAR_ID
   ,TOTAL_MILES = ISNULL(TOTAL_DISTANCE, 0) 
   ,TOTAL_HOURS = ISNULL(TOTAL_HOURS, 0)
   ,PROPERTY_TAG
   ,d.ROUTE_ID
	--,SELECT *
	FROM [LTD-TMDATA].tmdatamart.dbo.VEHICLE_DISTANCE d
		 INNER JOIN calStart C ON C.CALENDAR_ID = d.CALENDAR_ID
		 LEFT JOIN [LTD-TMDATA].tmdatamart.dbo.REVENUE t ON t.REVENUE_ID = d.REVENUE_ID
	WHERE d.TOTAL_DISTANCE > 0
		  AND TOTAL_DISTANCE > 0
		
)
SELECT x.LABEL_NAME
,the_date = [dbo].[F_CALENDAR_ID_TO_DATE](x.the_date)
,miles_value = SUM(x.miles_value)
,hours_value = SUM(x.hours_value)
,x.PROPERTY_TAG
FROM
(
	SELECT m.LABEL_NAME
   ,m.ROUTE_ID
   ,m.the_date
   ,SUM(m.TOTAL_MILES) miles_value
   ,SUM(m.TOTAL_HOURS) hours_value
   ,m.PROPERTY_TAG
	FROM prep m
	GROUP BY m.LABEL_NAME
   ,m.the_date
   ,m.PROPERTY_TAG
   ,ROUTE_ID
) x
GROUP BY x.LABEL_NAME
,x.the_date
,x.PROPERTY_TAG
UNION
SELECT LABEL_NAME = 'LOGGED_MESSAGES;VEHICLE_DISTANCE'
,the_date = [dbo].[F_CALENDAR_ID_TO_DATE](calendar_id)
,SUM(odometer) / 100.0
,0
,veh
FROM [tm].[logged_messages] l
	 JOIN tdy t ON t.tdy = l.calendar_id
WHERE l.route IS NOT NULL
GROUP BY calendar_id
,veh;


GO
