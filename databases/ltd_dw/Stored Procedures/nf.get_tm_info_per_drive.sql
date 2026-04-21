SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [nf].[get_tm_info_per_drive]
AS

/************************************************
CREATED BY  : B Eichberger
CREATED FOR : load tm matching data into table for NF Model
CREATED DT  : 20210825
EDITED DT   : 20220303 -- troubleshooting not loading issue
EDITED DT   : 20220329 -- added drives from events
REINSTATED  : 20220614 -- attempt to reinstate to manage different needs of the tab models
EDITED DT   : 20220726 -- remove tempdb from process

exec nf.get_tm_info_per_drive 
*************************************************/



SET NOCOUNT ON;

DECLARE @SPROC VARCHAR(100);
SET @SPROC = OBJECT_SCHEMA_NAME(@@PROCID) + '.' + OBJECT_NAME(@@PROCID);

BEGIN TRY

DECLARE @licenseDate TABLE(license_number VARCHAR(32), calId INT)
INSERT @licenseDate (license_number,
                          calId)
SELECT license_number ,MAX(calId) FROM (
SELECT i.license_number,
       MAX(LEFT(i.start_spm_key,9)) calId
        from fact.drive_veh_spm_tm_info i
	GROUP BY i.license_number
union
SELECT o.License_Number,
       MAX(o.workingDateInt) calMax
       FROM wrk.NoTmOUTPUT_drive_veh_spm_tm_info o
GROUP BY o.License_Number
) p
GROUP BY p.license_number

DROP TABLE IF EXISTS Wrk.vehList
CREATE TABLE Wrk.vehList (calendar_id INT, Property_Tag VARCHAR(32))
INSERT Wrk.vehList (calendar_id, PROPERTY_TAG)

SELECT calendar_id, v.PROPERTY_TAG
FROM [ltd-tmdata].tmdatamart.dbo.ADHERENCE a WITH (NOLOCK)
JOIN ltd_dw.model.Vehicle_v v ON v.vehicle_id = a.VEHICLE_ID
JOIN @licenseDate l ON l.license_number = v.license_no COLLATE SQL_Latin1_General_CP850_CI_AS 
				AND a.CALENDAR_ID >= l.calId
WHERE CALENDAR_ID >= 120210501 AND v.electric = 1
		GROUP BY calendar_id, v.PROPERTY_TAG
UNION
SELECT calendar_id, v.PROPERTY_TAG
FROM [ltd-tmdata].tmdatamart.dbo.PASSENGER_COUNT a WITH (NOLOCK)
JOIN ltd_dw.model.Vehicle_v v ON v.vehicle_id = a.VEHICLE_ID
JOIN @licenseDate l ON l.license_number = v.license_no COLLATE SQL_Latin1_General_CP850_CI_AS 
				AND a.CALENDAR_ID >= l.calId
WHERE CALENDAR_ID >= 120210501 AND v.electric = 1
		GROUP BY calendar_id, v.PROPERTY_TAG

DROP TABLE IF EXISTS Wrk.missingDt
CREATE TABLE Wrk.missingDt (rn INT IDENTITY(1,1), calId INT NOT NULL, calDt DATE NOT NULL,license_number int)
insert Wrk.missingDt (calId, calDt, license_number)
SELECT c.CALENDAR_ID calId, c.CALENDAR_DATE AS calDt, h.PROPERTY_TAG FROM tm.DW_CALENDAR c 
JOIN Wrk.vehList h ON h.CALENDAR_ID = c.CALENDAR_ID 
LEFT JOIN fact.drive_veh_spm_tm_info i ON LEFT(i.start_spm_key,9) = c.CALENDAR_ID AND i.license_number = h.PROPERTY_TAG
LEFT JOIN wrk.NoTmOUTPUT_drive_veh_spm_tm_info s on s.license_number = h.PROPERTY_TAG and s.workingDateInt = h.calendar_id
WHERE c.calendar_id >= 120210501
AND c.CALENDAR_DATE < CAST(GETDATE() AS DATE) 
AND i.start_spm_key is NULL 
AND i.license_number is NULL
AND s.license_number is NULL
AND s.workingDate is NULL
AND h.PROPERTY_TAG IS NOT null
ORDER BY c.CALENDAR_ID asc

IF (SELECT COUNT(*) FROM wrk.missingDt) <> 0
BEGIN
-- SELECT * from Wrk.missingDt
DECLARE @i INT = 1
DECLARE @r INT = (SELECT MAX(calId) FROM Wrk.missingDt)
DECLARE @currVeh INT
DECLARE @currDtIntEnd BIGINT
DECLARE @currDtIntStart BIGINT


WHILE @i <= @r
BEGIN
--SELECT @currVeh veh,@currDtIntStart dStart, @currDtIntEnd dEnd,SYSDATETIME() asof
select @currVeh = (SELECT license_number FROM Wrk.missingDt WHERE rn = @i)
DECLARE @currDt date = (SELECT calDt FROM Wrk.missingDt WHERE rn = @i)
DECLARE @currDtInt INT = (SELECT calId FROM Wrk.missingDt WHERE rn = @i)

