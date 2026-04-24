SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROC [webstore].[EtlMergeRefunds]
    @PerPage           INT             = 100,
    @BaseUrl           NVARCHAR(500)   = 'https://www.ltd.org',
    @Endpoint          NVARCHAR(100)   = 'wp-json/wc/v3/refunds',
    @Credential        SYSNAME         = 'https://www.ltd.org/wp-json/wc/v3',
    @MaxPage           INT             = 100
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ETLProcessActivityID INT = NULL;

    BEGIN TRY

        /*==============================================================
          AUDIT + ETL PROCESS INITIALIZATION
        ==============================================================*/

        DECLARE @database_name SYSNAME = DB_NAME();
        EXEC dba.aud.LogObjectActivity
             @ObjectID = @@PROCID,
             @ObjectType = 'PROC',
             @DatabaseName = @database_name;

        DECLARE @ETLProcessID INT;

        SELECT @ETLProcessID = ep.EtlProcessID
        FROM dbo.EtlProcess ep
        WHERE ep.ProcessName = 'Webstore - Load Refunds from API';

        IF @ETLProcessID IS NULL
        BEGIN
            ;THROW 50003, 'ETLProcessID not found for ProcessName: Webstore - Load Refunds from API', 1;
        END

        EXEC @ETLProcessActivityID = dbo.ETLProcessActivity_insert
             @ETLProcessID = @ETLProcessID;


        /*==============================================================
          API EXTRACTION (PAGINATED LOOP)
        ==============================================================*/

        DECLARE @Page INT = 1;
        DECLARE @TimeoutSeconds SMALLINT = 230;

        DECLARE @QueryString NVARCHAR(MAX);
        DECLARE @RequestUrl NVARCHAR(4000);
        DECLARE @ApiRequestID INT;
        DECLARE @TotalPages INT = NULL;

        DECLARE @Response NVARCHAR(MAX);
        DECLARE @HttpStatusCode INT;
        DECLARE @ReturnCode INT;

        -- Enable external REST endpoint execution for this session
        EXEC sys.sp_configure 'external rest endpoint', 1;
        RECONFIGURE;

        WHILE (1 = 1)
        BEGIN
            -- Reset response variables for each iteration
            SET @Response = NULL;
            SET @HttpStatusCode = NULL;
            SET @ReturnCode = NULL;

            -- Safety check to prevent infinite loops
            IF @Page > @MaxPage
            BEGIN
                ;THROW 50000, 'Exceeded maximum page limit. Possible infinite loop.', 1;
            END

            -- Construct query string with pagination parameters
            SET @QueryString = '';

            IF @PerPage IS NOT NULL
                SET @QueryString += '&per_page=' + CAST(@PerPage AS VARCHAR(10));

            IF @Page IS NOT NULL
                SET @QueryString += '&page=' + CAST(@Page AS VARCHAR(10));

            IF LEN(@QueryString) > 0
                SET @QueryString = '?' + STUFF(@QueryString, 1, 1, '');

            SET @RequestUrl = @BaseUrl + '/' + @Endpoint + @QueryString;

            -- Log the API request
            INSERT INTO dbo.ApiRequest
            (
                EtlProcessActivityID,
                SourceSystem,
                EndpointName,
                RequestUrl,
                HttpMethod,
                CredentialName,
                TimeoutSeconds
            )
            VALUES
            (
                @ETLProcessActivityID,
                'WooCommerce',
                'refunds',
                @RequestUrl,
                'GET',
                @Credential,
                @TimeoutSeconds
            );

            SET @ApiRequestID = SCOPE_IDENTITY();

            EXEC @ReturnCode = sys.sp_invoke_external_rest_endpoint
                 @url = @RequestUrl,
                 @method = 'GET',
                 @timeout = @TimeoutSeconds,
                 @credential = @Credential,
                 @response = @Response OUTPUT;

            IF @Response IS NULL
            BEGIN
                ;THROW 50002, 'API call returned NULL response.', 1;
            END

            SET @HttpStatusCode = COALESCE(
                TRY_CAST(JSON_VALUE(@Response, '$.response.status.http.code') AS INT),
                TRY_CAST(JSON_VALUE(@Response, '$.data.status') AS INT),
                @ReturnCode
            );

            INSERT INTO dbo.ApiResponse
            (
                ApiRequestID,
                HttpStatusCode,
                Response
            )
            VALUES
            (
                @ApiRequestID,
                @HttpStatusCode,
                @Response
            );

            IF ISNULL(@HttpStatusCode, 0) >= 400
            BEGIN
                DECLARE @ErrorMessage NVARCHAR(2048) = CONCAT(
                    'API request failed. Status: ',
                    CAST(@HttpStatusCode AS VARCHAR(10)),
                    '. Message: ',
                    ISNULL(JSON_VALUE(@Response, '$.message'), 'Unknown error')
                );

                ;THROW 50001, @ErrorMessage, 1;
            END

            SET @TotalPages = TRY_CAST(JSON_VALUE(@Response, '$.response.headers."x-wp-totalpages"') AS INT);

            IF NOT EXISTS
            (
                SELECT 1
                FROM OPENJSON(@Response, '$.result')
            )
            OR (@TotalPages IS NOT NULL AND @Page >= @TotalPages)
            BEGIN
                BREAK;
            END

            SET @Page += 1;
        END


        /*==============================================================
          STAGING LOAD (RAW JSON -> RELATIONAL)
        ==============================================================*/

        TRUNCATE TABLE Webstore.RefundStage;

        INSERT INTO Webstore.RefundStage
        (
            EtlProcessActivityID,
            ApiRequestID,
            ID,
            ParentID,
            DateCreated,
            DateCreatedGmt,
            Amount,
            Reason,
            RefundedBy,
            RefundedPayment,
            MetaData,
            LineItems,
            ShippingLines,
            TaxLines,
            FeeLines,
            Links
        )
        SELECT
            ar.EtlProcessActivityID,
            ar.ApiRequestID,
            r.id,
            r.parent_id,
            r.date_created,
            r.date_created_gmt,
            r.amount,
            r.reason,
            r.refunded_by,
            r.refunded_payment,
            r.meta_data,
            r.line_items,
            r.shipping_lines,
            r.tax_lines,
            r.fee_lines,
            r._links
        FROM dbo.ApiResponse apr
        JOIN dbo.ApiRequest ar
            ON ar.ApiRequestID = apr.ApiRequestID
        CROSS APPLY OPENJSON(apr.Response, '$.result')
        WITH
        (
            id                BIGINT         '$.id',
            parent_id         BIGINT         '$.parent_id',
            date_created      DATETIME       '$.date_created',
            date_created_gmt  DATETIME       '$.date_created_gmt',
            amount            DECIMAL(18,2)  '$.amount',
            reason            NVARCHAR(MAX)  '$.reason',
            refunded_by       BIGINT         '$.refunded_by',
            refunded_payment  BIT            '$.refunded_payment',
            meta_data         NVARCHAR(MAX)  '$.meta_data' AS JSON,
            line_items        NVARCHAR(MAX)  '$.line_items' AS JSON,
            shipping_lines    NVARCHAR(MAX)  '$.shipping_lines' AS JSON,
            tax_lines         NVARCHAR(MAX)  '$.tax_lines' AS JSON,
            fee_lines         NVARCHAR(MAX)  '$.fee_lines' AS JSON,
            _links            NVARCHAR(MAX)  '$._links' AS JSON
        ) AS r
        WHERE ar.EtlProcessActivityID = @ETLProcessActivityID
          AND apr.Response IS NOT NULL;

        IF EXISTS
        (
            SELECT ID
            FROM Webstore.RefundStage
            GROUP BY ID
            HAVING COUNT(*) > 1
        )
        BEGIN
            ;THROW 50004, 'Duplicate refund IDs found in Webstore.RefundStage.', 1;
        END


        /*==============================================================
          MERGE INTO PRODUCTION TABLE
        ==============================================================*/

        DECLARE @cnt INT;

        SELECT @cnt = COUNT(*)
        FROM Webstore.RefundStage;

        DECLARE @sdt DATETIME = SYSDATETIME();

        DECLARE @outputTbl TABLE
        (
            actionNm VARCHAR(32)
        );

        MERGE Webstore.Refund AS dst
        USING Webstore.RefundStage AS src
            ON dst.ID = src.ID

        WHEN MATCHED AND
        (
               ISNULL(dst.ParentID, 0) <> ISNULL(src.ParentID, 0)
            OR ISNULL(dst.DateCreated, '19000101') <> ISNULL(src.DateCreated, '19000101')
            OR ISNULL(dst.DateCreatedGmt, '19000101') <> ISNULL(src.DateCreatedGmt, '19000101')
            OR ISNULL(dst.Amount, 0) <> ISNULL(src.Amount, 0)
            OR ISNULL(dst.Reason, '') <> ISNULL(src.Reason, '')
            OR ISNULL(dst.RefundedBy, 0) <> ISNULL(src.RefundedBy, 0)
            OR ISNULL(dst.RefundedPayment, 0) <> ISNULL(src.RefundedPayment, 0)
            --OR ISNULL(dst.MetaData, '') <> ISNULL(src.MetaData, '')
            OR ISNULL(dst.LineItems, '') <> ISNULL(src.LineItems, '')
            OR ISNULL(dst.ShippingLines, '') <> ISNULL(src.ShippingLines, '')
            OR ISNULL(dst.TaxLines, '') <> ISNULL(src.TaxLines, '')
            OR ISNULL(dst.FeeLines, '') <> ISNULL(src.FeeLines, '')
            OR ISNULL(dst.Links, '') <> ISNULL(src.Links, '')
        )
        THEN
            UPDATE SET
                dst.ParentID = src.ParentID,
                dst.DateCreated = src.DateCreated,
                dst.DateCreatedGmt = src.DateCreatedGmt,
                dst.Amount = src.Amount,
                dst.Reason = src.Reason,
                dst.RefundedBy = src.RefundedBy,
                dst.RefundedPayment = src.RefundedPayment,
                dst.MetaData = src.MetaData,
                dst.LineItems = src.LineItems,
                dst.ShippingLines = src.ShippingLines,
                dst.TaxLines = src.TaxLines,
                dst.FeeLines = src.FeeLines,
                dst.Links = src.Links,
                dst.EtlProcessActivityID = src.EtlProcessActivityID,
                dst.ApiRequestID = src.ApiRequestID,
                dst.RecordUpdatedDate = GETDATE()

        WHEN NOT MATCHED BY TARGET THEN
            INSERT
            (
                ID,
                ParentID,
                DateCreated,
                DateCreatedGmt,
                Amount,
                Reason,
                RefundedBy,
                RefundedPayment,
                MetaData,
                LineItems,
                ShippingLines,
                TaxLines,
                FeeLines,
                Links,
                EtlProcessActivityID,
                ApiRequestID
            )
            VALUES
            (
                src.ID,
                src.ParentID,
                src.DateCreated,
                src.DateCreatedGmt,
                src.Amount,
                src.Reason,
                src.RefundedBy,
                src.RefundedPayment,
                src.MetaData,
                src.LineItems,
                src.ShippingLines,
                src.TaxLines,
                src.FeeLines,
                src.Links,
                src.EtlProcessActivityID,
                src.ApiRequestID
            )

        WHEN NOT MATCHED BY SOURCE THEN
            DELETE

        OUTPUT $action
        INTO @outputTbl;

        DECLARE @ins INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'INSERT');
        DECLARE @upd INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'UPDATE');
        DECLARE @del INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'DELETE');
        DECLARE @row INT = ISNULL(@ins, 0) + ISNULL(@upd, 0);

        INSERT ltd_dw.process.MergeLogs
        (
            MergeCode,
            ObjectDestination,
            ObjectSource,
            ObjectProgram,
            recInsert,
            recUpdate,
            recDelete,
            MergeBeginDatetime,
            MergeEndDatetime
        )
        VALUES
        (
            'WOOAPI',
            'Staging.Webstore.Refund',
            'Staging.Webstore.RefundStage',
            @@SERVERNAME + '.Staging.EtlMergeRefunds',
            ISNULL(@ins, 0),
            ISNULL(@upd, 0),
            ISNULL(@del, 0),
            @sdt,
            SYSDATETIME()
        );

        EXEC dbo.ETLProcessActivity_update
             @ETLProcessActivityID = @ETLProcessActivityID,
             @row = @row;

        EXEC sys.sp_configure 'external rest endpoint', 0;
        RECONFIGURE;

    END TRY

    /*==============================================================
      ERROR HANDLING
    ==============================================================*/

    BEGIN CATCH

        IF @ETLProcessActivityID IS NOT NULL
        BEGIN
            EXEC dbo.ETLProcessActivity_update
                 @ETLProcessActivityID = @ETLProcessActivityID,
                 @row = 0;
        END

        EXEC sys.sp_configure 'external rest endpoint', 0;
        RECONFIGURE;

        DECLARE @SPROC VARCHAR(255) =
            QUOTENAME(OBJECT_SCHEMA_NAME(@@PROCID)) + '.' + QUOTENAME(OBJECT_NAME(@@PROCID));

        DECLARE @profile VARCHAR(255) = (
                    SELECT TOP 1 name
                    FROM msdb.dbo.sysmail_profile
                ),
                @errormsg VARCHAR(MAX),
                @error INT,
                @message VARCHAR(MAX),
                @xstate INT,
                @errsev INT,
                @sub VARCHAR(255);

        SELECT  @error = ERROR_NUMBER(),
                @errsev = ERROR_SEVERITY(),
                @message = ERROR_MESSAGE(),
                @xstate = XACT_STATE();

        SELECT @errormsg =
            'Error in ' + ISNULL(@SPROC, '') + ':'
            + CAST(ISNULL(@error, '') AS NVARCHAR(32)) + '|'
            + COALESCE(@message, '') + '|'
            + CAST(ISNULL(@xstate, '') AS NVARCHAR(32)) + '|'
            + CAST(ISNULL(@errsev, '') AS NVARCHAR(32));

        SELECT @sub = 'ERROR: ' + @SPROC;

        EXEC msdb.dbo.sp_send_dbmail
             @profile_name = @profile,
             @recipients = 'data@ltd.org',
             @subject = @sub,
             @body = @errormsg;

        RAISERROR(@errormsg, @errsev, 1);
    END CATCH;

END
GO
