SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE VIEW [webstore].[webstore_transactions_journal_import] AS



-- CTE for base order details
WITH  charge_code_account_map
AS (SELECT '855' AS charge_code,
           '010.000.00.41024.4111' AS full_account
    UNION ALL
    SELECT '1810',
           '015.711.01.41010.4111'
    UNION ALL
    SELECT '1815',
           '015.711.01.41010.4111'
    UNION ALL
    SELECT '1820',
           '015.753.01.41010.4111'
    UNION ALL
    SELECT '1980',
           '010.000.00.41210.4111'),

order_details
AS (
        SELECT CAST(oc.id AS NVARCHAR(50)) AS id,
               oc.order_id,
               oc.product_id,
               oc.qty,
               oc.product_name,
               oc.price,
               oc.discount,
               ccm.charge_code AS charge_code,
               oc.orig_price,
               oc.price * oc.qty AS total,
			   o.transaction_datetime,
			   o.updated_by,
			   o.last_updated,
			   ccam.[full_account],
			   'W' + FORMAT(o.transaction_datetime, 'MMddyyyy') AS ref3,
			   FORMAT(o.transaction_datetime, 'MM/dd/yyyy') AS formatted_date,
			   CASE
				   WHEN MONTH(o.transaction_datetime) < 7 THEN
					   MONTH(o.transaction_datetime) + 6
				   ELSE
					   MONTH(o.transaction_datetime) - 6
			   END AS fiscal_month,
			   CASE
				   WHEN MONTH(o.transaction_datetime) < 7 THEN
					   YEAR(o.transaction_datetime)
				   ELSE
					   YEAR(o.transaction_datetime) + 1
			   END AS fiscal_year
        FROM [LTD-FINANCE].[pos_dw].[dbo].[orders_cart] oc
			LEFT JOIN [LTD-FINANCE].[pos_dw].[dbo].[orders] o 
				ON o.id = oc.order_id
			LEFT JOIN [LTD-FINANCE].[pos_dw].[dbo].[charge_code_map] ccm
                ON ccm.product_name = oc.product_name
			LEFT JOIN charge_code_account_map ccam
				ON ccm.[charge_code] = ccam.[charge_code] 
        UNION ALL
        SELECT CAST(o.id AS NVARCHAR(50)) + 's',
               o.id,
               0,
               1,
               'Shipping/Handling',
               o.shipping_cost,
               0,
               '1980',
               o.shipping_cost,
               o.shipping_cost,
			   o.transaction_datetime,
			   o.updated_by,
			   o.last_updated,
			   '010.000.00.41210.4111' AS full_account,
			   'W' + FORMAT(o.transaction_datetime, 'MMddyyyy') AS ref3,
			   FORMAT(o.transaction_datetime, 'MM/dd/yyyy') AS formatted_date,
			   CASE
				   WHEN MONTH(o.transaction_datetime) < 7 THEN
					   MONTH(o.transaction_datetime) + 6
				   ELSE
					   MONTH(o.transaction_datetime) - 6
			   END AS fiscal_month,
			   CASE
				   WHEN MONTH(o.transaction_datetime) < 7 THEN
					   YEAR(o.transaction_datetime)
				   ELSE
					   YEAR(o.transaction_datetime) + 1
			   END AS fiscal_year
        FROM [LTD-FINANCE].[pos_dw].[dbo].[orders] o
        WHERE o.shipping_cost > 0
			),

		
