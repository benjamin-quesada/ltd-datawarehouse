SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE PROCEDURE [hastus].[merge_avl_pbs]
AS
/*-----------LTD_GLOSSARY---------------
created by	:  B Eichberger
created dt	:  20260407
purpose		:  merge hastus avl files for pbs (poster by stop)
use			:  exec hastus.merge_avl_pbs

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

SELECT @cnt = (SELECT COUNT(*) FROM hastus.avl_pbs_raw);
IF (@cnt > 0)
-- check to see if there is any data in the table before processing
BEGIN

DECLARE @sdt DATETIME2 = SYSDATETIME();
DECLARE @outputTbl TABLE (actionNm VARCHAR(32));

DROP TABLE IF EXISTS #pbs
SELECT distinct q.* INTO #pbs 
    FROM (SELECT * FROM hastus.avl_pbs_raw r
            ) q

DROP TABLE IF EXISTS #rollMerge
SELECT rn = ROW_NUMBER() OVER (ORDER BY filedate), filedate INTO #rollMerge
                                            FROM (SELECT DISTINCT filedate FROM #pbs) p

DECLARE @i INT = 1
DECLARE @r INT = (SELECT MAX(rn) FROM #rollmerge)

while @i <= @r
BEGIN

   DECLARE @currFileDt DATE = (SELECT filedate FROM #rollmerge WHERE rn = @i)
   DROP TABLE IF EXISTS #prepMerge
   SELECT * INTO #prepMerge FROM #pbs WHERE filedate = @currFileDt
   
    MERGE -- TRUNCATE TABLE -- select * from 
        hastus.avl_pbs AS t
    USING -- select * from 
   #prepMerge AS s
    ON (t.poster_stop_id = s.poster_stop_id)
    WHEN MATCHED AND (
			ISNULL(t.poster_description, '') <> ISNULL(s.poster_description, '')
			OR ISNULL(t.poster_format, '') <> ISNULL(s.poster_format, '')
			OR ISNULL(t.poster_route, '') <> ISNULL(s.poster_route, '')
			OR ISNULL(t.poster_pattern, '') <> ISNULL(s.poster_pattern, '')
			OR ISNULL(t.poster_prod_method, '') <> ISNULL(s.poster_prod_method, '')
			OR ISNULL(t.poster_type, '') <> ISNULL(s.poster_type, '')
		)
	    THEN UPDATE SET t.poster_description = s.poster_description
		    ,t.poster_format = s.poster_format
		    ,t.poster_route = s.poster_route
		    ,t.poster_pattern = s.poster_pattern
		    ,t.poster_prod_method = s.poster_prod_method
		    ,t.poster_type = s.poster_type
		    ,t.record_updated_date = s.filedate
    WHEN NOT MATCHED BY TARGET
	    THEN INSERT
		     (
			     poster_stop_id
			    ,poster_description
			    ,poster_format
			    ,poster_route
			    ,poster_pattern
			    ,poster_prod_method
			    ,poster_type
		     )
		     VALUES
		     (s.poster_stop_id, s.poster_description, s.poster_format, s.poster_route, s.poster_pattern, s.poster_prod_method, s.poster_type)
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
        SELECT 'PBS',
               'ltd_dw.hastus.avl_pbs',
               'HASTUS',
               @prg,
               ISNULL(@ins, 0),
               ISNULL(@upd, 0),
               ISNULL(@del, 0),
               @sdt,
               SYSDATETIME();

    DROP TABLE #prepMerge


SELECT @i = @i + 1
IF @i > @r
BREAK
    ELSE CONTINUE
    END
    
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
