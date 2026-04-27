SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROC [webstore].[GetWebstoreOrderImport]
    @BeginDate DATE = NULL,
    @EndDate DATE = NULL


AS

BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        -- Log execution of this stored procedure for audit visibility
        DECLARE @DatabaseName sysname = DB_NAME();
        EXEC dba.aud.LogObjectActivity 
             @ObjectID = @@PROCID,
             @ObjectType = 'PROC',
             @DatabaseName = @DatabaseName;


        WITH ProductAccountMap
        AS (SELECT 'Umo/eFare Tap Card' AS ProductDescription,
                   '' AS ProjectString,
                   '' AS ProjectStringType,
                   '010.000.00.41024.4111' AS FullAccount
            UNION ALL
            SELECT 'RideSource Ticket Book',
                   '1176.Fares     .          .          ',
                   'F',
                   '015.711.01.41010.4111'
            UNION ALL
            SELECT 'Ride Source Out of Area Ticket Book',
                   '1176.Fares     .          .          ',
                   'F',
                   '015.711.01.41010.4111'
            UNION ALL
            SELECT 'Diamond Express Ticket Book',
                   '1187.Fares     .          .          ',
                   'F',
                   '015.753.01.41010.4111'
            )

        ,ParsedOrder AS (
            SELECT
                o.ID AS Id,
                o.Status AS [Status],
                o.DateCreated AS DateCreated,
                o.DateModified AS DateModified,
                o.ShippingTotal AS ShippingTotal,
                o.Total AS Total,
                o.TransactionID AS TransactionId,
                o.CreatedVia AS CreatedVia,
                o.CustomerNote AS CustomerNote,
                o.DateCompleted AS DateCompleted,
                o.DatePaid AS DatePaid,
                o.NeedsPayment AS NeedsPayment,
                -- line item fields
                li.Id               AS LineItemId,
                li.Name             AS LineItemName,
                li.ProductId,
                li.VariationId,
                li.Quantity,
                li.TaxClass,
                li.Subtotal,
                li.SubtotalTax,
                li.Total            AS LineItemTotal,
                li.TotalTax,
                li.Sku,
                li.GlobalUniqueId,
                li.Price,
                li.ParentName,
                li.ImageId,
                li.ImageSrc

            FROM Webstore.[Order_v] o
            CROSS APPLY OPENJSON(o.LineItems)
            WITH (
                Id                BIGINT          '$.id',
                Name              NVARCHAR(400)   '$.name',
                ProductId         BIGINT          '$.product_id',
                VariationId       BIGINT          '$.variation_id',
                Quantity          INT             '$.quantity',
                TaxClass          NVARCHAR(100)   '$.tax_class',

                Subtotal          DECIMAL(18,2)   '$.subtotal',
                SubtotalTax       DECIMAL(18,2)   '$.subtotal_tax',
                Total             DECIMAL(18,2)   '$.total',
                TotalTax          DECIMAL(18,2)   '$.total_tax',

                Sku               NVARCHAR(100)   '$.sku',
                GlobalUniqueId    NVARCHAR(200)   '$.global_unique_id',
                Price             DECIMAL(18,2)   '$.price',
                ParentName        NVARCHAR(400)   '$.parent_name',

                ImageId           BIGINT          '$.image.id',
                ImageSrc          NVARCHAR(2000)  '$.image.src',

                TaxesJson         NVARCHAR(MAX)   '$.taxes'     AS JSON,
                MetaDataJson      NVARCHAR(MAX)   '$.meta_data' AS JSON
            ) li
        ), StagedOrders AS (
            SELECT CAST(po.Id AS NVARCHAR(50)) AS Id,
                   po.Status,
                   po.DateCreated,
                   po.DateModified,
                   po.ShippingTotal,
                   po.Total,
                   po.TransactionId,
                   po.CreatedVia,
                   po.CustomerNote,
                   po.DateCompleted,
                   po.DatePaid,
                   po.NeedsPayment,
                   po.LineItemId,
                   po.LineItemName,
                   po.ProductId,
                   po.VariationId,
                   po.Quantity,
                   po.TaxClass,
                   po.Subtotal,
                   po.SubtotalTax,
                   po.LineItemTotal,
                   po.TotalTax,
                   po.Sku,
                   po.GlobalUniqueId,
                   po.Price,
                   po.ParentName,
                   po.ImageId,
                   po.ImageSrc, 
	               FORMAT(po.DateCreated, 'MM/dd/yyyy') AS FormattedDate,
                   pac.ProjectString,
                   pac.ProjectStringType,
                   pac.FullAccount
            FROM ParsedOrder po
            LEFT JOIN ProductAccountMap pac
            ON po.LineItemName = pac.[ProductDescription] 
            WHERE po.[Status] IN ('completed','processing','refunded')
        ), RefundedLineItems AS (
            --PARTIAL REFUNDS WILL FAIL AS THEY SHOULDN'T HAPPEN, IF THEY DO WE NEED TO ACCOUNT FOR THEM DIFFERENTLY
            SELECT so.Id,
                   so.LineItemName,
                   so.LineItemTotal AS RefundAmount,
                   CAST(r.DateCreated AS DATE) AS RefundDate
            FROM StagedOrders so
                INNER JOIN Webstore.[Refund_v] r
                    ON r.ParentID = so.Id
            WHERE JSON_VALUE(r.MetaData, '$[0].value') = 'full'
            UNION
            SELECT so.Id,
                   'Shipping/Handling',
                   so.ShippingTotal AS RefundAmount,
                   CAST(r.DateCreated AS DATE) AS RefundDate
            FROM StagedOrders so
                INNER JOIN Webstore.[Refund_v] r
                    ON r.ParentID = so.Id
            WHERE JSON_VALUE(r.MetaData, '$[0].value') = 'full'
        ), WebstoreOrderJournalDetail AS (
            --order line items credit
            SELECT 'D' AS Identifier,
                    'CR' AS [Ref 1],
                    so.ProjectStringType AS [Project String Type],
                    'R' AS [Acct Type],
                    so.ProjectString AS [Project String],
                    so.FullAccount AS [Full Account],
                    'Web ' + so.LineItemName AS [Additional Description-Line Description],
                    '0.00' AS [Debit Gross],
                    so.LineItemTotal  AS [Credit Gross],
                    'W' + CAST(so.Id AS NVARCHAR(50)) AS [Ref 2],
                    'W' + FORMAT(so.DatePaid, 'MMddyyyy') AS [Ref 3],
                    '' AS [Ref 4],
                    'Web ' + so.LineItemName AS [Comment-JE Description],
                    --fields for ordering final result
		            'Revenue Credit' AS TransactionType,
                    CAST(so.DatePaid AS DATE) AS WebstoreTransactionDate,
		            2 AS DetailSectionOrder 
            FROM StagedOrders so

            UNION ALL

            --order shipping credit
            SELECT 'D' AS Identifier,
                    'CR' AS [Ref 1],
                    '' AS [Project String Type],
                    'R' AS [Acct Type],
                    '' AS [Project String],
                    '010.000.00.41210.4111' AS [Full Account],
                    'Web Shipping/Handling' AS [Additional Description-Line Description],
                    '0.00' AS [Debit Gross],
                    so.ShippingTotal  AS [Credit Gross],
                    'W' + CAST(so.Id AS NVARCHAR(50)) AS [Ref 2],
                    'W' + FORMAT(so.DatePaid, 'MMddyyyy') AS [Ref 3],
                    '' AS [Ref 4],
                    'Web Shipping/Handling' AS [Comment-JE Description],

	                'Revenue Credit' AS TransactionType,
                    CAST(so.DatePaid AS DATE) AS WebstoreTransactionDate,
	                2 AS DetailSectionOrder 
            FROM StagedOrders so
            WHERE so.ShippingTotal <> 0
            GROUP BY so.ShippingTotal, 
                    so.DatePaid, 
                    so.Id

            UNION ALL

            --order line items & shipping debit sum
            SELECT 'D' AS Identifier,
                    'CR' AS [Ref 1],
                    '' AS [Project String Type],
                    'B' AS [Acct Type],
                    '' AS [Project String],
                    '990.000.00.10100.5200' AS [Full Account],
                    'Webstore CC Sales' AS [Additional Description-Line Description],
                    SUM(Debits.DebitAmount) AS [Debit Gross],
                    '0.00' AS [Credit Gross],
                    '' AS [Ref 2],
                    'W' + FORMAT(Debits.WebstoreTransactionDate, 'MMddyyyy') AS [Ref 3],
                    '' AS [Ref 4],
                    'Webstore CC Sales' AS [Comment-JE Description],

		            'Cash Debit' AS TransactionType,
                    Debits.WebstoreTransactionDate,
		            3 AS DetailSectionOrder
            FROM (
                SELECT so.Id,
                so.LineItemTotal AS DebitAmount,
                CAST(so.DatePaid AS DATE) AS WebstoreTransactionDate
                FROM StagedOrders so
                UNION
                SELECT so.Id,
                so.ShippingTotal AS DebitAmount,
                CAST(so.DatePaid AS DATE) 
                FROM StagedOrders so
                WHERE so.ShippingTotal <> 0
                GROUP BY so.ShippingTotal, 
                        so.DatePaid, 
                        so.Id
                ) Debits
            GROUP BY Debits.WebstoreTransactionDate

            UNION ALL
            --order refund credit
            SELECT  'D' AS Identifier,
                    'CR' AS [Ref 1],
                    '' AS [Project String Type],
                    'B' AS [Acct Type],
                    '' AS [Project String],
                    '990.000.00.10100.5200' AS [Full Account],
                    'Webstore CC Refunds' AS [Additional Description-Line Description],
                    '0.00' AS [Debit Gross],
                    SUM(r.RefundAmount) AS [Credit Gross],
                    '' AS [Ref 2],
                    'W' + FORMAT(RefundDate, 'MMddyyyy') AS [Ref 3],
                    '' AS [Ref 4],
                    'Webstore CC Refunds' AS [Comment-JE Description],
    		        'Cash Credit' AS TransactionType,
                    CAST(r.RefundDate AS DATE) AS WebstoreTransactionDate,
    		        3 AS DetailSectionOrder --have cash appear at the bottom

            FROM RefundedLineItems r
            GROUP BY r.RefundDate

            UNION ALL

            --order refund debit
            SELECT  'D',
                    'CR',
                    '',
                    'R',
                    '',
                    '010.000.00.41115.4111', --refund revenue account
                    'Web Refund ' + r.LineItemName,
                    CAST(r.RefundAmount AS NVARCHAR(50)),
                    '0.00',
                    'CR' + CAST(Id AS NVARCHAR(50)),
                    'W' + FORMAT(RefundDate, 'MMddyyyy') AS [Ref 3],
                    '',
                    'Web Refund ' + r.LineItemName,
    		        'Revenue Debit' AS TransactionType,
                    CAST(r.RefundDate AS DATE),
    		        2 AS DetailSectionOrder --Revenue as mid section
            FROM RefundedLineItems r


        ), WebstoreOrderJournalHeader AS (

        --header
            SELECT 'H' 											           AS Identifier,
                   'CR'										               AS [Ref 1],
                   FORMAT(wojd.WebstoreTransactionDate, 'MM/dd/yyyy')      AS [Project String Type],
	               CASE
	                 WHEN MONTH(wojd.WebstoreTransactionDate) < 7 THEN
		                 CAST((MONTH(wojd.WebstoreTransactionDate) + 6) AS NVARCHAR(50))
	                 ELSE
		                 CAST((MONTH(wojd.WebstoreTransactionDate) - 6) AS NVARCHAR(50))
	               END AS FiscalMonth,
	               CASE
	                 WHEN MONTH(wojd.WebstoreTransactionDate) < 7 THEN
		                 CAST(YEAR(wojd.WebstoreTransactionDate) AS NVARCHAR(50))
	                 ELSE
		                 CAST((YEAR(wojd.WebstoreTransactionDate) + 1) AS NVARCHAR(50))
	               END AS FiscalYear,
                   wojd.[Ref 3]										       AS [Full Account],
                   ''											           AS [Additional Description-Line Description],
                   ''											           AS [Debit Gross],
                   ''											           AS [Credit Gross],
                   ''											           AS [Ref 2],
                   ''													   AS [Ref 3],
                   ''											           AS [Ref 4],
                   ''											           AS [Comment-JE Description],
		           '' AS TransactionType,
                   WebstoreTransactionDate,
		           1 AS DetailSectionOrder
            FROM WebstoreOrderJournalDetail wojd
            GROUP BY wojd.WebstoreTransactionDate,
	               CASE
	                 WHEN MONTH(wojd.WebstoreTransactionDate) < 7 THEN
		                 MONTH(wojd.WebstoreTransactionDate) + 6
	                 ELSE
		                 MONTH(wojd.WebstoreTransactionDate) - 6
	               END,
	               CASE
	                 WHEN MONTH(wojd.WebstoreTransactionDate) < 7 THEN
		                 YEAR(wojd.WebstoreTransactionDate)
	                 ELSE
		                 YEAR(wojd.WebstoreTransactionDate) + 1
	               END,
                   wojd.[Ref 3]	
        ), FullImport AS (
        SELECT WebstoreOrderJournalHeader.Identifier,
               WebstoreOrderJournalHeader.[Ref 1],
               WebstoreOrderJournalHeader.[Project String Type],
               WebstoreOrderJournalHeader.FiscalMonth AS [Acct Type],
               WebstoreOrderJournalHeader.FiscalYear AS [Project String],
               WebstoreOrderJournalHeader.[Full Account],
               WebstoreOrderJournalHeader.[Additional Description-Line Description],
               WebstoreOrderJournalHeader.[Debit Gross],
               WebstoreOrderJournalHeader.[Credit Gross],
               WebstoreOrderJournalHeader.[Ref 2],
               WebstoreOrderJournalHeader.[Ref 3],
               WebstoreOrderJournalHeader.[Ref 4],
               WebstoreOrderJournalHeader.[Comment-JE Description],
               WebstoreOrderJournalHeader.TransactionType,
               WebstoreOrderJournalHeader.WebstoreTransactionDate,
               WebstoreOrderJournalHeader.DetailSectionOrder FROM WebstoreOrderJournalHeader
        UNION
        SELECT WebstoreOrderJournalDetail.Identifier,
               WebstoreOrderJournalDetail.[Ref 1],
               WebstoreOrderJournalDetail.[Project String Type],
               WebstoreOrderJournalDetail.[Acct Type],
               WebstoreOrderJournalDetail.[Project String],
               WebstoreOrderJournalDetail.[Full Account],
               WebstoreOrderJournalDetail.[Additional Description-Line Description],
               CAST(WebstoreOrderJournalDetail.[Debit Gross] AS VARCHAR(50)),
               CAST(WebstoreOrderJournalDetail.[Credit Gross] AS VARCHAR(50)),
               WebstoreOrderJournalDetail.[Ref 2],
               WebstoreOrderJournalDetail.[Ref 3],
               WebstoreOrderJournalDetail.[Ref 4],
               WebstoreOrderJournalDetail.[Comment-JE Description],
               WebstoreOrderJournalDetail.TransactionType,
               WebstoreOrderJournalDetail.WebstoreTransactionDate,
               WebstoreOrderJournalDetail.DetailSectionOrder FROM WebstoreOrderJournalDetail

        )

        SELECT FullImport.Identifier,
               FullImport.[Ref 1],
               FullImport.[Project String Type],
               FullImport.[Acct Type],
               FullImport.[Project String],
               FullImport.[Full Account],
               FullImport.[Additional Description-Line Description],
               FullImport.[Debit Gross],
               FullImport.[Credit Gross],
               FullImport.[Ref 2],
               FullImport.[Ref 3],
               FullImport.[Ref 4],
               FullImport.[Comment-JE Description],
               FullImport.TransactionType,
               FullImport.WebstoreTransactionDate,
               FullImport.DetailSectionOrder
        FROM FullImport
        WHERE FullImport.WebstoreTransactionDate BETWEEN ISNULL(@BeginDate, '1900-01-01') AND ISNULL(@EndDate, '9999-12-31')
        ORDER BY FullImport.[WebstoreTransactionDate],
                 FullImport.DetailSectionOrder,
                 FullImport.[TransactionType],
                 FullImport.[Ref 2],
                 TRY_CAST(FullImport.[Credit Gross] AS DECIMAL(10, 2)) DESC;

    END TRY


    /*==============================================================
      ERROR HANDLING
    ===============================================================*/

    BEGIN CATCH

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
GRANT EXECUTE ON  [webstore].[GetWebstoreOrderImport] TO [public]
GO
