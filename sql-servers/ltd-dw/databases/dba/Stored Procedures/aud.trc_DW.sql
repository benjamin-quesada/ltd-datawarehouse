SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [aud].[trc_DW] @InputFolder NVARCHAR(200), @traceMinutes INT, @srvr NVARCHAR(32)
AS
BEGIN TRY
    /*
Start a timed profiler trace storing the captured output into a folder.
The folder must exist. A subfolder will be created using the start date
and time to allow for repeated running of this profile without replacing
the previous captured trace files.

Sample Command: exec aud.trc_DW 'E:\traces\ltd-dw', 3, 'LTD-DW'

CREATED DT:		20221117
CREATED BY:		B. Eichberger

*/


    SET NOCOUNT ON;

    DECLARE @SPROC VARCHAR(100);
    SET @SPROC=OBJECT_SCHEMA_NAME(@@PROCID)+'.'+OBJECT_NAME(@@PROCID);

    EXEC sp_configure 'show advanced options', 1;
    RECONFIGURE;
    EXEC sp_configure 'xp_cmdshell', 1;
    RECONFIGURE;
    EXEC sp_configure 'show advanced options', 1;
    RECONFIGURE;
    EXEC sp_configure 'Ole Automation Procedures', 1;
    RECONFIGURE;

    ------ TEST
    --DECLARE @InputFolder NVARCHAR(200) = 'E:\traces\ltd-dw', @traceMinutes INT = 3, @srvr NVARCHAR(32) = 'LTD-DW'
    ------ END TEST

    -- CoOmmented out for LTD-DW - other servers have to do this net use

    --DECLARE @netuseCmd NVARCHAR(MAX) = 'exec master..xp_cmdshell ''if exist U: (net use U: /delete)'''
    --EXEC Sp_executesql @netuseCmd

    --select @netuseCmd = 'exec master..xp_cmdshell ''net use U: \\ltd-dw\traces qQeAnUeKmgXplcwWDppE! /User:LTD\SQL_DW''' -- -P
    --PRINT @netuseCmd
    --EXEC Sp_executesql @netuseCmd
    -- Start profiler trace

    -- To change the traces duration, modify the following statement
    DECLARE @StopTime DATETIME;
    SET @StopTime=DATEADD(mi, @traceMinutes, GETDATE());
    DECLARE @StartDatetime VARCHAR(13);
    SET @StartDatetime=CONVERT(CHAR(8), GETDATE(), 112)+'_'+CAST(REPLACE(CONVERT(VARCHAR(5), GETDATE(), 108), ':', '') AS CHAR(4)); --['YYYYMMDD_HHMM']
    SELECT @StartDatetime;
    DECLARE @rc INT;
    DECLARE @TraceID INT;
    DECLARE @TraceFile NVARCHAR(100);
    DECLARE @MaxFileSize BIGINT;
    SET @MaxFileSize=50; -- The maximum trace file in megabytes
    DECLARE @cmd NVARCHAR(2000);
    DECLARE @msg NVARCHAR(200);
    DECLARE @Folder NVARCHAR(90);
    SET @Folder=@InputFolder;
    IF RIGHT(@Folder, 1)<>'\' SET @Folder=@Folder+N'\';
    -- Check if Folder exists
    PRINT @Folder;

    SET @cmd=N'dir '+@Folder;
    --PRINT @cmd

    EXEC @rc=master..xp_cmdshell @cmd, no_output;

    IF(@rc<>0)
    BEGIN
        SET @msg=N'The specified folder '+@Folder+N'
