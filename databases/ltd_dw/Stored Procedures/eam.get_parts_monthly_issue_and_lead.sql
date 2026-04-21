SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [eam].[get_parts_monthly_issue_and_lead]
AS

/*-----------LTD_GLOSSARY---------------
 CREATED BY :  B. Eichberger
 CREATED DT	:  2025-01-24
 PURPOSE	:  insert min max calculations from eam parts tables
 USE		:  exec eam.get_parts_monthly_issue_and_lead

*/

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

DROP TABLE IF EXISTS #temppartscross 
DROP TABLE IF EXISTS #tempplocount 
DROP TABLE IF EXISTS #tempparts 
DROP TABLE IF EXISTS #leadtimes 


SELECT n.count_year, n.count_month
	,n.PART_part_no 
	,n.part_suffix 
	,ISNULL(n.issue_qty,0) issue_qty
	INTO #tempplocount
	FROM [LTD-EAM].proto.emsdba.plo_count n 
	 --WHERE PART_part_no = '002-0073'

SELECT DISTINCT n.PART_part_no, n.part_suffix 
INTO #tempparts
FROM [LTD-EAM].proto.emsdba.PTS_MAIN n 
	 --WHERE PART_part_no = '002-0073'
				
SELECT c.[Year]
	  ,c.[Month]
	  ,x.PART_part_no
	  ,x.part_suffix
into #temppartscross
FROM (SELECT DISTINCT [Year], [Month] from ltd_dw.tm.DW_CALENDAR WHERE [Year] >= 2017) c
cross join #tempparts x

;

SELECT q.PART_part_no
,q.part_suffix
,q.Year
,q.Month
,q.lead_count [Lead Entry Count]
,q.[Monthly Lead Time]
,[Lead Time] = CASE WHEN q.lead_count <> 0 THEN [Monthly Lead Time] / q.lead_count ELSE 1 END
INTO #leadtimes
FROM
(
	SELECT i.[Year]
   ,i.[Month]
   ,i.PART_part_no
   ,i.part_suffix
   ,i.lead_count
   ,i.lead_days
   ,[Lead Time] = SUM(ISNULL(lead_days, 0)) OVER (PARTITION BY PART_part_no,part_suffix ORDER BY i.[Year],i.[Month] ROWS BETWEEN 11 PRECEDING AND CURRENT ROW) / i.lead_count
   ,[Monthly Lead Time] = SUM(ISNULL(lead_days, 0)) OVER (PARTITION BY PART_part_no,part_suffix ORDER BY i.[Year],i.[Month] ROWS BETWEEN 11 PRECEDING AND CURRENT ROW) / 12
	FROM
	(
		SELECT s.[Year]
	   ,s.[Month]
	   ,s.PART_part_no
	   ,s.part_suffix
	   ,lead_days = SUM(ISNULL(lead_days, 0))
	   ,lead_count = COUNT(*) 
		FROM #temppartscross s
			 LEFT JOIN [LTD-EAM].proto.emsdba.PLO_LEAD a ON a.PART_part_no = s.PART_part_no
						AND a.part_suffix = s.part_suffix
						AND YEAR(post_datetime) = s.Year
						AND MONTH(post_datetime) = s.Month
		WHERE s.PART_part_no = '12974'
		group BY s.[Year]
	   ,s.[Month]
	   ,s.PART_part_no
	   ,s.part_suffix
	   --ORDER BY 1 desc,2 desc
	) i
	--ORDER BY 1 desc,2 desc
) q
ORDER BY [Year],[Month];

TRUNCATE TABLE eam.partsMinMax_LeadTime
INSERT eam.partsMinMax_LeadTime
([Year]
,[Month]
,[PART_part_no]
,[part_suffix]
,[Monthly Lead Time]
,[Lead Time]
,[Cal Min Qty]
,[Cal Max Qty]
,[Cal Min Qty Round]
,[Cal Max Qty Round])
SELECT [Year]
	  ,[Month]
	  ,PART_part_no
	  ,part_suffix
	  ,[Monthly Lead Time]
	  ,[Lead Time]
	  ,[Cal Min Qty] = CASE WHEN ISNULL([Monthly Lead Time],0) = 0 then 0
							ELSE (ISNULL(issue_monthly,0) / [Monthly Lead Time]) * ([Lead Time] + 1) END -- Security Period = 1
	  ,[Cal Max Qty] = CASE WHEN ISNULL([Monthly Lead Time],0) = 0 then 0
							ELSE (ISNULL(issue_monthly,0) / [Monthly Lead Time]) * (([Lead Time] * 2) + 1) END
	  ,[Cal Min Qty Round] = CEILING(CASE WHEN ISNULL([Monthly Lead Time],0) = 0 then 0
							ELSE (ISNULL(issue_monthly,0) / [Monthly Lead Time]) * ([Lead Time] + 1) END)
	  ,[Cal Max Qty Round] = CEILING(CASE WHEN ISNULL([Monthly Lead Time],0) = 0 then 0
							ELSE (ISNULL(issue_monthly,0) / [Monthly Lead Time]) * (([Lead Time] * 2) + 1) END)
FROM
(SELECT y.[Year]
	  ,y.[Month]
	  ,y.PART_part_no
	  ,y.part_suffix
	  ,[Monthly Lead Time] = ISNULL(d.[Monthly Lead Time],0)
	  ,d.[Lead Entry Count] ,[Lead Time] 
	  ,issue_qty = ISNULL(y.issue_qty,0)
	  ,issue_monthly = SUM(ISNULL(y.issue_qty,0.0))  OVER (PARTITION BY y.PART_part_no,y.part_suffix ORDER BY y.[Year], y.[Month] ROWS BETWEEN 11 PRECEDING AND CURRENT ROW)/12.0
FROM (
SELECT DISTINCT x.[Year]
	  ,x.[Month]
	  ,x.PART_part_no
	  ,x.part_suffix
	  ,b.issue_qty FROM (
SELECT x.[Year]
	  ,x.[Month]
	  ,x.PART_part_no
	  ,x.part_suffix
FROM #tempPartsCross x
left join #tempparts t 
    on t.PART_part_no = x.PART_part_no
	AND t.part_suffix = x.part_suffix
) x 
LEFT JOIN #tempplocount b
ON b.count_year = x.[Year]
AND b.count_month = x.[Month]
AND b.PART_part_no = x.PART_part_no
AND b.part_suffix = x.part_suffix ) y
LEFT JOIN #leadtimes d ON d.PART_part_no = y.PART_part_no AND d.part_suffix = d.part_suffix AND d.Month = y.[Month] AND d.Year = y.[Year]
) v
WHERE NOT (v.[Year] = YEAR(GETDATE()) AND v.[Month] >= Month(GETDATE()))
ORDER BY v.[Year], v.[Month]


DROP TABLE IF EXISTS #temppartscross 
DROP TABLE IF EXISTS #tempplocount 
DROP TABLE IF EXISTS #tempparts 
DROP TABLE IF EXISTS #leadtimes 


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
