SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [ops].[merge_run]
AS

/*-----------LTD_GLOSSARY---------------
UPDATED BY:	Sopheap Suy
UPDATED DT: 04/10/2025 
purpose	:	merge ops.run from [LTD-OPS].midas.dbo.run
use		:	exec ops.merge_run

purpose	 :  Add object activities on who, what, when call this object
            write this data to aud.object_activity table everytime it's called */

SET NOCOUNT ON;

DECLARE @SPROC VARCHAR(100);
SET @SPROC = OBJECT_SCHEMA_NAME(@@PROCID) + '.' + OBJECT_NAME(@@PROCID);

INSERT INTO dba.[aud].[Object_Activity]
(
    [server_name],
    [database_name],
    [host_name],
    [System_User],
    [object_name],
    [client_net_address],
    [local_net_address],
    [auth_Scheme],
    [last_read],
    [last_write],
    [most_recent_sql_handle],
    [Timestamp],
    object_type
)
SELECT DISTINCT
       @@SERVERNAME,
       DB_NAME(),
       HOST_NAME(),
       SYSTEM_USER,
       @SPROC,
       client_net_address,
       local_net_address,
       auth_scheme,
       last_read,
       last_write,
       most_recent_sql_handle,
       CURRENT_TIMESTAMP AS [Timestamp],
       'PROC'
FROM sys.dm_exec_connections
WHERE session_id = @@SPID;

