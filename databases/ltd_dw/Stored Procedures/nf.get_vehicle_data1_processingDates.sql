SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [nf].[get_vehicle_data1_processingDates]
AS

/*---------------------------------------
Standardized Work Task Cost and Time Calculations

CREATED		20220815
AUTHOR		B EICHBERGER
PURPOSE		Prepares date ranges to send for parameter files from New Flyer API

exec nf.get_vehicle_data1_processingDates
----------------------------------------*/

BEGIN TRY

set nocount on;

DECLARE @SPROC VARCHAR(100)
SET @SPROC = OBJECT_SCHEMA_NAME(@@PROCID) + '.' + OBJECT_NAME(@@PROCID)

;
WITH ldt AS 
(SELECT ISNULL(vehicle_id,0) vehicle_id,ISNULL(license_number,0) license_number, ISNULL(MIN(ld),'2021-05-01') ldt FROM (
	SELECT v.vehicle_id,v.license_nmbr as license_number, ISNULL(MAX(CAST([last_input_time] AS date)),'2022-05-01') ld
	FROM nf.new_flyer_vehicle v
	LEFT JOIN [nf].[newflyer_parameters] t ON t.vehicle_id = v.vehicle_id
	WHERE v.vehicle_id IS NOT NULL	
	GROUP BY v.vehicle_id,v.license_nmbr
	UNION
	SELECT v.vehicle_id,v.license_nmbr as license_number, ISNULL(MAX([last_input_time_local]),'2022-05-01') ld
	FROM nf.new_flyer_vehicle v
	LEFT JOIN nf.[newflyer_parameters] t ON t.vehicle_id = v.vehicle_id
	WHERE v.vehicle_id IS NOT NULL	
	GROUP BY v.vehicle_id,v.license_nmbr
	UNION
	SELECT v.vehicle_id,v.license_nmbr as license_number, ISNULL(MAX(CAST(t.start_time AS date)),'2022-05-01') ld
	FROM nf.new_flyer_vehicle v
	LEFT JOIN [nf].newflyer_trips t ON t.vehicle_id = v.vehicle_id
	WHERE v.vehicle_id IS NOT NULL	
	GROUP BY v.vehicle_id,v.license_nmbr
	UNION
	SELECT v.vehicle_id,v.license_nmbr as license_number, ISNULL(MAX(t.start_time_local),'2022-05-01') ld
	FROM nf.new_flyer_vehicle v
	LEFT JOIN nf.newflyer_trips t ON t.vehicle_id = v.vehicle_id
	WHERE v.vehicle_id IS NOT NULL	
	GROUP BY v.vehicle_id,v.license_nmbr) y 
	GROUP BY vehicle_id,license_number )

SELECT 
       n.license_number,
       n.dtFrom,
       h.session_token FROM (
SELECT 
cast(d.vehicle_id as varchar(32)) vehicle_id,
cast(d.license_number as varchar(32)) license_number,
FORMAT(c.CALENDAR_DATE,'yyyy-MM-dd') dtFrom,
FORMAT(CAST(DATEADD(DAY,1,c.CALENDAR_DATE) AS DATETIME), 'yyyy-MM-dd') dtTo
FROM tm.DW_CALENDAR c 
CROSS JOIN ldt d
WHERE c.CALENDAR_DATE BETWEEN d.ldt AND CAST(GETDATE() AS date)
GROUP BY  
c.CALENDAR_DATE,
cast(d.vehicle_id as varchar(32)) ,
cast(d.license_number as varchar(32))
) n
CROSS JOIN  (select top(1) session_token from [dbo].[newflyer_token] order by session_start DESC) h
WHERE NOT EXISTS (SELECT 1 FROM [nf].[newflyer_zero_vehicledata1] t WHERE t.license_number = n.license_number
					AND t.fileloaddt = CAST(n.dtFrom AS DATE))
order by dtFrom , license_number


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
