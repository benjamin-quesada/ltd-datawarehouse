SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   PROCEDURE [eam].[get_part_movement_min_max_with_eqno]
AS

/*-----------LTD_GLOSSARY---------------
 created by	:  b. eichberger
 created dt	:  2024-08-05 
 purpose	:  merge eam parts movement data into [eam].[parts_movement_min_max_equip_no]
 use		:  exec eam.get_part_movement_min_max_with_eqno

UPDATED BY	: Sopheap Suy
UPDATED DT	: 10/31/2024
purpose		: Add object activities on who, what, when call this object
			  write this data to aud.object_activity table everytime it's called 
		
UPDATED BY	: B. Eichberger
UPDATED DT	: 11/12/2024
purpose		: RID-30426 BI Min Max Report: Add column for Work Order count

UPDATED BY	: B. Eichberger
UPDATED DT	: 1/2/2025
purpose		: RID-30426 BI Min Max Report: Add column for part no yymm

USE			: exec [eam].[get_part_movement_min_max_with_eqno]
----------------------------------*/

SET NOCOUNT ON

DECLARE @SPROC VARCHAR(100)
SET @SPROC = OBJECT_SCHEMA_NAME(@@PROCID) + '.' + OBJECT_NAME(@@PROCID)

INSERT INTO DBA.[aud].[Object_Activity]
	([server_name], [database_name] ,[host_name], [System_User], [object_name]
	,[client_net_address], [local_net_address], [auth_Scheme], [last_read], [last_write]
	,[most_recent_sql_handle], [Timestamp], object_type)
SELECT DISTINCT @@SERVERNAME, DB_NAME(),HOST_NAME(),SYSTEM_USER, @SPROC,
	client_net_address, local_net_address , auth_Scheme, last_read, last_write 
	,most_recent_sql_handle, CURRENT_TIMESTAMP AS [Timestamp], 'PROC'
FROM sys.dm_exec_connections 
WHERE session_id = @@SPID ;

BEGIN TRY

DECLARE @sdt DATETIME2 = SYSDATETIME()
DECLARE @outputTbl TABLE (actionNm VARCHAR(32));


--DECLARE @lastIssDate DATE = (SELECT DATEADD(DAY,1,EOMONTH(DATEADD(MONTH,-3,ISNULL(MAX(month_date),'1/1/1990')))) 
--	FROM [eam].[parts_movement_min_max_equip_no])
--SELECT @lastIssDate


DROP TABLE IF EXISTS #mergeready
DROP TABLE IF EXISTS #eq_used
DROP TABLE IF EXISTS #parts

SELECT o.PART_part_no, o.part_suffix, o.part_no_suffix
   ,EQTYP_equip_type = ISNULL(o.EQTYP_equip_type,'Unspecified')
   ,o.issued_year
   ,o.issued_month
   ,after_semi_name = RTRIM(LTRIM(o.after_semi_name))
   ,before_semi_name = RTRIM(LTRIM(o.before_semi_name))
   ,SUM(ISNULL(o.qty_issued,0)) qty_issued
   ,SUM(ISNULL(count_wo,0)) count_wo
   ,RT_qty_issued_life = SUM(qty_issued) OVER (PARTITION BY ISNULL(EQTYP_equip_type,'Unspecified')
											   ,PART_part_no
											   ,part_suffix
												ORDER BY o.issued_year, o.issued_month
												ROWS UNBOUNDED PRECEDING
											   )
   ,RT_qty_used_life = SUM(qty_issued) OVER (PARTITION BY PART_part_no
											   ,part_suffix
												ORDER BY o.issued_year, o.issued_month
												ROWS UNBOUNDED PRECEDING
											   )
