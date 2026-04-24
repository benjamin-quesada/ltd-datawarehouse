SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [nf].[load_dim_new_flyer_drive]
as
set nocount on;
/*----

PURPOSE: Load dimension and lookup table dim.new_flyer_drive
CREATED: 20220726
CREATOR: b. eichberger

USE    : exec nf.load_dim_new_flyer_drive
----*/
DECLARE @SPROC VARCHAR(100)
SET @SPROC = OBJECT_SCHEMA_NAME(@@PROCID) + '.' + OBJECT_NAME(@@PROCID)

BEGIN TRY

INSERT dim.new_flyer_drive (
start_spm_key,
end_spm_key,
drive_license_key,
drive_id,
license_number,
start_latitude,
start_longitude,
end_latitude,
end_longitude,
start_time,
end_time,
trip_start_spm,
trip_end_spm,
trip_start_calendar_id,
trip_end_calendar_id,
start_trip_glenwood,
end_trip_glenwood
)
SELECT s.start_spm_key,
       s.end_spm_key,
       s.drive_license_key,
       s.drive_id,
       s.license_number,
       s.start_latitude,
       s.start_longitude,
       s.end_latitude,
       s.end_longitude,
       s.start_time,
       s.end_time,
       s.trip_start_spm,
       s.trip_end_spm,
       s.trip_start_calendar_id,
       s.trip_end_calendar_id,
       s.start_trip_glenwood,
       s.end_trip_glenwood FROM [fact].[new_flyer_drives] s
WHERE NOT EXISTS (SELECT 1 FROM dim.new_flyer_drive 
					WHERE drive_id = s.drive_id 
					AND license_number = s.license_number)

						
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
