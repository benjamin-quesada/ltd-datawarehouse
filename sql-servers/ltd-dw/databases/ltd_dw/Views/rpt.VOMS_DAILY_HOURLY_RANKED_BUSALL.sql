SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






CREATE VIEW [rpt].[VOMS_DAILY_HOURLY_RANKED_BUSALL]
AS


SELECT CAST(C.CALENDAR_DATE AS DATE) [Date]
,[HH]
,[current_runs]
,bustype
,[Max Run by Month] = ROW_NUMBER() OVER (PARTITION BY B.calendar_id
										 ORDER BY CURRENT_RUNS DESC
										)
,[Max Run Date by Month] = ROW_NUMBER() OVER (PARTITION BY DATEPART(YEAR, CONVERT(CHAR(10), B.calendar_id, 120))
											 ,DATEPART(MONTH, CONVERT(CHAR(10), B.calendar_id, 120))
											  ORDER BY CURRENT_RUNS DESC
											 )
,C.YYYYMMDD
,C.DayNo
,C.DayOfWeek
,C.DayOfWeekNbr
,C.DAYOFYEAR
,C.WeekOfYear
,C.WeekofYearKey
,C.WeekOfMonth
,C.WeekOfMonthKey
,C.MONTH
,C.MonthName
,C.MonthNameText
,C.FiscalPeriod
,C.QUARTER
,C.QuarterName
,C.[Fiscal Quarter]
,C.[Fiscal Quarter Name]
,C.YEAR
,C.FiscalYear
,C.[Fiscal Year Name]
,C.isHoliday
,C.CalculatedMonthAge
,C.IsCurrentMonth
,C.[Current MTD This Year]
,C.[Current MTD Last Year]
,C.[Last 30 Days]
,C.[Last 60 Days]
,C.[Last 90 Days]
,C.[Prior 90 Days]
,C.[Last 10 Working Days]
,C.[Last 30 Working Days]
,C.[Last 60 Working Days]
,C.[Last 90 Working Days]
,C.YearMonth
,C.[Last Full Month]
,C.[Last Full 6 Months]
,C.[Last Full 12 Months]
,C.[Last Full 9 Months]
,C.[Last 9 Months To Date]
,C.[Previous Date Full 6 Months]
FROM [ltd_dw].[rpt].[VOMS_DAILY_HOURLY_BUS] B
	 JOIN tm.DW_CALENDAR C ON C.YYYYMMDD = B.calendar_id;

GO