does not exist, Please specify an existing drive:\folder '+CAST(@rc AS VARCHAR(10));
        RAISERROR(@msg, 10, 1);
        --RETURN (-1);

        PRINT @msg;
    END;

    --Create new trace file folder
    SET @cmd=N'mkdir '+@Folder+@srvr+N'_'+@StartDatetime;
    PRINT @cmd;
    EXEC @rc=master..xp_cmdshell @cmd, no_output;
    IF(@rc<>0)
    BEGIN
        SET @msg=N'Error creating trace folder : '+CAST(@rc AS VARCHAR(10));
        SET @msg=@msg+N'SQL Server 2005 or later instance require OLE Automation to been enabled';
        RAISERROR(@msg, 10, 1);
        --RETURN (-1);

        PRINT @msg;
    END;
    SET @TraceFile=@Folder+@srvr+N'_'+@StartDatetime+N'\'+N'trace';
    EXEC @rc=sp_trace_create
        @TraceID OUTPUT, 2, @TraceFile, @MaxFileSize, @StopTime;
    IF(@rc<>0)
    BEGIN
        SET @msg=N'Error creating trace : '+CAST(@rc AS VARCHAR(10));
        RAISERROR(@msg, 10, 1);
    --RETURN (-1);
    END;
    --> Using your saved trace file, add the '-- Set the events' section below <-- 


    DECLARE @on BIT;
    SET @on=1;
    EXEC sp_trace_setevent @TraceID, 14, 1, @on;
    EXEC sp_trace_setevent @TraceID, 14, 9, @on;
    EXEC sp_trace_setevent @TraceID, 14, 10, @on;
    EXEC sp_trace_setevent @TraceID, 14, 11, @on;
    EXEC sp_trace_setevent @TraceID, 14, 6, @on;
    EXEC sp_trace_setevent @TraceID, 14, 12, @on;
    EXEC sp_trace_setevent @TraceID, 14, 14, @on;
    EXEC sp_trace_setevent @TraceID, 15, 11, @on;
    EXEC sp_trace_setevent @TraceID, 15, 6, @on;
    EXEC sp_trace_setevent @TraceID, 15, 9, @on;
    EXEC sp_trace_setevent @TraceID, 15, 10, @on;
    EXEC sp_trace_setevent @TraceID, 15, 12, @on;
    EXEC sp_trace_setevent @TraceID, 15, 13, @on;
    EXEC sp_trace_setevent @TraceID, 15, 14, @on;
    EXEC sp_trace_setevent @TraceID, 15, 15, @on;
    EXEC sp_trace_setevent @TraceID, 15, 16, @on;
    EXEC sp_trace_setevent @TraceID, 15, 17, @on;
    EXEC sp_trace_setevent @TraceID, 15, 18, @on;
    EXEC sp_trace_setevent @TraceID, 17, 1, @on;
    EXEC sp_trace_setevent @TraceID, 17, 9, @on;
    EXEC sp_trace_setevent @TraceID, 17, 10, @on;
    EXEC sp_trace_setevent @TraceID, 17, 11, @on;
    EXEC sp_trace_setevent @TraceID, 17, 6, @on;
    EXEC sp_trace_setevent @TraceID, 17, 12, @on;
    EXEC sp_trace_setevent @TraceID, 17, 14, @on;
    EXEC sp_trace_setevent @TraceID, 10, 9, @on;
    EXEC sp_trace_setevent @TraceID, 10, 2, @on;
    EXEC sp_trace_setevent @TraceID, 10, 10, @on;
    EXEC sp_trace_setevent @TraceID, 10, 6, @on;
    EXEC sp_trace_setevent @TraceID, 10, 11, @on;
    EXEC sp_trace_setevent @TraceID, 10, 12, @on;
    EXEC sp_trace_setevent @TraceID, 10, 13, @on;
    EXEC sp_trace_setevent @TraceID, 10, 14, @on;
    EXEC sp_trace_setevent @TraceID, 10, 15, @on;
    EXEC sp_trace_setevent @TraceID, 10, 16, @on;
    EXEC sp_trace_setevent @TraceID, 10, 17, @on;
    EXEC sp_trace_setevent @TraceID, 10, 18, @on;
    EXEC sp_trace_setevent @TraceID, 12, 1, @on;
    EXEC sp_trace_setevent @TraceID, 12, 9, @on;
    EXEC sp_trace_setevent @TraceID, 12, 11, @on;
    EXEC sp_trace_setevent @TraceID, 12, 6, @on;
    EXEC sp_trace_setevent @TraceID, 12, 10, @on;
    EXEC sp_trace_setevent @TraceID, 12, 12, @on;
    EXEC sp_trace_setevent @TraceID, 12, 13, @on;
    EXEC sp_trace_setevent @TraceID, 12, 14, @on;
    EXEC sp_trace_setevent @TraceID, 12, 15, @on;
    EXEC sp_trace_setevent @TraceID, 12, 16, @on;
    EXEC sp_trace_setevent @TraceID, 12, 17, @on;
    EXEC sp_trace_setevent @TraceID, 12, 18, @on;
    EXEC sp_trace_setevent @TraceID, 13, 1, @on;
    EXEC sp_trace_setevent @TraceID, 13, 9, @on;
    EXEC sp_trace_setevent @TraceID, 13, 11, @on;
    EXEC sp_trace_setevent @TraceID, 13, 6, @on;
    EXEC sp_trace_setevent @TraceID, 13, 10, @on;
    EXEC sp_trace_setevent @TraceID, 13, 12, @on;
    EXEC sp_trace_setevent @TraceID, 13, 14, @on;


    --> Using your saved trace file, add the '-- Set the Filters' section below <-- 

    DECLARE @intfilter INT;
    DECLARE @bigintfilter BIGINT;

    EXEC sp_trace_setfilter
        @TraceID, 10, 0, 7, N'SQL Server Profiler - 9851c630-b174-443f-8c32-e1108a7e9c5f';


    --> Customization is now completed <--
    -----------------------------------------------------------------------------
    -- This filter is added to exclude all profiler traces.
    EXEC sp_trace_setfilter @TraceID, 10, 0, 7, N'SQL Profiler%';
    -- Set the trace status to start
    EXEC sp_trace_setstatus @TraceID, 1; -- start trace
    PRINT 'Trace id = '+CAST(@TraceID AS VARCHAR(42))+' Path='+@Folder+'\';
    PRINT 'To Stop this trace sooner, execute these two commands';
    PRINT ' EXEC sp_trace_setstatus @traceid = '+CAST(@TraceID AS VARCHAR(42))+', @status = 0; '; -- Stop/pause Trace';
    PRINT ' EXEC sp_trace_setstatus @traceid = '+CAST(@TraceID AS VARCHAR(42))+', @status = 2; '; -- Close trace and delete it from the server';

    EXEC sp_configure 'show advanced options', 1;
    RECONFIGURE;
    EXEC sp_configure 'xp_cmdshell', 0;
    RECONFIGURE;


    EXEC sp_configure 'show advanced options', 1;
    RECONFIGURE;
    EXEC sp_configure 'Ole Automation Procedures', 0;
    RECONFIGURE;

    EXEC sp_configure 'show advanced options', 0;
    RECONFIGURE;

END TRY
BEGIN CATCH

    DECLARE @profile VARCHAR(255) =(SELECT TOP(1)[name] FROM msdb.dbo.sysmail_profile ORDER BY [name]);
    DECLARE
        @errormsg VARCHAR(MAX), @error INT, @message VARCHAR(MAX), @xstate INT, @errsev INT, @sub VARCHAR(255);

    SELECT
        @error=ERROR_NUMBER(), @errsev=ERROR_SEVERITY(), @message=ERROR_MESSAGE(), @xstate=XACT_STATE();

    SELECT
        @errormsg='Error in '+ISNULL(@SPROC, '')+': '+CAST(ISNULL(@error, '') AS NVARCHAR(32))+'|'+COALESCE(@message, '')+'|'+CAST(ISNULL(@xstate, '') AS NVARCHAR(32))+'|'+CAST(ISNULL(@errsev, '') AS NVARCHAR(32));

    SELECT @sub='ERROR: '+@SPROC;

    EXEC msdb.dbo.sp_send_dbmail
        @profile_name=@profile, @recipients='barb.eichberger@ltd.org', @subject=@sub, @body=@errormsg;

    RAISERROR(@errormsg, @errsev, 1);
END CATCH;
GO