select @currDtIntStart = (SELECT CAST(CAST(calId AS varchar(32)) + '000000' AS BIGINT)  FROM Wrk.missingDt WHERE rn = @i) 
select @currDtIntEnd = (SELECT CAST(CAST(calId AS varchar(32)) + '999999' AS BIGINT) FROM Wrk.missingDt WHERE rn = @i)


            DELETE FROM fact.drive_veh_spm_tm_info
             WHERE start_spm_key BETWEEN @currDtIntStart AND @currDtIntEnd
               AND license_number = @currVeh;

            DROP TABLE IF EXISTS Wrk.parkeys;
            CREATE TABLE Wrk.PARKEYS (parameter_spm_key BIGINT NOT NULL,
                                   parameter_type_key INT NOT NULL,
                                   license_number INT NOT NULL,
                                   last_input_value NUMERIC(22, 8) NOT NULL,
                                   last_input_time DATETIME2 NOT NULL,
								   plastdate DATE NOT NULL,
                                   start_calendar_id BIGINT NOT NULL,
                                   start_spm INT NOT NULL);
	
	--------find all parameter data	
			INSERT Wrk.PARKEYS (parameter_spm_key,
                          parameter_type_key,
                          license_number,
                          last_input_value,
                          last_input_time,
						  plastdate,
                          start_calendar_id,
                          start_spm)
            SELECT i.parameter_spm_key,
                   i.parameter_type_key,
                   i.license_number,
                   i.last_input_value,
                   i.last_input_time,
				   i.plastdate,
                   i.start_calendar_id,
                   i.start_spm
              FROM ( SELECT CAST(CAST(dbo.F_DATE_TO_CALENDAR_ID(p.last_input_time) AS varchar(32))
                                   + RIGHT('000000'
                                           + CAST(dbo.F_DATE_TO_SEC_SINCE_MIDNITE(CAST(p.last_input_time AS DATETIME)) AS VARCHAR(32)), 6) AS BIGINT) AS parameter_spm_key,
                              t.parameter_type_key,
                              p.license_number,
                              p.last_input_value,
                              p.last_input_time,
							  CAST(p.last_input_time AS DATE) plastdate,
                              CAST(CONVERT(VARCHAR(32), CAST(p.last_input_time AS DATETIME), 112) AS INT) + 100000000 start_calendar_id,
                              dbo.F_DATE_TO_SEC_SINCE_MIDNITE(CAST(p.last_input_time AS DATETIME)) start_spm
                         FROM [fact].[new_flyer_parameters_limited] p WITH (NOLOCK)
                         JOIN [dim].[new_flyer_parameter_type_limited] t
                           ON t.parameter_type = p.parameter_type
						    WHERE -- select 
							dbo.F_DATE_TO_CALENDAR_ID(p.last_input_time) = @currDtInt
							AND p.license_number = @currVeh
							) i

	--------find all drive info data	
            DROP TABLE IF EXISTS Wrk.DRIVEYS;
            CREATE TABLE Wrk.DRIVEYS (CAL_SPM_KEY BIGINT NOT NULL,
                                   Drive_Id VARCHAR(42) NOT NULL,
                                   license_number INT NOT NULL,
                                   drive_license_key BIGINT NOT NULL,
                                   start_spm_key BIGINT NOT NULL,
                                   end_spm_key BIGINT NOT NULL);
            INSERT Wrk.DRIVEYS (CAL_SPM_KEY,
                             Drive_Id,
                             license_number,
                             drive_license_key,
                             start_spm_key,
                             end_spm_key)
            SELECT x.CAL_SPM_KEY,
                   x.Drive_Id,
                   x.license_number,
                   x.drive_license_key,
                   x.start_spm_key,
                   x.end_spm_key
              FROM ( SELECT f.parameter_spm_key CAL_SPM_KEY,
                              f.start_calendar_id CALENDAR_ID,
                              CAST(d.drive_id AS VARCHAR(42)) Drive_Id,
                              d.license_number,
                              CAST(d.drive_license_key AS BIGINT) drive_license_key,
                              CAST(d.start_spm_key AS BIGINT) start_spm_key,
                              CAST(d.end_spm_key AS BIGINT) end_spm_key
                         -- select * 
						 FROM Wrk.PARKEYS f
						 LEFT JOIN -- select * from 
						 dim.new_flyer_drive d  
									--WHERE trip_start_calendar_id = 120220606
                         ON d.trip_start_calendar_id = f.start_calendar_id
                           AND f.license_number     = d.license_number
						   AND f.start_spm >= CAST(d.trip_start_spm AS BIGINT)
                           AND f.start_spm <= CAST(d.trip_end_spm AS BIGINT)
                         --JOIN tm.DW_CALENDAR_SPM s
                         --  ON s.CAL_SPM_KEY = f.parameter_spm_key
				 WHERE d.start_spm_key is not null and d.start_spm_key is not null
                        GROUP BY f.parameter_spm_key ,
                              f.start_calendar_id ,
                              CAST(d.drive_id AS VARCHAR(42)) ,
                              d.license_number,
                              CAST(d.drive_license_key AS BIGINT) ,
                              CAST(d.start_spm_key AS BIGINT) ,
                              CAST(d.end_spm_key AS BIGINT) ) x
             WHERE x.end_spm_key IS NOT NULL
             GROUP BY x.CAL_SPM_KEY,
                      x.Drive_Id,
                      x.license_number,
                      x.drive_license_key,
                      x.start_spm_key,
                      x.end_spm_key;

	--------find all events and combine	
  INSERT Wrk.DRIVEYS (CAL_SPM_KEY,
                             Drive_Id,
                             license_number,
                             drive_license_key,
                             start_spm_key,
                             end_spm_key)
 SELECT b.event_spm_key,
                   b.drive_id,
                   b.license_number,
                   b.drive_license_key,
                   b.start_spm_key,
                   b.end_spm_key
              FROM (
				SELECT event_spm_key = CAST(CAST(CONVERT(VARCHAR(32), CAST(event_time AS DATETIME), 112) AS INT)
                                                   + 100000000 AS VARCHAR(32))
                                              + RIGHT('000000'
                                                      + CAST([dbo].[F_DATE_TO_SEC_SINCE_MIDNITE](
                                                                 CAST(event_time AS DATETIME)) AS VARCHAR(32)), 6),
                              e.drive_id,
                              e.license_number,
                              drive_license_key = CAST(drive_id AS VARCHAR(32))
                                                  + RIGHT('000000' + CAST(license_number AS VARCHAR(32)), 6),
                              start_spm_key = CAST(CAST(CONVERT(VARCHAR(32), CAST(event_time AS DATETIME), 112) AS INT)
                                                   + 100000000 AS VARCHAR(32))
                                              + RIGHT('000000'
                                                      + CAST([dbo].[F_DATE_TO_SEC_SINCE_MIDNITE](
                                                                 CAST(event_time AS DATETIME)) AS VARCHAR(32)), 6),
                              end_spm_key = CAST(CAST(CONVERT(VARCHAR(32), CAST(end_time AS DATETIME), 112) AS INT)
                                                 + 100000000 AS VARCHAR(32))
                                            + RIGHT('000000'
                                                    + CAST([dbo].[F_DATE_TO_SEC_SINCE_MIDNITE](
                                                               CAST(end_time AS DATETIME)) AS VARCHAR(32)), 6)
                         FROM dbo.newflyer_events e
                        WHERE license_number = @currVeh
						) b
             WHERE b.end_spm_key IS NOT NULL AND event_spm_key BETWEEN @currDtIntStart AND @currDtIntEnd 
               AND NOT EXISTS (   SELECT 1
                                    FROM Wrk.DRIVEYS
                                   WHERE license_number    = b.license_number
                                     AND drive_license_key = b.drive_license_key
                                     AND start_spm_key     = b.start_spm_key
                                     AND end_spm_key       = b.end_spm_key);

