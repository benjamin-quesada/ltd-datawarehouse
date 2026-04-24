SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [eam].[part_movement_min_max_with_eqno]
AS
/********************************

CREATED ON	: 20240802
CREATED BY	: B. Eichberger
PURPOSE		: fulfill report request for parts min/max
	
CHANGED ON	: 20250102
CHANGED BY	: B. Eichberger
PURPOSE		: add identifier to align on power bi report by part_no_yymm

--*/

WITH EQ_USED
AS (SELECT o.part_no, o.part_suffix, o.part_no_suffix
   ,EQTYP_equip_type = ISNULL(o.EQTYP_equip_type,'Unspecified')
   ,o.issued_year
   ,o.issued_month
   ,o.after_semi_name
   ,o.before_semi_name
   ,SUM(ISNULL(o.qty_issued,0)) qty_issued
   ,ISNULL(qty_issued_life,0) qty_issued_life
	FROM
	(
		SELECT m.PART_part_no part_no
	   ,m.part_suffix
	   ,part_no_suffix = CAST(m.PART_part_no AS VARCHAR(12))  + '[' + CAST(m.part_suffix AS VARCHAR(12)) + ']' 
	   ,RTRIM(LTRIM(t.PartShortDescription)) part_short_description
	   ,RTRIM(LTRIM(m.[description])) part_description
	   ,RTRIM(LTRIM(t.Keyword)) part_keyword
	   ,t.ProductCategoryID product_category
	   ,after_semi_name = CASE WHEN m.[description] LIKE '%;%' THEN RTRIM(SUBSTRING(m.[description], CHARINDEX(';', m.[description]) + 1, 999))ELSE m.[description] END
	   ,before_semi_name = CASE WHEN m.[description] LIKE '%;%' THEN LEFT(m.[description], CHARINDEX(';', m.[description]) - 1)ELSE m.[description] END
	   ,EQTYP_equip_type = ISNULL(q.EQTYP_equip_type,'Unspecified')
	   ,issued_year = YEAR(issue_date)
	   ,issued_month = MONTH(issue_date)
	   ,m.qty_issued
	   ,qty_issued_life = SUM(qty_issued) OVER (PARTITION BY ISNULL(EQTYP_equip_type,'Unspecified')
											   ,m.PART_part_no
											   ,m.part_suffix
												ORDER BY m.issue_date
												ROWS UNBOUNDED PRECEDING
											   )
		FROM [LTD-EAM].[proto].[emsdba].PTD_MAIN m WITH (NOLOCK)
			 INNER JOIN [LTD-EAM].[proto].[emsdba].EQ_MAIN q WITH (NOLOCK) ON q.EQ_equip_no = m.EQ_equip_no
			 LEFT JOIN [LTD-EAM].[proto].[emsdba].[QPart] t WITH (NOLOCK) ON t.PartID = m.PART_part_no
																			 AND t.PartSuffix = m.part_suffix
		WHERE m.fully_reversed = 'N'
	--AND EQTYP_equip_type = '2019 NEW FLYER'
	--AND m.PART_part_no = '11239'
	) o
	GROUP BY o.part_no, o.part_suffix, o.part_no_suffix
   ,ISNULL(o.EQTYP_equip_type,'Unspecified')
   ,o.issued_year
   ,o.issued_month
   ,o.after_semi_name
   ,o.before_semi_name
   ,o.qty_issued_life
   )


SELECT DISTINCT 
 i.PrimaryBinID