INTO #EQ_used 
FROM
	(
		SELECT m.PART_part_no
	   ,m.part_suffix
	   ,part_no_suffix = CAST(m.PART_part_no AS VARCHAR(12))  + '-' + CAST(m.part_suffix AS VARCHAR(12)) 
	   ,RTRIM(LTRIM(REPLACE(t.PartShortDescription,'`',' ft'))) part_short_description
	   ,RTRIM(LTRIM(REPLACE(m.[description],'`',' ft'))) part_description
	   ,RTRIM(LTRIM(t.Keyword)) part_keyword
	   ,t.ProductCategoryID product_category
	   ,after_semi_name = CASE WHEN m.[description] LIKE '%;%' THEN RTRIM(SUBSTRING(m.[description], CHARINDEX(';', m.[description]) + 1, 999))ELSE m.[description] END
	   ,before_semi_name = CASE WHEN m.[description] LIKE '%;%' THEN LEFT(m.[description], CHARINDEX(';', m.[description]) - 1)ELSE m.[description] END
	   ,EQTYP_equip_type = ISNULL(q.EQTYP_equip_type,'Unspecified')
	   ,issued_year = YEAR(issue_date)
	   ,issued_month = MONTH(issue_date)
	   ,qty_issued = SUM(m.qty_issued)
	   ,count_wo = COUNT(CONCAT(CONCAT(m.work_order_yr,'-') , m.work_order_no))
		FROM [LTD-EAM].[proto].[emsdba].PTD_MAIN m WITH (NOLOCK)
			 LEFT JOIN [LTD-EAM].[proto].[emsdba].EQ_MAIN q WITH (NOLOCK) ON q.EQ_equip_no = m.EQ_equip_no
			 LEFT JOIN [LTD-EAM].[proto].[emsdba].[QPart] t WITH (NOLOCK) ON t.PartID = m.PART_part_no AND t.PartSuffix = m.part_suffix
		WHERE m.fully_reversed = 'N' AND m.return_flag = 'N'
		--AND m.PART_part_no = '12974'
		group by 
		m.PART_part_no 
	   ,m.part_suffix
	   ,CAST(m.PART_part_no AS VARCHAR(12))  + '-' + CAST(m.part_suffix AS VARCHAR(12)) + '-' 
	   ,RTRIM(LTRIM(REPLACE(t.PartShortDescription,'`',' ft'))) 
	   ,RTRIM(LTRIM(REPLACE(m.[description],'`',' ft'))) 
	   ,RTRIM(LTRIM(t.Keyword)) 
	   ,t.ProductCategoryID 
	   ,CASE WHEN m.[description] LIKE '%;%' THEN RTRIM(SUBSTRING(m.[description], CHARINDEX(';', m.[description]) + 1, 999))ELSE m.[description] END
	   ,CASE WHEN m.[description] LIKE '%;%' THEN LEFT(m.[description], CHARINDEX(';', m.[description]) - 1)ELSE m.[description] END
	   ,ISNULL(q.EQTYP_equip_type,'Unspecified')
	   ,YEAR(issue_date)
	   ,MONTH(issue_date)
	) o
	GROUP BY o.PART_part_no, o.part_suffix, o.part_no_suffix
   ,ISNULL(o.EQTYP_equip_type,'Unspecified')
   ,o.issued_year
   ,o.issued_month
   ,o.after_semi_name
   ,o.before_semi_name
   ,o.qty_issued

--SELECT * FROM #EQ_used where PART_part_no = '12974'

SELECT ISNULL(ql.PrimaryBinID, 'Unspecified') PrimaryBinID
,IsObsolete = CASE WHEN ql.PrimaryBinID = 'Obsolete' THEN 1 ELSE 0 END
,IsTBD = CASE WHEN ql.PrimaryBinID = 'TBD' THEN 1 ELSE 0 END
,m.PART_part_no
,m.part_suffix
,part_no_suffix = CAST(m.PART_part_no AS VARCHAR(12)) + '-' + CAST(m.part_suffix AS VARCHAR(12)) 
,part_no_yyyymm = CAST(m.PART_part_no AS VARCHAR(12)) + '-' + CAST(m.part_suffix AS VARCHAR(12)) + '-' + CAST(m.count_year AS VARCHAR(5)) + RIGHT('00' + CAST(m.count_month AS VARCHAR(2)), 2)
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
,SUM(ISNULL(m.receipt_qty, 0)) receipt_qty
,SUM(ISNULL(m.issue_qty, 0)) issue_qty
,SUM(ISNULL(m.transfer_in_qty, 0)) transfer_in_qty
,SUM(ISNULL(m.transfer_out_qty, 0)) transfer_out_qty
,SUM(ISNULL(m.adjustment_qty, 0)) adjustment_qty
,SUM(ISNULL(m.qty_out_for_repair, 0)) qty_out_for_repair
,SUM(ISNULL(m.qty_repaired, 0)) qty_repaired
,sum_part_movement = ((SUM(m.receipt_qty) + SUM(m.transfer_in_qty) + SUM(m.adjustment_qty)) - SUM(m.transfer_out_qty)) - SUM(m.issue_qty)
,TotalQuantityOnOrderForAllLoc = SUM(ISNULL(qp.TotalQuantityOnOrderForAllLoc, 0))
,QuantityOnHand = MAX(ISNULL(ql.QuantityOnHand, 0))
,[On Hand Plus On Order] = MAX(ISNULL(qp.TotalQuantityOnOrderForAllLoc, 0)) + MAX(ISNULL(ql.QuantityOnHand, 0)) -- select *
INTO #parts
FROM -- select * from 
[LTD-EAM].[proto].[emsdba].[V_PART_MOVEMENT] m WITH (NOLOCK)
	 LEFT JOIN [LTD-EAM].[proto].[emsdba].[QPart] qp WITH (NOLOCK) ON m.PART_part_no = qp.PartID
	 LEFT JOIN [LTD-EAM].[proto].[emsdba].[QPartLocation] ql WITH (NOLOCK) ON ql.PartID = qp.PartID
	 LEFT JOIN [LTD-EAM].[proto].[emsdba].[RPT_PART_STOCK_STATUS]s ON s.[Part ID] = m.PART_part_no
																	   AND s.[Part Suffix] = m.part_suffix
