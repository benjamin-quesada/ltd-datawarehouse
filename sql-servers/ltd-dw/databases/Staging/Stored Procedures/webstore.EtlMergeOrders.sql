SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROC [webstore].[EtlMergeOrders]
    @AfterDate         DATETIME        = NULL,  -- start date filter for API (inclusive)
    @BeforeDate        DATETIME        = NULL,  -- end date filter for API (exclusive)
    @ModifiedAfter     DATETIME        = NULL,  -- optional filter to only pull orders modified after this date
    @PerPage           INT             = 100,   -- page size for API requests
    @OrderStatus       VARCHAR(50)     = NULL,  -- optional order status filter
    @BaseUrl           NVARCHAR(500)   = 'https://www.ltd.org',
    @Endpoint          NVARCHAR(100)   = 'wp-json/wc/v3/orders',
    @Credential        SYSNAME         = 'https://www.ltd.org/wp-json/wc/v3',
    @MaxPage           INT             = 100,    -- safety limit to prevent infinite paging
    @DeleteMissingRows BIT             = 0      -- whether to hard delete rows from the production table that are missing from the source API response (use when doing a full load with no date filters)
AS

BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        /*==============================================================
          AUDIT + ETL PROCESS INITIALIZATION
        ===============================================================*/

        -- Log execution of this stored procedure for audit visibility
        DECLARE @database_name sysname = DB_NAME();
        EXEC dba.aud.LogObjectActivity 
             @ObjectID = @@PROCID,
             @ObjectType = 'PROC',
             @DatabaseName = @database_name;

        -- Look up the ETL process definition row used for this procedure
        DECLARE @ETLProcessID INT;
        DECLARE @ETLProcessActivityID INT;

        SELECT @ETLProcessID = ep.EtlProcessID
        FROM dbo.EtlProcess ep
        WHERE ep.ProcessName = 'Webstore - Load Orders from API';

        -- Fail fast if the process definition is missing
        IF @ETLProcessID IS NULL
        BEGIN
            ;THROW 50003, 'ETLProcessID not found for ProcessName: Webstore - Load Orders from API', 1;
        END

        -- Create a new ETL activity row for this execution
        EXEC @ETLProcessActivityID = dbo.ETLProcessActivity_insert @ETLProcessID = @ETLProcessID;


        /*==============================================================
          API EXTRACTION (PAGINATED LOOP)
        ===============================================================*/

        DECLARE @Page INT = 1;
        DECLARE @TimeoutSeconds SMALLINT = 230;

        DECLARE @QueryString NVARCHAR(MAX);
        DECLARE @RequestUrl NVARCHAR(4000);
        DECLARE @ApiRequestID INT;
        DECLARE @TotalPages INT = NULL;

        DECLARE @Response NVARCHAR(MAX);
        DECLARE @HttpStatusCode INT;
        DECLARE @ReturnCode INT;

        -- Enable SQL Server external REST endpoint execution for this run
        EXEC sys.sp_configure 'external rest endpoint', 1;
        RECONFIGURE;

        WHILE (1 = 1)
        BEGIN
            -- Reset per-page variables so values do not carry across iterations
            SET @Response = NULL;
            SET @HttpStatusCode = NULL;
            SET @ReturnCode = NULL;

            -- Safety check in case pagination metadata is wrong or missing
            IF @Page > @MaxPage
            BEGIN
                ;THROW 50000, 'Exceeded maximum page limit. Possible infinite loop.', 1;
            END

            -- Build the query string dynamically so only non-null filters are included
            SET @QueryString = '';

            IF @AfterDate IS NOT NULL
                SET @QueryString += '&after=' + CONVERT(VARCHAR(19), @AfterDate, 126);

            IF @BeforeDate IS NOT NULL
                SET @QueryString += '&before=' + CONVERT(VARCHAR(19), @BeforeDate, 126);

            IF @ModifiedAfter IS NOT NULL
                SET @QueryString += '&modified_after=' + CONVERT(VARCHAR(19), @ModifiedAfter, 126);

            IF @OrderStatus IS NOT NULL
                SET @QueryString += '&status=' + @OrderStatus;

            IF @PerPage IS NOT NULL
                SET @QueryString += '&per_page=' + CAST(@PerPage AS VARCHAR(10));

            IF @Page IS NOT NULL
                SET @QueryString += '&page=' + CAST(@Page AS VARCHAR(10));

            IF LEN(@QueryString) > 0
                SET @QueryString = '?' + STUFF(@QueryString, 1, 1, '');

            -- Construct the full endpoint URL for this page
            SET @RequestUrl = @BaseUrl + '/' + @Endpoint + @QueryString;

            -- Log the outbound API request for traceability
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
                'orders',
                @RequestUrl,
                'GET',
                @Credential,
                @TimeoutSeconds
            );

            SET @ApiRequestID = SCOPE_IDENTITY();

            -- Execute the API request and capture the raw response payload
            EXEC @ReturnCode = sys.sp_invoke_external_rest_endpoint
                 @url = @RequestUrl,
                 @method = 'GET',
                 @timeout = @TimeoutSeconds,
                 @credential = @Credential,
                 @response = @Response OUTPUT;

            -- A null response is treated as a hard failure
            IF @Response IS NULL
            BEGIN
                ;THROW 50002, 'API call returned NULL response.', 1;
            END

            -- Determine the HTTP status code from either:
            -- 1) normal wrapped success response
            -- 2) error payload returned by the API
            -- 3) stored procedure return code as a fallback
            SET @HttpStatusCode = COALESCE(
                TRY_CAST(JSON_VALUE(@Response, '$.response.status.http.code') AS INT),
                TRY_CAST(JSON_VALUE(@Response, '$.data.status') AS INT),
                @ReturnCode
            );

            -- Log the response exactly as received for replay/debugging later
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

            -- Stop immediately if the API returned an error payload/status
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

            -- Read total page count from the WooCommerce response headers
            SET @TotalPages = TRY_CAST(JSON_VALUE(@Response, '$.response.headers."x-wp-totalpages"') AS INT);

            -- Exit paging loop when:
            -- 1) the current page has no results
            -- 2) the last page has been reached
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
        ===============================================================*/

        -- This is a transient stage table, so clear it before loading current-run data
        TRUNCATE TABLE Webstore.OrderStage;

        -- Parse each stored API response into one row per order in the stage table
        INSERT INTO Webstore.OrderStage
        (
            EtlProcessActivityID,
            ApiRequestID,
            ID,
            ParentID,
            Status,
            Currency,
            Version,
            PricesIncludeTax,
            DateCreated,
            DateModified,
            DiscountTotal,
            DiscountTax,
            ShippingTotal,
            ShippingTax,
            CartTax,
            Total,
            TotalTax,
            CustomerID,
            OrderKey,
            Billing,
            Shipping,
            PaymentMethod,
            PaymentMethodTitle,
            TransactionID,
            CustomerIpAddress,
            CustomerUserAgent,
            CreatedVia,
            CustomerNote,
            DateCompleted,
            DatePaid,
            CartHash,
            Number,
            MetaData,
            LineItems,
            TaxLines,
            ShippingLines,
            FeeLines,
            CouponLines,
            Refunds,
            PaymentUrl,
            IsEditable,
            NeedsPayment,
            NeedsProcessing,
            DateCreatedGmt,
            DateModifiedGmt,
            DateCompletedGmt,
            DatePaidGmt,
            CurrencySymbol,
            Links
        )
        SELECT
            ar.EtlProcessActivityID,
            ar.ApiRequestID,
            o.id,
            o.parent_id,
            o.status,
            o.currency,
            o.version,
            o.prices_include_tax,
            o.date_created,
            o.date_modified,
            o.discount_total,
            o.discount_tax,
            o.shipping_total,
            o.shipping_tax,
            o.cart_tax,
            o.total,
            o.total_tax,
            o.customer_id,
            o.order_key,
            o.billing,
            o.shipping,
            o.payment_method,
            o.payment_method_title,
            o.transaction_id,
            o.customer_ip_address,
            o.customer_user_agent,
            o.created_via,
            o.customer_note,
            o.date_completed,
            o.date_paid,
            o.cart_hash,
            o.number,
            o.meta_data,
            o.line_items,
            o.tax_lines,
            o.shipping_lines,
            o.fee_lines,
            o.coupon_lines,
            o.refunds,
            o.payment_url,
            o.is_editable,
            o.needs_payment,
            o.needs_processing,
            o.date_created_gmt,
            o.date_modified_gmt,
            o.date_completed_gmt,
            o.date_paid_gmt,
            o.currency_symbol,
            o._links
        FROM dbo.ApiResponse apr
        JOIN dbo.ApiRequest ar
            ON ar.ApiRequestID = apr.ApiRequestID
        CROSS APPLY OPENJSON(apr.Response, '$.result')
        WITH (
            id                    BIGINT          '$.id',
            parent_id             BIGINT          '$.parent_id',
            status                NVARCHAR(50)    '$.status',
            currency              NVARCHAR(10)    '$.currency',
            version               NVARCHAR(20)    '$.version',
            prices_include_tax    BIT             '$.prices_include_tax',
            date_created          DATETIME        '$.date_created',
            date_modified         DATETIME        '$.date_modified',
            discount_total        DECIMAL(18, 2)  '$.discount_total',
            discount_tax          DECIMAL(18, 2)  '$.discount_tax',
            shipping_total        DECIMAL(18, 2)  '$.shipping_total',
            shipping_tax          DECIMAL(18, 2)  '$.shipping_tax',
            cart_tax              DECIMAL(18, 2)  '$.cart_tax',
            total                 DECIMAL(18, 2)  '$.total',
            total_tax             DECIMAL(18, 2)  '$.total_tax',
            customer_id           BIGINT          '$.customer_id',
            order_key             NVARCHAR(100)   '$.order_key',
            billing               NVARCHAR(MAX)   '$.billing' AS JSON,
            shipping              NVARCHAR(MAX)   '$.shipping' AS JSON,
            payment_method        NVARCHAR(100)   '$.payment_method',
            payment_method_title  NVARCHAR(255)   '$.payment_method_title',
            transaction_id        NVARCHAR(100)   '$.transaction_id',
            customer_ip_address   NVARCHAR(45)    '$.customer_ip_address',
            customer_user_agent   NVARCHAR(400)   '$.customer_user_agent',
            created_via           NVARCHAR(50)    '$.created_via',
            customer_note         NVARCHAR(MAX)   '$.customer_note',
            date_completed        DATETIME        '$.date_completed',
            date_paid             DATETIME        '$.date_paid',
            cart_hash             NVARCHAR(100)   '$.cart_hash',
            number                NVARCHAR(50)    '$.number',
            meta_data             NVARCHAR(MAX)   '$.meta_data' AS JSON,
            line_items            NVARCHAR(MAX)   '$.line_items' AS JSON,
            tax_lines             NVARCHAR(MAX)   '$.tax_lines' AS JSON,
            shipping_lines        NVARCHAR(MAX)   '$.shipping_lines' AS JSON,
            fee_lines             NVARCHAR(MAX)   '$.fee_lines' AS JSON,
            coupon_lines          NVARCHAR(MAX)   '$.coupon_lines' AS JSON,
            refunds               NVARCHAR(MAX)   '$.refunds' AS JSON,
            payment_url           NVARCHAR(MAX)   '$.payment_url',
            is_editable           BIT             '$.is_editable',
            needs_payment         BIT             '$.needs_payment',
            needs_processing      BIT             '$.needs_processing',
            date_created_gmt      DATETIME        '$.date_created_gmt',
            date_modified_gmt     DATETIME        '$.date_modified_gmt',
            date_completed_gmt    DATETIME        '$.date_completed_gmt',
            date_paid_gmt         DATETIME        '$.date_paid_gmt',
            currency_symbol       NVARCHAR(10)    '$.currency_symbol',
            _links                NVARCHAR(MAX)   '$._links' AS JSON
        ) AS o
        WHERE ar.EtlProcessActivityID = @ETLProcessActivityID
          AND apr.Response IS NOT NULL;

        -- MERGE assumes one source row per order ID; fail if stage has duplicates
        IF EXISTS
        (
            SELECT ID
            FROM Webstore.OrderStage
            GROUP BY ID
            HAVING COUNT(*) > 1
        )
        BEGIN
            ;THROW 50004, 'Duplicate order IDs found in Webstore.OrderStage.', 1;
        END


        /*==============================================================
          MERGE INTO PRODUCTION TABLE
        ===============================================================*/

        --check min created dates in stage table to determine what date to filter for production table to limit the number of rows being compared in the merge statement
        DECLARE @MinStageCreatedDate DATETIME
        select @MinStageCreatedDate = MIN(DateCreated) from Webstore.OrderStage


        DECLARE @cnt INT;

        SELECT @cnt = COUNT(*)
        FROM Webstore.OrderStage;

        -- Only merge when the stage table contains data for this run
        IF (@cnt > 0)
        BEGIN
            DECLARE @sdt DATETIME = SYSDATETIME();

            -- Capture merge actions so inserted and updated row counts can be logged
            DECLARE @outputTbl TABLE
            (
                actionNm VARCHAR(32)
            );

            MERGE Webstore.[Order] AS dst
            USING Webstore.OrderStage AS src
                ON dst.ID = src.ID
                AND dst.DateCreated >= @MinStageCreatedDate  -- only consider production rows created since the earliest created order in the stage table

            -- Update existing rows only when one or more tracked columns changed
            WHEN MATCHED AND
            (
                   ISNULL(dst.ParentID, 0) <> ISNULL(src.ParentID, 0)
                OR ISNULL(dst.Status, '') <> ISNULL(src.Status, '')
                OR ISNULL(dst.Currency, '') <> ISNULL(src.Currency, '')
                OR ISNULL(dst.Version, '') <> ISNULL(src.Version, '')
                OR ISNULL(dst.PricesIncludeTax, 0) <> ISNULL(src.PricesIncludeTax, 0)
                OR ISNULL(dst.DateCreated, '19000101') <> ISNULL(src.DateCreated, '19000101')
                OR ISNULL(dst.DateModified, '19000101') <> ISNULL(src.DateModified, '19000101')
                OR ISNULL(dst.DiscountTotal, 0) <> ISNULL(src.DiscountTotal, 0)
                OR ISNULL(dst.DiscountTax, 0) <> ISNULL(src.DiscountTax, 0)
                OR ISNULL(dst.ShippingTotal, 0) <> ISNULL(src.ShippingTotal, 0)
                OR ISNULL(dst.ShippingTax, 0) <> ISNULL(src.ShippingTax, 0)
                OR ISNULL(dst.CartTax, 0) <> ISNULL(src.CartTax, 0)
                OR ISNULL(dst.Total, 0) <> ISNULL(src.Total, 0)
                OR ISNULL(dst.TotalTax, 0) <> ISNULL(src.TotalTax, 0)
                OR ISNULL(dst.CustomerID, 0) <> ISNULL(src.CustomerID, 0)
                OR ISNULL(dst.OrderKey, '') <> ISNULL(src.OrderKey, '')
                OR ISNULL(dst.Billing, '') <> ISNULL(src.Billing, '')
                OR ISNULL(dst.Shipping, '') <> ISNULL(src.Shipping, '')
                OR ISNULL(dst.PaymentMethod, '') <> ISNULL(src.PaymentMethod, '')
                OR ISNULL(dst.PaymentMethodTitle, '') <> ISNULL(src.PaymentMethodTitle, '')
                OR ISNULL(dst.TransactionID, '') <> ISNULL(src.TransactionID, '')
                OR ISNULL(dst.CustomerIpAddress, '') <> ISNULL(src.CustomerIpAddress, '')
                OR ISNULL(dst.CustomerUserAgent, '') <> ISNULL(src.CustomerUserAgent, '')
                OR ISNULL(dst.CreatedVia, '') <> ISNULL(src.CreatedVia, '')
                OR ISNULL(dst.CustomerNote, '') <> ISNULL(src.CustomerNote, '')
                OR ISNULL(dst.DateCompleted, '19000101') <> ISNULL(src.DateCompleted, '19000101')
                OR ISNULL(dst.DatePaid, '19000101') <> ISNULL(src.DatePaid, '19000101')
                OR ISNULL(dst.CartHash, '') <> ISNULL(src.CartHash, '')
                OR ISNULL(dst.Number, '') <> ISNULL(src.Number, '')
                --OR ISNULL(dst.MetaData, '') <> ISNULL(src.MetaData, '')
                OR ISNULL(dst.LineItems, '') <> ISNULL(src.LineItems, '')
                OR ISNULL(dst.TaxLines, '') <> ISNULL(src.TaxLines, '')
                OR ISNULL(dst.ShippingLines, '') <> ISNULL(src.ShippingLines, '')
                OR ISNULL(dst.FeeLines, '') <> ISNULL(src.FeeLines, '')
                OR ISNULL(dst.CouponLines, '') <> ISNULL(src.CouponLines, '')
                OR ISNULL(dst.Refunds, '') <> ISNULL(src.Refunds, '')
                OR ISNULL(dst.PaymentUrl, '') <> ISNULL(src.PaymentUrl, '')
                OR ISNULL(dst.IsEditable, 0) <> ISNULL(src.IsEditable, 0)
                OR ISNULL(dst.NeedsPayment, 0) <> ISNULL(src.NeedsPayment, 0)
                OR ISNULL(dst.NeedsProcessing, 0) <> ISNULL(src.NeedsProcessing, 0)
                OR ISNULL(dst.DateCreatedGmt, '19000101') <> ISNULL(src.DateCreatedGmt, '19000101')
                OR ISNULL(dst.DateModifiedGmt, '19000101') <> ISNULL(src.DateModifiedGmt, '19000101')
                OR ISNULL(dst.DateCompletedGmt, '19000101') <> ISNULL(src.DateCompletedGmt, '19000101')
                OR ISNULL(dst.DatePaidGmt, '19000101') <> ISNULL(src.DatePaidGmt, '19000101')
                OR ISNULL(dst.CurrencySymbol, '') <> ISNULL(src.CurrencySymbol, '')
                OR ISNULL(dst.Links, '') <> ISNULL(src.Links, '')
            )
            THEN
                UPDATE SET
                    dst.ParentID = src.ParentID,
                    dst.Status = src.Status,
                    dst.Currency = src.Currency,
                    dst.Version = src.Version,
                    dst.PricesIncludeTax = src.PricesIncludeTax,
                    dst.DateCreated = src.DateCreated,
                    dst.DateModified = src.DateModified,
                    dst.DiscountTotal = src.DiscountTotal,
                    dst.DiscountTax = src.DiscountTax,
                    dst.ShippingTotal = src.ShippingTotal,
                    dst.ShippingTax = src.ShippingTax,
                    dst.CartTax = src.CartTax,
                    dst.Total = src.Total,
                    dst.TotalTax = src.TotalTax,
                    dst.CustomerID = src.CustomerID,
                    dst.OrderKey = src.OrderKey,
                    dst.Billing = src.Billing,
                    dst.Shipping = src.Shipping,
                    dst.PaymentMethod = src.PaymentMethod,
                    dst.PaymentMethodTitle = src.PaymentMethodTitle,
                    dst.TransactionID = src.TransactionID,
                    dst.CustomerIpAddress = src.CustomerIpAddress,
                    dst.CustomerUserAgent = src.CustomerUserAgent,
                    dst.CreatedVia = src.CreatedVia,
                    dst.CustomerNote = src.CustomerNote,
                    dst.DateCompleted = src.DateCompleted,
                    dst.DatePaid = src.DatePaid,
                    dst.CartHash = src.CartHash,
                    dst.Number = src.Number,
                    dst.MetaData = src.MetaData,
                    dst.LineItems = src.LineItems,
                    dst.TaxLines = src.TaxLines,
                    dst.ShippingLines = src.ShippingLines,
                    dst.FeeLines = src.FeeLines,
                    dst.CouponLines = src.CouponLines,
                    dst.Refunds = src.Refunds,
                    dst.PaymentUrl = src.PaymentUrl,
                    dst.IsEditable = src.IsEditable,
                    dst.NeedsPayment = src.NeedsPayment,
                    dst.NeedsProcessing = src.NeedsProcessing,
                    dst.DateCreatedGmt = src.DateCreatedGmt,
                    dst.DateModifiedGmt = src.DateModifiedGmt,
                    dst.DateCompletedGmt = src.DateCompletedGmt,
                    dst.DatePaidGmt = src.DatePaidGmt,
                    dst.CurrencySymbol = src.CurrencySymbol,
                    dst.Links = src.Links,
                    dst.EtlProcessActivityID = src.EtlProcessActivityID,
                    dst.ApiRequestID = src.ApiRequestID,
                    dst.RecordUpdatedDate = GETDATE()

            -- Insert new orders that do not yet exist in the destination table
            WHEN NOT MATCHED BY TARGET THEN
                INSERT
                (
                    ID,
                    ParentID,
                    Status,
                    Currency,
                    Version,
                    PricesIncludeTax,
                    DateCreated,
                    DateModified,
                    DiscountTotal,
                    DiscountTax,
                    ShippingTotal,
                    ShippingTax,
                    CartTax,
                    Total,
                    TotalTax,
                    CustomerID,
                    OrderKey,
                    Billing,
                    Shipping,
                    PaymentMethod,
                    PaymentMethodTitle,
                    TransactionID,
                    CustomerIpAddress,
                    CustomerUserAgent,
                    CreatedVia,
                    CustomerNote,
                    DateCompleted,
                    DatePaid,
                    CartHash,
                    Number,
                    MetaData,
                    LineItems,
                    TaxLines,
                    ShippingLines,
                    FeeLines,
                    CouponLines,
                    Refunds,
                    PaymentUrl,
                    IsEditable,
                    NeedsPayment,
                    NeedsProcessing,
                    DateCreatedGmt,
                    DateModifiedGmt,
                    DateCompletedGmt,
                    DatePaidGmt,
                    CurrencySymbol,
                    Links,
                    EtlProcessActivityID,
                    ApiRequestID
                )
                VALUES
                (
                    src.ID,
                    src.ParentID,
                    src.Status,
                    src.Currency,
                    src.Version,
                    src.PricesIncludeTax,
                    src.DateCreated,
                    src.DateModified,
                    src.DiscountTotal,
                    src.DiscountTax,
                    src.ShippingTotal,
                    src.ShippingTax,
                    src.CartTax,
                    src.Total,
                    src.TotalTax,
                    src.CustomerID,
                    src.OrderKey,
                    src.Billing,
                    src.Shipping,
                    src.PaymentMethod,
                    src.PaymentMethodTitle,
                    src.TransactionID,
                    src.CustomerIpAddress,
                    src.CustomerUserAgent,
                    src.CreatedVia,
                    src.CustomerNote,
                    src.DateCompleted,
                    src.DatePaid,
                    src.CartHash,
                    src.Number,
                    src.MetaData,
                    src.LineItems,
                    src.TaxLines,
                    src.ShippingLines,
                    src.FeeLines,
                    src.CouponLines,
                    src.Refunds,
                    src.PaymentUrl,
                    src.IsEditable,
                    src.NeedsPayment,
                    src.NeedsProcessing,
                    src.DateCreatedGmt,
                    src.DateModifiedGmt,
                    src.DateCompletedGmt,
                    src.DatePaidGmt,
                    src.CurrencySymbol,
                    src.Links,
                    src.EtlProcessActivityID,
                    src.ApiRequestID
                )

            OUTPUT $action
            INTO @outputTbl;

            -- Summarize merge action counts
            DECLARE @ins INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'INSERT');
            DECLARE @upd INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'UPDATE');
            DECLARE @row INT = ISNULL(@ins, 0) + ISNULL(@upd, 0);
            DECLARE @del INT = 0;

            -- Optionally hard delete production rows that are missing from the source API response when doing a full load with no date filters
            IF (@DeleteMissingRows = 1 AND @AfterDate IS NULL AND @BeforeDate IS NULL AND @ModifiedAfter IS NULL)
            BEGIN
                DELETE dst
                FROM Webstore.[Order] AS dst
                LEFT JOIN Staging.Webstore.OrderStage AS src
                    ON dst.ID = src.ID
                WHERE src.ID IS NULL
                SET @del = @@ROWCOUNT;
            END


            -- Log merge results for operational visibility
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
                'Staging.Webstore.[Order]',
                'Staging.Webstore.OrderStage',
                @@SERVERNAME + '.Staging.EtlMergeOrders',
                ISNULL(@ins, 0),
                ISNULL(@upd, 0),
                ISNULL(@del, 0),
                @sdt,
                SYSDATETIME()
            );

            -- Mark ETL activity complete and store inserted + updated row count
            EXEC dbo.ETLProcessActivity_update
                 @ETLProcessActivityID = @ETLProcessActivityID,
                 @row = @row;

        END
        ELSE
        BEGIN
            -- No rows were staged, but the ETL activity still needs to be closed out
            EXEC dbo.ETLProcessActivity_update
                 @ETLProcessActivityID = @ETLProcessActivityID,
                 @row = 0;
        END

        -- Disable external REST endpoint feature after successful completion
        EXEC sys.sp_configure 'external rest endpoint', 0;
        RECONFIGURE;

    END TRY


    /*==============================================================
      ERROR HANDLING
    ===============================================================*/

    BEGIN CATCH

        -- Close out the ETL activity if it was started before the failure occurred
        IF @ETLProcessActivityID IS NOT NULL
        BEGIN
            EXEC dbo.ETLProcessActivity_update
                 @ETLProcessActivityID = @ETLProcessActivityID,
                 @row = 0;
        END

        -- Disable external REST endpoint feature even when the procedure fails
        EXEC sys.sp_configure 'external rest endpoint', 0;
        RECONFIGURE;

        -- Build procedure-qualified name for alerting/logging
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

        -- Capture SQL error details
        SELECT  @error = ERROR_NUMBER(),
                @errsev = ERROR_SEVERITY(),
                @message = ERROR_MESSAGE(),
                @xstate = XACT_STATE();

        -- Build an email-friendly error payload
        SELECT @errormsg =
            'Error in ' + ISNULL(@SPROC, '') + ':'
            + CAST(ISNULL(@error, '') AS NVARCHAR(32)) + '|'
            + COALESCE(@message, '') + '|'
            + CAST(ISNULL(@xstate, '') AS NVARCHAR(32)) + '|'
            + CAST(ISNULL(@errsev, '') AS NVARCHAR(32));

        SELECT @sub = 'ERROR: ' + @SPROC;

        -- Notify the data team of the failure
        EXEC msdb.dbo.sp_send_dbmail
             @profile_name = @profile,
             @recipients = 'data@ltd.org',
             @subject = @sub,
             @body = @errormsg;

        -- Re-raise the error so SQL Agent / callers still see the failure
        RAISERROR(@errormsg, @errsev, 1);
    END CATCH;

END
GO
