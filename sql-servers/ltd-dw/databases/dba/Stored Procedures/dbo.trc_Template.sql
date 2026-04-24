SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
use Admin
go
*/
CREATE PROCEDURE [dbo].[trc_Template] @Folder NVARCHAR(200), @traceMinutes INT
AS
BEGIN TRY
/*
Start a timed profiler trace storing the captured output into a folder.
The folder must exist. A subfolder will be created using the start date
and time to allow for repeated running of this profile without replacing
the previous captured trace files.

Sample Command: exec trc_Template 'E:\trace', 360

*/
SET NOCOUNT ON;

EXEC sp_configure 'show advanced options', 1
-- To update the currently configured value for advanced options.
RECONFIGURE
-- To enable the feature.
EXEC sp_configure 'xp_cmdshell', 1
-- To update the currently configured value for this feature.
RECONFIGURE
-- Start profiler trace

--
-- To change the traces duration, modify the following statement
DECLARE @StopTime DATETIME;
SET @StopTime = DATEADD(mi, @traceMinutes, GETDATE());
DECLARE @StartDatetime VARCHAR(13);
SET @StartDatetime
    = CONVERT(CHAR(8), GETDATE(), 112) + '_' + CAST(REPLACE(CONVERT(VARCHAR(5), GETDATE(), 108), ':', '') AS CHAR(4)); --['YYYYMMDD_HHMM']
DECLARE @rc INT;
DECLARE @TraceID INT;
DECLARE @TraceFile NVARCHAR(100);
DECLARE @MaxFileSize BIGINT;
SET @MaxFileSize = 50; -- The maximum trace file in megabytes
DECLARE @cmd NVARCHAR(2000);
DECLARE @msg NVARCHAR(200);
IF RIGHT(@Folder, 1) <> '\'
    SET @Folder = @Folder + '\';
-- Check if Folder exists

SET @cmd = N'dir ' + @Folder;

EXEC @rc = master..xp_cmdshell @cmd, no_output;
IF (@rc != 0)
BEGIN
    SET @msg = N'The specified folder ' + @Folder + N'
does not exist, Please specify an existing drive:\folder ' + CAST(@rc AS VARCHAR(10));
    RAISERROR(@msg, 10, 1);
    RETURN (-1);
END;

--Create new trace file folder
SET @cmd = N'mkdir ' + @Folder + @StartDatetime;
EXEC @rc = master..xp_cmdshell @cmd, no_output;
IF (@rc != 0)
BEGIN
    SET @msg = N'Error creating trace folder : ' + CAST(@rc AS VARCHAR(10));
    SET @msg = @msg + N'SQL Server 2005 or later instance require OLE Automation to been enabled';
    RAISERROR(@msg, 10, 1);
    RETURN (-1);
END;
SET @TraceFile = @Folder + @StartDatetime + N'\trace';
EXEC @rc = sp_trace_create @TraceID OUTPUT,
                           2,
                           @TraceFile,
                           @MaxFileSize,
                           @StopTime;
IF (@rc != 0)
BEGIN
    SET @msg = N'Error creating trace : ' + CAST(@rc AS VARCHAR(10));
    RAISERROR(@msg, 10, 1);
    RETURN (-1);
END;
--> Using your saved trace file, add the '-- Set the events' section below <-- 
--> Using your saved trace file, add the '-- Set the Filters' section below <-- 
--> Customization is now completed <--
-----------------------------------------------------------------------------
-- This filter is added to exclude all profiler traces.
EXEC sp_trace_setfilter @TraceID, 10, 0, 7, N'SQL Profiler%';
-- Set the trace status to start
EXEC sp_trace_setstatus @TraceID, 1; -- start trace
SELECT 'Trace id = ',
       @TraceID,
       'Path=',
       @Folder + @StartDatetime + '\';
SELECT 'To Stop this trace sooner, execute these two commands';
SELECT ' EXEC sp_trace_setstatus @traceid = ',
       @TraceID,
       ', @status = 0; -- Stop/pause Trace';
SELECT ' EXEC sp_trace_setstatus @traceid = ',
       @TraceID,
       ', @status = 2; -- Close trace and delete it from the server';


EXEC sp_configure 'xp_cmdshell', 0
-- To update the currently configured value for this feature.
RECONFIGURE
EXEC sp_configure 'show advanced options', 0
-- To update the currently configured value for advanced options.
RECONFIGURE


RETURN;

END TRY

BEGIN CATCH
END CATCH
GO
