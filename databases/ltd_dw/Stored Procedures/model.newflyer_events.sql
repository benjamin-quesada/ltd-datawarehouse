SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [model].[newflyer_events]
@monthAge int
AS
SET NOCOUNT ON;

/************************************************
CREATED BY  : B Eichberger
CREATED DT  : 20220923
CREATED FOR : move code from embedded in model table properties 
			  to procedure to load data into NF Model

  exec model.newflyer_events -12
*************************************************/

DECLARE @SPROC VARCHAR(100);
SET @SPROC = OBJECT_SCHEMA_NAME(@@PROCID) + '.' + OBJECT_NAME(@@PROCID);

BEGIN TRY
;
WITH p AS (SELECT GEOGRAPHY::STGeomFromText((SELECT geogCol2 FROM geo.SpatialTable WHERE geogName = 'Glenwood Extended'), 4269 ) AS poly)

SELECT r.event_spm_key,
       r.drive_license_key,
       r.event_type_cat_key,
       r.drive_id,
       r.trip_id,
       r.license_number,
       r.event_time,
       r.event_spm,
       r.event_calendar_id,
       r.latitude,
       r.longitude,
       r.event_on_trip,
       CASE WHEN r.point.STIntersection(r.poly).ToString() LIKE 'POINT%' THEN 'DRIVE' ELSE 'GLENWOOD' END DriveOrGlenwood
FROM (
SELECT q.event_spm_key,
       q.veh_drive_eventspm_key,
       q.drive_license_key,
       q.event_type_cat_key,
       q.drive_id,
       q.trip_id,
       q.license_number,
       q.event_time,
       q.event_spm,
       q.event_calendar_id,
       q.latitude,
       q.longitude,
       q.event_on_trip,
       p.poly,
	   geography::Point(q.latitude,q.longitude, 4269) AS point
FROM (
SELECT event_spm_key,
       veh_drive_eventspm_key,
       drive_license_key,
       event_type_cat_key,
       drive_id,
       trip_id,
       license_number,
       event_time,
       event_spm,
       event_calendar_id,
       latitude,
       longitude,
       event_on_trip
FROM [fact].[new_flyer_events] e
JOIN tm.DW_CALENDAR c ON c.CALENDAR_ID = e.event_calendar_id
WHERE (@monthAge <> -12 AND c.CalculatedMonthAge = @monthAge)  or
      (@monthAge = -12 AND c.CalculatedMonthAge = @monthAge AND event_calendar_id >= 120210501 ) 
	) q
	CROSS JOIN p
) r
WHERE r.latitude IS NOT NULL AND r.longitude IS NOT NULL
OPTION (MAXDOP 2)


END TRY
BEGIN CATCH

    DECLARE @profile VARCHAR(255) = (SELECT [name] FROM msdb.dbo.sysmail_profile);
    DECLARE @errormsg VARCHAR(MAX),
            @error    INT,
            @message  VARCHAR(MAX),
            @xstate   INT,
            @errsev   INT,
            @sub      VARCHAR(255);

    SELECT @error = ERROR_NUMBER(),
           @errsev = ERROR_SEVERITY(),
           @message = ERROR_MESSAGE(),
           @xstate = XACT_STATE();

    SELECT @errormsg
        = 'Error in ' + ISNULL(@SPROC, '') + ': ' + CAST(ISNULL(@error, '') AS NVARCHAR(32)) + '|'
          + COALESCE(@message, '') + '|' + CAST(ISNULL(@xstate, '') AS NVARCHAR(32)) + '|'
          + CAST(ISNULL(@errsev, '') AS NVARCHAR(32));

    SELECT @sub = 'ERROR: ' + @SPROC;

    EXEC msdb.dbo.sp_send_dbmail @profile_name = @profile,
                                 @recipients = 'barb.eichberger@ltd.org',
                                 @subject = @sub,
                                 @body = @errormsg;

    RAISERROR(@errormsg, @errsev, 1);
END CATCH;
GO