BEGIN TRY


    DECLARE @sdt DATETIME2 = SYSDATETIME();
    DECLARE @outputTbl TABLE
    (
        actionNm VARCHAR(32)
    );


    SELECT run_SID,
           runNumber COLLATE SQL_Latin1_General_CP1_CI_AS runNumber,
           division COLLATE  SQL_Latin1_General_CP1_CI_AS division,
           dayType COLLATE  SQL_Latin1_General_CP1_CI_AS dayType,
           schedVersion COLLATE  SQL_Latin1_General_CP1_CI_AS schedVersion,
           scheduleName COLLATE SQL_Latin1_General_CP1_CI_AS scheduleName,
           runPriority,
           runType COLLATE  SQL_Latin1_General_CP1_CI_AS runType,
           appOrigin COLLATE  SQL_Latin1_General_CP1_CI_AS appOrigin,
           runFlags,
           beginDate,
           endDate,
           runStatus COLLATE SQL_Latin1_General_CP1_CI_AS runStatus,
           runcutFlags ,
           primaryRoute COLLATE SQL_Latin1_General_CP1_CI_AS primaryRoute
    INTO #empOps 
    FROM [LTD-OPS].midas.dbo.run WITH (NOLOCK);

    MERGE ops.run AS dst
    USING #empOps AS src
    ON (dst.run_SID = src.run_SID)
    WHEN MATCHED AND (
                         ISNULL(dst.runNumber, '') <> ISNULL(src.runNumber , '')
                         OR dst.division <> src.division
                         OR ISNULL(dst.dayType, '') <> ISNULL(src.dayType, '')
                         OR dst.schedVersion <> src.schedVersion
                         OR dst.scheduleName <> src.scheduleName
                         OR ISNULL(dst.runPriority, '') <> ISNULL(src.runPriority, '')
                         OR ISNULL(dst.runType, '') <> ISNULL(src.runType, '')
                         OR ISNULL(dst.appOrigin, '') <> ISNULL(src.appOrigin, '')
                         OR dst.runFlags <> src.runFlags
                         OR ISNULL(dst.beginDate, '') <> ISNULL(src.beginDate, '')
                         OR ISNULL(dst.endDate, '') <> ISNULL(src.endDate, '')
                         OR ISNULL(dst.runStatus, '') <> ISNULL(src.runStatus, '')
                         OR dst.runcutFlags <> src.runcutFlags
                         OR ISNULL(dst.primaryRoute, '') <> ISNULL(src.primaryRoute, '')
                     ) THEN
        UPDATE SET dst.runNumber = src.runNumber,
                   dst.division = src.division,
                   dst.dayType = src.dayType,
                   dst.schedVersion = src.schedVersion,
                   dst.scheduleName = src.scheduleName,
                   dst.runPriority = src.runPriority,
                   dst.runType = src.runType,
                   dst.appOrigin = src.appOrigin,
                   dst.runFlags = src.runFlags,
                   dst.beginDate = src.beginDate,
                   dst.endDate = src.endDate,
                   dst.runStatus = src.runStatus,
                   dst.runcutFlags = src.runcutFlags,
                   dst.primaryRoute = src.primaryRoute,
                   dst.record_updated_date = GETDATE()
    WHEN NOT MATCHED BY TARGET THEN
        INSERT
        (
            run_SID,
            runNumber,
            division,
            dayType,
            schedVersion,
            scheduleName,
            runPriority,
            runType,
            appOrigin,
            runFlags,
            beginDate,
            endDate,
            runStatus,
            runcutFlags,
            primaryRoute
        )
        VALUES
        (src.run_SID, src.runNumber, src.division, src.dayType, src.schedVersion, src.scheduleName, src.runPriority,
         src.runType, src.appOrigin, src.runFlags, src.beginDate, src.endDate, src.runStatus, src.runcutFlags,
         src.primaryRoute)
    WHEN NOT MATCHED BY SOURCE THEN
        DELETE
    OUTPUT $action
    INTO @outputTbl;

    DECLARE @ins INT =
            (
                SELECT COUNT(*)FROM @outputTbl WHERE actionNm = 'INSERT'
            );
    DECLARE @upd INT =
            (
                SELECT COUNT(*)FROM @outputTbl WHERE actionNm = 'UPDATE'
            );
    DECLARE @del INT =
            (
                SELECT COUNT(*)FROM @outputTbl WHERE actionNm = 'DELETE'
            );
    DECLARE @prg VARCHAR(90) = @@SERVERNAME + '.ltd_dw.' + @SPROC;

    INSERT process.MergeLogs
    (
        [MergeCode],
        [ObjectDestination],
        [ObjectSource],
        [ObjectProgram],
        [recInsert],
        [recUpdate],
        [recDelete],
        [MergeBeginDatetime],
        [MergeEndDatetime]
    )
    SELECT 'OPSRun',
           'ltd_dw.ops.run',
           '[LTD-OPS].midas.dbo.run',
           @prg,
           ISNULL(@ins, 0),
           ISNULL(@upd, 0),
           ISNULL(@del, 0),
           @sdt,
           SYSDATETIME();



END TRY
BEGIN CATCH

    DECLARE @profile VARCHAR(255) =
            (
                SELECT [name] FROM msdb.dbo.sysmail_profile
            );
    DECLARE @errormsg VARCHAR(MAX),
            @error INT,
            @message VARCHAR(MAX),
            @xstate INT,
            @errsev INT,
            @sub VARCHAR(255);

    SELECT @error = ERROR_NUMBER(),
           @errsev = ERROR_SEVERITY(),
           @message = ERROR_MESSAGE(),
           @xstate = XACT_STATE();

    SELECT @errormsg
        = 'Error in ' + ISNULL(@SPROC, '') + ':' + CAST(ISNULL(@error, '') AS NVARCHAR(32)) + '|'
          + COALESCE(@message, '') + '|' + CAST(ISNULL(@xstate, '') AS NVARCHAR(32)) + '|'
          + CAST(ISNULL(@errsev, '') AS NVARCHAR(32));

    SELECT @sub = 'ERROR: ' + @SPROC;

    EXEC msdb.dbo.sp_send_dbmail @profile_name = @profile,
                                 @recipients = 'data@ltd.org',
                                 @subject = @sub,
                                 @body = @errormsg;

    RAISERROR(@errormsg, @errsev, 1);
END CATCH;
GO
