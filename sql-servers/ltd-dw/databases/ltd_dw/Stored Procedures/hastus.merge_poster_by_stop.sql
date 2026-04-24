SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE      PROCEDURE [hastus].[merge_poster_by_stop]
AS

/*-----------LTD_GLOSSARY---------------
UPDATED BY:	Sopheap Suy
UPDATED DT: 05/20/2025 
purpose	:	merge hastus.poster_by_stop from hastus.poster_by_stop_stg
use		:	exec hastus.merge_poster_by_stop

purpose	 :  Add object activities on who, what, when call this object
            write this data to aud.object_activity table everytime it's called */

SET NOCOUNT ON;

DECLARE @SPROC VARCHAR(100);
SET @SPROC = OBJECT_SCHEMA_NAME(@@PROCID) + '.' + OBJECT_NAME(@@PROCID);

INSERT INTO dba.aud.Object_Activity
(
    server_name,
    database_name,
    host_name,
    [System_User],
    object_name,
    client_net_address,
    local_net_address,
    auth_Scheme,
    last_read,
    last_write,
    most_recent_sql_handle,
    Timestamp,
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
       CURRENT_TIMESTAMP AS Timestamp,
       'PROC'
FROM sys.dm_exec_connections
WHERE session_id = @@SPID;

BEGIN TRY

    DECLARE @cnt INT;

    SELECT @cnt = COUNT(*)
    FROM hastus.poster_by_stop_stg;
    IF (@cnt > 0)
    -- check to see if there is any data in the table before processing
    BEGIN

        DECLARE @sdt DATETIME2 = SYSDATETIME();
        DECLARE @outputTbl TABLE
        (
            actionNm VARCHAR(32)
        );

        MERGE hastus.poster_by_stop AS dst
        USING hastus.poster_by_stop_stg AS src
        ON (dst.poster_stop_id = src.poster_stop_id)
        WHEN MATCHED AND (
                             ISNULL(dst.poster_description, '') <> ISNULL(src.poster_description, '')
                             OR ISNULL(dst.poster_format, '') <> ISNULL(src.poster_format, '')
                             OR ISNULL(dst.poster_route, '') <> ISNULL(src.poster_route, '')
                             OR ISNULL(dst.poster_pattern, '') <> ISNULL(src.poster_pattern, '')
                             OR ISNULL(dst.poster_prod_method, '') <> ISNULL(src.poster_prod_method, '')
                             OR ISNULL(dst.poster_type, '') <> ISNULL(src.poster_type, '')
                           ) THEN
            UPDATE SET dst.poster_description = src.poster_description,
                       dst.poster_format = src.poster_format,
                       dst.poster_route = src.poster_route,
                       dst.poster_pattern = src.poster_pattern,
                       dst.poster_prod_method = src.poster_prod_method,
                       dst.poster_type = src.poster_type,
                       dst.record_updated_date = SYSDATETIME()
                       
        WHEN NOT MATCHED BY TARGET THEN
            INSERT
            (
                poster_stop_id,
                poster_description,
                poster_format,
                poster_route,
                poster_pattern,
                poster_prod_method,
                poster_type
                
            )
            VALUES
            (src.poster_stop_id, src.poster_description, src.poster_format, src.poster_route, src.poster_pattern,
             src.poster_prod_method, src.poster_type)
        WHEN NOT MATCHED BY SOURCE THEN DELETE
        OUTPUT $action
        INTO @outputTbl;

        TRUNCATE TABLE hastus.poster_by_stop_stg;
/*
        DECLARE @ins INT = (SELECT COUNT(*)FROM @outputTbl WHERE actionNm = 'INSERT' );
        DECLARE @upd INT =( SELECT COUNT(*)FROM @outputTbl WHERE actionNm = 'UPDATE' );
        DECLARE @del INT = ( SELECT COUNT(*)FROM @outputTbl WHERE actionNm = 'DELETE' );
        DECLARE @prg VARCHAR(90) = @@SERVERNAME + '.ltd_dw.' + @SPROC;

        INSERT process.mergeLogs
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
        SELECT 'POAPI',
               'ltd_dw.hastus.poster_by_stop',
               'hastus.poster_by_stop_stg',
               @prg,
               ISNULL(@ins, 0),
               ISNULL(@upd, 0),
               ISNULL(@del, 0),
               @sdt,
               SYSDATETIME();
	*/
    END;

END TRY
BEGIN CATCH

    DECLARE @profile VARCHAR(255) =
            (
                SELECT TOP 1 name FROM msdb.dbo.sysmail_profile
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