GROUP BY ISNULL(ql.PrimaryBinID, 'Unspecified')
,CASE WHEN ql.PrimaryBinID = 'Obsolete' THEN 1 ELSE 0 END
,CASE WHEN ql.PrimaryBinID = 'TBD' THEN 1 ELSE 0 END
,m.PART_part_no
,m.part_suffix
,CAST(m.PART_part_no AS VARCHAR(12)) + '-' + CAST(ISNULL(m.part_suffix, '0') AS VARCHAR(12)) + '-'
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
,ISNULL(s.[Stock Status], 'Unspecified');

--SELECT * FROM #parts

SELECT  DISTINCT 
 i.PrimaryBinID
,i.IsObsolete
,i.IsTBD
,i.PART_part_no
,i.part_suffix
,i.part_no_suffix
,i.part_no_yyyymm
,PartShortDescription = REPLACE(COALESCE(i.PartShortDescription,e.before_semi_name),'`',' ft')
,i.ProductCategoryID
,DescriptionAdded = REPLACE(COALESCE(i.DescriptionAdded,e.after_semi_name),'`',' ft')
,i.Keyword
,PartNoDesc = REPLACE(i.PartNoDesc,'`',' ft')
,i.count_year
,i.count_month
,i.year_mo
,i.month_date
,i.month_name
,EQTYP_equip_type = ISNULL(e.EQTYP_equip_type,'Unspecified') 
,i.receipt_qty
,i.issue_qty
,i.transfer_in_qty
,i.transfer_out_qty
,i.adjustment_qty
,i.qty_out_for_repair
,i.qty_repaired
,e.count_wo
,RT_qty_issued_life = ISNULL(e.RT_qty_issued_life,0)
,RT_qty_used_life = ISNULL(e.RT_qty_used_life,0)
,RT_receipt_qty = SUM(ISNULL(i.receipt_qty, 0)) OVER (PARTITION BY i.PART_part_no,i.part_suffix ORDER BY i.count_year,i.count_month )
,RT_issue_qty = SUM(ISNULL(i.issue_qty, 0)) OVER (PARTITION BY i.PART_part_no,i.part_suffix ORDER BY i.count_year,i.count_month)
,RT_transfer_in_qty = SUM(ISNULL(i.transfer_in_qty, 0)) OVER (PARTITION BY i.PART_part_no,i.part_suffix ORDER BY i.count_year,i.count_month)
,RT_transfer_out_qty = SUM(ISNULL(i.transfer_out_qty, 0)) OVER (PARTITION BY i.PART_part_no,i.part_suffix ORDER BY i.count_year,i.count_month)
,RT_adjustment_qty = SUM(ISNULL(i.adjustment_qty, 0)) OVER (PARTITION BY i.PART_part_no,i.part_suffix ORDER BY i.count_year,i.count_month)
,RT_rcpt_minus_issued = SUM(ISNULL(i.receipt_qty, 0) - ISNULL(i.issue_qty, 0)) OVER (PARTITION BY i.PART_part_no,i.part_suffix ORDER BY count_year,count_month)
,RT_sum_part_movement = SUM(ISNULL(i.sum_part_movement, 0)) OVER (PARTITION BY i.PART_part_no,i.part_suffix ORDER BY count_year,count_month)
,RT_count_wo = SUM(ISNULL(e.count_wo,0)) OVER (PARTITION BY i.PART_part_no,i.part_suffix ORDER BY count_year,count_month)
,i.TotalQuantityOnOrderForAllLoc
,i.QuantityOnHand
,i.[On Hand Plus On Order]
,i.SafetyStockLevel
,i.MinimumAvailableQuantity
,i.MaximumAvailableQuantity
,i.[Stock Status]
INTO #mergeReady
FROM #parts i
LEFT JOIN #EQ_USED e ON e.PART_part_no = i.PART_part_no
					   AND e.part_suffix = i.part_suffix
					   AND e.issued_year = i.count_year
					   AND e.issued_month = i.count_month

--SELECT * FROM #mergeReady WHERE PART_part_no = '12974' ORDER BY count_year, count_month

TRUNCATE TABLE 
[eam].[parts_movement_min_max_w_equip_no] 


