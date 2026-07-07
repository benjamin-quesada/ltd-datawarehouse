SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE PROCEDURE [hastus].[merge_avl_pnm]
AS
/*-----------LTD_GLOSSARY---------------
created by	:  B Eichberger
created dt	:  20260423
purpose		:  merge hastus avl files for pnm (pattern names for BSI et al)
use			:  exec hastus.merge_avl_pnm

			*/


SET NOCOUNT ON;

BEGIN TRY

DECLARE @SPROC VARCHAR(100);
SET @SPROC = OBJECT_SCHEMA_NAME(@@PROCID) + '.' + OBJECT_NAME(@@PROCID);


INSERT INTO dba.aud.Object_Activity(server_name, database_name, host_name, [System_User], object_name, client_net_address, local_net_address, auth_Scheme, last_read, last_write, most_recent_sql_handle, Timestamp, object_type)
SELECT DISTINCT @@SERVERNAME, DB_NAME(), HOST_NAME(), SYSTEM_USER, @SPROC, client_net_address, local_net_address, auth_scheme, last_read, last_write, most_recent_sql_handle, CURRENT_TIMESTAMP AS Timestamp, 'PROC'
FROM sys.dm_exec_connections
WHERE session_id=@@SPID;

DECLARE @cnt INT;

SELECT @cnt = (SELECT COUNT(*) FROM hastus.avl_pnm_raw);
IF (@cnt > 0)
-- check to see if there is any data in the table before processing
BEGIN

DECLARE @currFileDt DATE = (SELECT DISTINCT filedate FROM hastus.avl_pnm_raw)
DECLARE @sdt DATETIME2 = SYSDATETIME();
DECLARE @outputTbl TABLE (actionNm VARCHAR(32));

DROP TABLE IF EXISTS #prepMerge
SELECT distinct q.* INTO #prepMerge 
    FROM (SELECT * FROM hastus.avl_pnm_raw r
            ) q
 
    MERGE -- TRUNCATE TABLE -- select * from 
        hastus.avl_pnm AS t
    USING -- select * from 
   #prepMerge AS s
    ON (t.[ppat_id] = s.[ppat_id]
    AND t.[filedate] = s.[filedate]
    AND t.[ppat_direction] = s.[ppat_direction]
    AND t.excluded IS NULL 
    )
    WHEN MATCHED AND (
			ISNULL(t.[ppat_description], '') <> ISNULL(s.[ppat_description], '')
			OR ISNULL(t.[ppat_public_access], '') <> ISNULL(s.[ppat_public_access], '')
			OR ISNULL(t.[ppat_owner], '') <> ISNULL(s.[ppat_owner], '')
		)
	    THEN UPDATE SET t.[ppat_description] = s.[ppat_description]
		    ,t.[ppat_public_access] = s.[ppat_public_access]
		    ,t.[ppat_owner] = s.[ppat_owner]
		    ,t.record_updated_date = s.filedate
    WHEN NOT MATCHED BY TARGET
	    THEN INSERT
		     (
	           [filedate]
              ,[ppat_id]
              ,[ppat_direction]
              ,[ppat_description]
              ,[ppat_public_access]
              ,[ppat_owner]
		     )
		     VALUES
		     ( s.[filedate]
              ,s.[ppat_id]
              ,s.[ppat_direction]
              ,s.[ppat_description]
              ,s.[ppat_public_access]
              ,s.[ppat_owner])
    WHEN NOT MATCHED BY SOURCE THEN UPDATE
    SET t.excluded = @currFileDt
    OUTPUT $action INTO @outputTbl;

    
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
        SELECT 'PNM',
               'ltd_dw.hastus.avl_pnm',
               'HASTUS',
               @prg,
               ISNULL(@ins, 0),
               ISNULL(@upd, 0),
               ISNULL(@del, 0),
               @sdt,
               SYSDATETIME();

    DROP TABLE #prepMerge;


    
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