header AS (
    SELECT CAST(transaction_datetime AS DATE) AS webstore_transaction_date,     
           'H' 											           AS Identifier,
           'CR'										               AS [Ref 1],
           formatted_date								           AS [project string type],
           CAST(fiscal_month AS NVARCHAR(50))			           AS [Acct type],
           CAST(fiscal_year AS NVARCHAR(50))			           AS [project string],
           ref3										               AS [full account],
           ''											           AS [additional description-Line Description],
           ''											           AS [Debit Gross],
           ''											           AS [Credit Gross],
           ''											           AS [Ref 2],
           ''													   AS [ref3],
           ''											           AS [Ref 4],
           ''											           AS [comment-JE Description],
		   '' AS transaction_type,
		   1 AS detail_section_order
    FROM order_details
    GROUP BY CAST(transaction_datetime AS DATE),
             formatted_date,
             CAST(fiscal_month AS NVARCHAR(50)),
             CAST(fiscal_year AS NVARCHAR(50)),
             ref3
)
,
revenue_detail AS 
(
	--revenue credit
    SELECT CAST(transaction_datetime AS DATE) AS webstore_transaction_date,
           'D' AS Identifier,
           'CR' AS [Ref 1],
           '' AS [project string type],
           'R' AS [Acct type],
           '' AS [project string],
           full_account AS [full account],
           'Web ' + product_name AS [additional description-Line Description],
           '0.00' AS [Debit Gross],
           total  AS [Credit Gross],
           'CR' + CAST(order_id AS NVARCHAR(50)) AS [Ref 2],
           ref3,
           '' AS [Ref 4],
           'Web ' + product_name AS [comment-JE Description],
			'Revenue Credit' AS transaction_type,
			2 AS detail_section_order --Revenue as mid section
    FROM order_details
    UNION ALL
	--revenue debit
    SELECT CAST(last_updated AS DATE),
           'D',
           'CR',
           '',
           'R',
           '',
           '010.000.00.41115.4111', --refund revenue account
           'Web Refund ' + product_name,
           CAST(total AS NVARCHAR(50)),
           '0.00',
           'CR' + CAST(order_id AS NVARCHAR(50)),
           ref3,
           '',
           'Web Refund ' + product_name,
		   'Revenue Debit' AS transaction_type,
		   2 AS detail_section_order --Revenue as mid section
    FROM order_details od
	WHERE CHARINDEX('credit', od.updated_by) <> 0 
),

