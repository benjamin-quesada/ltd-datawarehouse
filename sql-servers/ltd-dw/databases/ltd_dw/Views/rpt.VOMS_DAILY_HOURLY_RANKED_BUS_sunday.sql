SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE view [rpt].[VOMS_DAILY_HOURLY_RANKED_BUS_sunday]
as
  SELECT  [VOMS_hourly_key]
      ,h.calendar_id as ldate,bustype
      ,[HH]
      ,h.[current_runs]
	  ,[Max Run by Month] = ROW_NUMBER() OVER (partition by h.calendar_id ORDER BY CURRENT_RUNS DESC)
	  ,[Max Run Date by Month] = ROW_NUMBER() OVER (partition by datepart(year,CONVERT(CHAR(10), h.calendar_id, 120)), datepart(month,CONVERT(CHAR(10), h.calendar_id, 120)) ORDER BY CURRENT_RUNS DESC)
  FROM [ltd_dw].[rpt].[VOMS_DAILY_HOURLY_BUS] h
  INNER JOIN [tm].[DW_CALENDAR] c on c.yyyymmdd = h.calendar_id
  and c.DayOfWeekNbr = 1 AND bustype = 'BUS'
GO