,i.IsObsolete
,i.IsTBD
,i.PART_part_no
,i.part_suffix
,i.part_no_suffix
,part_no_yymm = i.part_no_suffix+CAST(i.count_year AS VARCHAR(12))+RIGHT('00'+CAST(i.count_month AS VARCHAR(12)),2)
,PartShortDescription = REPLACE(i.PartShortDescription,'`',' ft')
,i.ProductCategoryID
,DescriptionAdded = REPLACE(i.DescriptionAdded,'`',' ft')
,e.after_semi_name
,e.before_semi_name
,i.Keyword
,PartNoDesc = REPLACE(i.PartNoDesc,'`',' ft')
,i.count_year
,i.count_month
,i.year_mo
,i.month_date
,i.month_name
,EQTYP_equip_type = ISNULL(e.EQTYP_equip_type,'Unspecified') 
,RT_life_issue_qty = SUM(ISNULL(e.qty_issued,0)) OVER (PARTITION BY e.EQTYP_equip_type,e.part_no,e.part_suffix ORDER BY e.issued_year, e.issued_month)
,qty_issued_life = ISNULL(e.qty_issued_life,0)
,i.receipt_qty
,i.issue_qty
,i.transfer_in_qty
,i.transfer_out_qty
,i.adjustment_qty
,i.qty_out_for_repair
,i.qty_repaired
,RT_receipt_qty = SUM(i.receipt_qty) OVER (PARTITION BY i.PART_part_no,i.part_suffix ORDER BY i.count_year,i.count_month )
,RT_issue_qty = SUM(i.issue_qty) OVER (PARTITION BY i.PART_part_no,i.part_suffix ORDER BY i.count_year,i.count_month)
,RT_transfer_in_qty = SUM(i.transfer_in_qty) OVER (PARTITION BY i.PART_part_no,i.part_suffix ORDER BY i.count_year,i.count_month)
,RT_transfer_out_qty = SUM(i.transfer_out_qty) OVER (PARTITION BY i.PART_part_no,i.part_suffix ORDER BY i.count_year,i.count_month)
,RT_adjustment_qty = SUM(i.adjustment_qty) OVER (PARTITION BY i.PART_part_no,i.part_suffix ORDER BY i.count_year,i.count_month)
,RT_rcpt_minus_issued = SUM(i.receipt_qty - i.issue_qty) OVER (PARTITION BY i.PART_part_no,i.part_suffix ORDER BY count_year,count_month)
,i.TotalQuantityOnOrderForAllLoc
,i.QuantityOnHand
,i.[On Hand Plus On Order]
,i.SafetyStockLevel
,i.MinimumAvailableQuantity
,i.MaximumAvailableQuantity
,i.[Stock Status]
FROM
(
	SELECT ISNULL(ql.PrimaryBinID, 'Unspecified') PrimaryBinID
   ,IsObsolete = CASE WHEN ql.PrimaryBinID = 'Obsolete' THEN 1 ELSE 0 END
   ,IsTBD = CASE WHEN ql.PrimaryBinID = 'TBD' THEN 1 ELSE 0 END
   ,m.PART_part_no
   ,m.part_suffix
   ,part_no_suffix = CAST(m.PART_part_no AS VARCHAR(12))  + '[' + CAST(m.part_suffix AS VARCHAR(12)) + ']' 
   ,qp.PartShortDescription
   ,qp.ProductCategoryID
   ,DescriptionAdded = COALESCE(qp.PartShortDescription, qp.[Description])
   ,qp.Keyword
   ,PartNoDesc = m.PART_part_no + ' ' + qp.PartShortDescription
   ,m.count_year
   ,m.count_month
   ,year_mo = CAST(m.count_year AS VARCHAR(5)) + RIGHT('00' + CAST(m.count_month AS VARCHAR(2)), 2)
   ,month_date = CAST(m.count_month AS VARCHAR(2)) + '/1/' + CAST(m.count_year AS VARCHAR(6))
   ,month_name = LEFT(DATENAME(MONTH, CAST(m.count_month AS VARCHAR(2)) + '/1/' + CAST(m.count_year AS VARCHAR(6))), 3)
   ,SafetyStockLevel = ISNULL(ql.SafetyStockLevel, 0)
   ,MinimumAvailableQuantity = ISNULL(ql.MinimumAvailableQuantity, 0)
   ,MaximumAvailableQuantity = ISNULL(ql.MaximumAvailableQuantity, 0)
   ,ISNULL(s.[Stock Status], 'Unspecified') [Stock Status]
   ,SUM(m.receipt_qty) receipt_qty
   ,SUM(m.issue_qty) issue_qty
   ,SUM(m.transfer_in_qty) transfer_in_qty
   ,SUM(m.transfer_out_qty) transfer_out_qty
   ,SUM(m.adjustment_qty) adjustment_qty
   ,SUM(m.qty_out_for_repair) qty_out_for_repair
   ,SUM(m.qty_repaired) qty_repaired
   ,TotalQuantityOnOrderForAllLoc = SUM(ISNULL(qp.TotalQuantityOnOrderForAllLoc, 0))
   ,QuantityOnHand = MAX(ISNULL(ql.QuantityOnHand, 0))
   ,[On Hand Plus On Order] = MAX(ISNULL(qp.TotalQuantityOnOrderForAllLoc, 0)) + MAX(ISNULL(ql.QuantityOnHand, 0)) -- select *
	FROM [LTD-EAM].[proto].[emsdba].[V_PART_MOVEMENT] m WITH (NOLOCK)
		 LEFT JOIN [LTD-EAM].[proto].[emsdba].[QPart] qp WITH (NOLOCK) ON m.PART_part_no = qp.PartID
		 LEFT JOIN [LTD-EAM].[proto].[emsdba].[QPartLocation] ql WITH (NOLOCK) ON ql.PartID = qp.PartID
		 LEFT JOIN [LTD-EAM].[proto].[emsdba].[RPT_PART_STOCK_STATUS] s ON s.[Part ID] = m.PART_part_no AND s.[Part Suffix] = m.part_suffix
	WHERE m.PART_part_no = '11239'
	GROUP BY ISNULL(ql.PrimaryBinID, 'Unspecified')
   ,CASE WHEN ql.PrimaryBinID = 'Obsolete' THEN 1 ELSE 0 END
   ,CASE WHEN ql.PrimaryBinID = 'TBD' THEN 1 ELSE 0 END
   ,m.PART_part_no
   ,m.part_suffix
   ,CAST(m.PART_part_no AS VARCHAR(12)) + '[' + CAST(ISNULL(m.part_suffix, '0') AS VARCHAR(12)) + ']'
   ,qp.PartShortDescription
   ,qp.ProductCategoryID
   ,COALESCE(qp.PartShortDescription, qp.[Description])
   ,qp.Keyword
   ,m.count_year
   ,m.count_month
   ,CAST(m.count_year AS VARCHAR(5)) + RIGHT('00' + CAST(m.count_month AS VARCHAR(2)), 2)
   ,CAST(m.count_month AS VARCHAR(2)) + '/1/' + CAST(m.count_year AS VARCHAR(6))
   ,LEFT(DATENAME(MONTH, CAST(m.count_month AS VARCHAR(2)) + '/1/' + CAST(m.count_year AS VARCHAR(6))), 3)
   ,ISNULL(ql.SafetyStockLevel, 0)
   ,ISNULL(ql.MinimumAvailableQuantity, 0)
   ,ISNULL(ql.MaximumAvailableQuantity, 0)
   ,ISNULL(s.[Stock Status], 'Unspecified')
) i
LEFT JOIN EQ_USED e ON e.part_no = i.PART_part_no
					   AND e.part_suffix = i.part_suffix
					   AND e.issued_year = i.count_year
					   AND e.issued_month = i.count_month

GO
