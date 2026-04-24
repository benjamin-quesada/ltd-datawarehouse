SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		B Eichberger, RID-13253
-- Create date: 11/17/2021
-- Description:	Get July-Jun Fiscal Year
-- Usage		SELECT dbo.ltd_FiscalYear('120220101')
-- =============================================
CREATE FUNCTION [dbo].[ltd_FiscalYear](
    @inputCalId           INT
)
RETURNS VARCHAR(32)
AS
BEGIN

/*

USAGE EXAMPLES of both tbl and non tbl functions.

SELECT ltd_db.dbo.ltd_FiscalYear(scc.calendar_id) FiscalYearName,
       x.*,
	   x.longFY,
	   x.caldate,
       t.[CALENDAR_ID],
       year = YEAR(the_date),
       month = MONTH(the_date),
       scc.dow_name,
       scc.svc_type,
       scc.ttv_name,
       [RTE],
       [RTE_DIR],
       NTD_mode = CASE WHEN [RTE] IN ( '101', '102', '103', '104', '105' ) THEN 'RB-DO' ELSE 'MB-DO' END,
       [SCHED_DEADHEAD_HRS],
       [SCHED_LAYOVER_HRS],
FROM [ltd_db].[dbo].[ntd_stats_transtrack] t 
    INNER JOIN ltd_db.dbo.service_calendar scc
        ON scc.calendar_id = t.CALENDAR_ID
CROSS APPLY	dbo.ltd_FiscalYear_Tbl(scc.calendar_id) x


*/    
	DECLARE @datepart INT = (SELECT RIGHT(@inputCalId,8))
	DECLARE @dateconv DATE = (SELECT CONVERT (DATETIME,CONVERT(CHAR(8),@datepart)))

    DECLARE @FiscalYrName     VARCHAR(32)

    
	SELECT @FiscalYrName = 'FY' + (CASE WHEN (MONTH(@dateconv)) <= 6 THEN convert(varchar(4), YEAR(@dateconv))    
                        ELSE convert(varchar(4),YEAR(@dateconv)+1) END    )
    


    RETURN @FiscalYrName

END


GO