if (select count(*) from Wrk.DRIVEYS) > 0
BEGIN
           
                INSERT fact.drive_veh_spm_tm_info (drive_id,
                                                license_number,
                                                drive_license_key,
                                                start_spm_key,
                                                end_spm_key,
                                                time_table_version_id,
                                                BLOCK_ID,
                                                ROUTE_ID,
                                                ROUTE_DIRECTION_ID,
                                               OPERATOR_ID)
                SELECT            q.Drive_Id,
                                  q.license_number,
                                  q.drive_license_key,
                                  q.start_spm_key,
                                  q.end_spm_key,
                                  i.time_table_version_id,
                                  i.BLOCK_ID,
                                  i.ROUTE_ID,
                                  i.ROUTE_DIRECTION_ID,
                                  i.OPERATOR_ID
                  FROM            Wrk.DRIVEYS q
                  LEFT OUTER JOIN fact.TM_Info i
                    ON i.cal_msgspm_key BETWEEN start_spm_key AND end_spm_key
                   AND CAST(i.veh AS INT) = q.license_number
                 WHERE            i.BLOCK_ID IS NOT NULL
                 GROUP BY q.Drive_Id,
                          q.license_number,
                          q.drive_license_key,
                          start_spm_key,
                          end_spm_key,
                          i.time_table_version_id,
                          i.BLOCK_ID,
                          i.ROUTE_ID,
                          i.ROUTE_DIRECTION_ID,
                          i.OPERATOR_ID;

END
 
if (select isnull(count(*),0) from Wrk.DRIVEYS) = 0
BEGIN
insert wrk.NoTmOUTPUT_drive_veh_spm_tm_info (license_number,workingDate,workingDateInt,IntStart, IntEnd,asofDate)
select @currVeh License_Number , @currDt workingDate, @currDtInt workingDateInt, @currDtIntStart IntStart
	, @currDtIntEnd IntEnd,sysdatetime() as asOfDate  WHERE @currVeh IS NOT null
END

            DROP TABLE Wrk.PARKEYS;
            DROP TABLE Wrk.DRIVEYS;

            SELECT @i = @i + 1;

            IF @i > @r
                BREAK;
            ELSE
                CONTINUE;

        END;

END

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
