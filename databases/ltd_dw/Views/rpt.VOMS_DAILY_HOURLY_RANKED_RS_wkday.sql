SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE view [rpt].[VOMS_DAILY_HOURLY_RANKED_RS_wkday]
as
  SELECT  [VOMS_hourly_key]
      ,[ldate]
      ,[HH]
      ,[current_runs]
	  ,[Max Run by Month] = ROW_NUMBER() OVER (partition by LDATE ORDER BY CURRENT_RUNS DESC)
	  ,[Max Run Date by Month] = ROW_NUMBER() OVER (partition by datepart(year,CONVERT(CHAR(10), LDATE, 120)), datepart(month,CONVERT(CHAR(10), LDATE, 120)) ORDER BY CURRENT_RUNS DESC)
  FROM [ltd_dw].[rpt].[VOMS_DAILY_HOURLY_RS] h
  INNER JOIN [tm].[DW_CALENDAR] c on c.yyyymmdd = ldate
  where c.DayOfWeekNbr between 2 and 6
GO