INSERT [eam].[parts_movement_min_max_w_equip_no]
(
PrimaryBinID
,IsObsolete
,IsTBD
,PART_part_no
,part_suffix
,part_no_suffix
,part_no_yyyymm
,PartShortDescription
,ProductCategoryID
,DescriptionAdded
,Keyword
,PartNoDesc
,count_year
,count_month
,year_mo
,month_date
,month_name
,eqtyp_equip_type
,receipt_qty
,issue_qty
,transfer_in_qty
,transfer_out_qty
,adjustment_qty
,qty_out_for_repair
,qty_repaired
,count_wo
,RT_qty_issued_life
,RT_qty_used_life
,RT_receipt_qty
,RT_issue_qty
,RT_transfer_in_qty
,RT_transfer_out_qty
,RT_adjustment_qty
,RT_rcpt_minus_issued
,RT_sum_part_movement
,RT_count_wo
,TotalQuantityOnOrderForAllLoc
,QuantityOnHand
,[On Hand Plus On Order]
,SafetyStockLevel
,MinimumAvailableQuantity
,MaximumAvailableQuantity
,[Stock Status]
)
OUTPUT inserted.[part_min_max_key] INTO @outputTbl
SELECT s.PrimaryBinID
,s.IsObsolete
,s.IsTBD
,s.PART_part_no
,s.part_suffix
,s.part_no_suffix
,s.part_no_yyyymm
,s.PartShortDescription
,s.ProductCategoryID
,s.DescriptionAdded
,s.Keyword
,s.PartNoDesc
,s.count_year
,s.count_month
,s.year_mo
,s.month_date
,s.month_name
,s.eqtyp_equip_type
,s.receipt_qty
,s.issue_qty
,s.transfer_in_qty
,s.transfer_out_qty
,s.adjustment_qty
,s.qty_out_for_repair
,s.qty_repaired
,ISNULL(s.count_wo,0) count_wo
,s.RT_qty_issued_life
,s.RT_qty_used_life
,s.RT_receipt_qty
,s.RT_issue_qty
,s.RT_transfer_in_qty
,s.RT_transfer_out_qty
,s.RT_adjustment_qty
,s.RT_rcpt_minus_issued
,s.RT_sum_part_movement
,s.RT_count_wo
,s.TotalQuantityOnOrderForAllLoc
,s.QuantityOnHand
,s.[On Hand Plus On Order]
,s.SafetyStockLevel
,s.MinimumAvailableQuantity
,s.MaximumAvailableQuantity
,s.[Stock Status]
FROM #mergeReady s;



DECLARE @ins INT = (SELECT COUNT(*) FROM @outputTbl ) --WHERE actionNm = 'INSERT'
--DECLARE @upd INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'UPDATE')
--DECLARE @del INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'DELETE')
DECLARE @prg varchar(90) = @@SERVERNAME + '.ltd_dw.eam.parts_movement_min_max_equip_no'

insert process.mergeLogs
(		[MergeCode]
           ,[ObjectDestination]
           ,[ObjectSource]
           ,[ObjectProgram]
           ,[recInsert]
           ,[recUpdate]
           ,[recDelete]
           ,[MergeBeginDatetime]
           ,[MergeEndDatetime])
select 'PARTM',
'ltd_dw.eam.parts_movement_min_max_equip_no',
'EAM',
@prg,
isnull(@ins,0) ,0,0,
@sdt,
sysdatetime()


DROP TABLE IF EXISTS #mergeready
DROP TABLE IF EXISTS #eq_used
DROP TABLE IF EXISTS #parts

END TRY	  

BEGIN CATCH

       DECLARE @profile VARCHAR(255) = (
                    SELECT [NAME]
                    FROM msdb.dbo.sysmail_profile
                    )
       DECLARE @errormsg VARCHAR(MAX)
             ,@error INT
             ,@message VARCHAR(MAX)
             ,@xstate INT
             ,@errsev INT
             ,@sub VARCHAR(255);

       SELECT @error = ERROR_NUMBER()
             ,@errsev = ERROR_SEVERITY()
             ,@message = ERROR_MESSAGE()
             ,@xstate = XACT_STATE();

       SELECT @errormsg = 'Error in ' + ISNULL(@SPROC, '') + ': ' + CAST(ISNULL(@error, '') AS NVARCHAR(32)) + '|' + COALESCE(@message, '') + '|' + CAST(ISNULL(@xstate, '') AS NVARCHAR(32)) + '|' +CAST(ISNULL(@errsev, '') AS NVARCHAR(32))

       SELECT @sub = 'ERROR: ' + @SPROC

       EXEC msdb.dbo.sp_send_dbmail @profile_name = @profile
             ,@recipients = 'barb.eichberger@ltd.org' 
             ,@subject = @sub
             ,@body = @errormsg;

       RAISERROR (
                    @errormsg
                    ,@errsev
                    ,1
                    )
END CATCH
GO