cash_detail AS (
		--cash credit
		SELECT CAST(transaction_datetime AS DATE) AS webstore_transaction_date,
               'D' AS Identifier,
               'CR' AS [Ref 1],
               '' AS [project string type],
               'B' AS [Acct type],
               '' AS [project string],
               '990.000.00.10100.1110' AS [full account],
               'Webstore CC Sales' AS [additional description-Line Description],
               total AS [Debit Gross],
               '0.00' AS [Credit Gross],
               '' AS [Ref 2],
               ref3 AS [Ref 3],
               '' AS [Ref 4],
               'Webstore CC Sales' AS [comment-JE Description],
			   'Cash Debit' AS transaction_type,
			   3 AS detail_section_order --have cash appear at the bottom
        FROM order_details
		UNION ALL
		--cash debit
        SELECT CAST(last_updated AS DATE) AS webstore_transaction_date,
               'D' AS Identifier,
               'CR' AS [Ref 1],
               '' AS [project string type],
               'B' AS [Acct type],
               '' AS [project string],
               '990.000.00.10100.1110' AS [full account],
               'Webstore CC Refunds' AS [additional description-Line Description],
               '0.00' AS [Debit Gross],
               total AS [Credit Gross],
               '' AS [Ref 2],
               ref3 AS [Ref 3],
               '' AS [Ref 4],
               'Webstore CC Refunds' AS [comment-JE Description],
			   'Cash Credit' AS transaction_type,
			   3 AS detail_section_order --have cash appear at the bottom
        FROM order_details od
		WHERE CHARINDEX('credit', od.updated_by) <> 0 
)
, cash_sum AS (

SELECT [cash_detail].[webstore_transaction_date],
       [cash_detail].[Identifier],
       [cash_detail].[Ref 1],
       [cash_detail].[project string type],
       [cash_detail].[Acct type],
       [cash_detail].[project string],
       [cash_detail].[full account],
       [cash_detail].[additional description-Line Description],
       SUM([cash_detail].[Debit Gross]) AS [Debit Gross],
       SUM([cash_detail].[Credit Gross]) AS [Credit Gross],
       [cash_detail].[Ref 2],
       '' AS [Ref 3],
       [cash_detail].[Ref 4],
       [cash_detail].[comment-JE Description],
       [cash_detail].[transaction_type],
       [cash_detail].[detail_section_order] 
	   FROM [cash_detail]
	   GROUP BY 
	   [cash_detail].[webstore_transaction_date],
       [cash_detail].[Identifier],
       [cash_detail].[Ref 1],
       [cash_detail].[project string type],
       [cash_detail].[Acct type],
       [cash_detail].[project string],
       [cash_detail].[full account],
       [cash_detail].[additional description-Line Description],
       [cash_detail].[Ref 2],
       [cash_detail].[Ref 4],
       [cash_detail].[comment-JE Description],
       [cash_detail].[transaction_type],
       [cash_detail].[detail_section_order] 

)
, all_import_data AS (

SELECT [header].[webstore_transaction_date],
       [header].[Identifier],
       [header].[Ref 1],
       [header].[project string type],
       [header].[Acct type],
       [header].[project string],
       [header].[full account],
       [header].[additional description-Line Description],
       [header].[Debit Gross],
       [header].[Credit Gross],
       [header].[Ref 2],
       [header].[ref3],
       [header].[Ref 4],
       [header].[comment-JE Description],
       [header].[transaction_type],
       [header].[detail_section_order] FROM [header]
UNION ALL
SELECT [revenue_detail].[webstore_transaction_date],
       [revenue_detail].[Identifier],
       [revenue_detail].[Ref 1],
       [revenue_detail].[project string type],
       [revenue_detail].[Acct type],
       [revenue_detail].[project string],
       [revenue_detail].[full account],
       [revenue_detail].[additional description-Line Description],
       CAST([revenue_detail].[Debit Gross] AS NVARCHAR(50)),
       CAST([revenue_detail].[Credit Gross] AS NVARCHAR(50)),
       [revenue_detail].[Ref 2],
       [revenue_detail].[ref3],
       [revenue_detail].[Ref 4],
       [revenue_detail].[comment-JE Description],
       [revenue_detail].[transaction_type],
       [revenue_detail].[detail_section_order] FROM [revenue_detail]
UNION ALL
SELECT [cash_sum].[webstore_transaction_date],
       [cash_sum].[Identifier],
       [cash_sum].[Ref 1],
       [cash_sum].[project string type],
       [cash_sum].[Acct type],
       [cash_sum].[project string],
       [cash_sum].[full account],
       [cash_sum].[additional description-Line Description],
       CAST([cash_sum].[Debit Gross] AS NVARCHAR(50)),
       CAST([cash_sum].[Credit Gross] AS NVARCHAR(50)),
       [cash_sum].[Ref 2],
       [cash_sum].[Ref 3],
       [cash_sum].[Ref 4],
       [cash_sum].[comment-JE Description],
       [cash_sum].[transaction_type],
       [cash_sum].[detail_section_order] 
	   FROM [cash_sum]
)


SELECT [all_import_data].[webstore_transaction_date],
       [all_import_data].[Identifier],
       [all_import_data].[Ref 1],
       [all_import_data].[project string type],
       [all_import_data].[Acct type],
       [all_import_data].[project string],
       [all_import_data].[full account],
       [all_import_data].[additional description-Line Description],
       [all_import_data].[Debit Gross],
       [all_import_data].[Credit Gross],
       [all_import_data].[Ref 2],
       [all_import_data].[ref3],
       [all_import_data].[Ref 4],
       [all_import_data].[comment-JE Description],
       [all_import_data].[transaction_type],
       [all_import_data].[detail_section_order] 
	   FROM [all_import_data]
GO
