SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create view [rpt].[eam_parts_inventory_history]
as

SELECT 
			o.[PART_part_no]
			,o.part_suffix
			,o.count_month
			,o.count_year
			,o.trans_in_qty
			,o.trans_in_value
			,o.trans_out_qty
			,o.trans_out_value
			,o.issue_qty
			,o.issue_value
			,o.receipt_qty
			,o.receipt_value
			,o.qty_scrapped
			,SUM((o.receipt_qty+o.trans_in_qty)-(o.issue_qty+o.qty_scrapped+o.trans_out_qty)) 
				OVER (Partition by o.[PART_part_no],o.part_suffix ORDER BY count_year, count_month  ROWS UNBOUNDED PRECEDING ) calculatedQOH
			,p.MEA_unit_of_issue
			,p.description_keyword
			,replace(p.description_short,'ý',' ') description_short
			,s.prd_product_category
			,a.acct_title
			,t.title_1
			,t.title_2
			,case when t.title_3 = '*** Title Not Found ***                 ' then '' else t.title_3 end title_3
		FROM [LTD-EAM].[proto].[emsdba].[PLO_COUNT] o WITH(NOLOCK)
		LEFT JOIN [LTD-EAM].[proto].[emsdba].[PTS_MAIN] s WITH(NOLOCK) on s.PART_part_no = o.PART_part_no and s.part_suffix = o.part_suffix 
		left JOIN [LTD-EAM].[proto].[emsdba].[PLO_MAIN] p WITH(NOLOCK) on p.PART_part_no = o.PART_part_no and p.part_suffix = o.part_suffix
		LEFT JOIN [LTD-FINANCE].GoldStandard.dbo.esxacctr a WITH (NOLOCK) 
			ON cast(a.LEVEL_4 AS VARCHAR(20)) COLLATE SQL_Latin1_General_CP1_CI_AS = cast(s.prd_product_category AS VARCHAR(20)) COLLATE SQL_Latin1_General_CP1_CI_AS
		       AND a.acct_year = o.count_year
		LEFT JOIN [LTD-FINANCE].GoldStandard.dbo.esgacttr t WITH(NOLOCK) on t.acct_id = a.acct_id and t.acct_year = a.acct_year
		where o.PART_part_no = 'VID-0073'
		--where trans_in_qty <> 0
		--order by PART_part_no,count_year, count_month
GO
