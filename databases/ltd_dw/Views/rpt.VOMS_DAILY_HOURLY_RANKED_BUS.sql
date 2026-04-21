SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE view [rpt].[VOMS_DAILY_HOURLY_RANKED_BUS]
as
SELECT  [VOMS_hourly_key]
      ,calendar_id as ldate
      ,[HH]
      ,[current_runs]
	  ,bustype
	  ,[Max Run by Month] = ROW_NUMBER() OVER (partition by calendar_id ORDER BY CURRENT_RUNS DESC)
	  ,[Max Run Date by Month] = ROW_NUMBER() OVER (partition by datepart(year,CONVERT(CHAR(10), calendar_id, 120)), datepart(month,CONVERT(CHAR(10), calendar_id, 120)) ORDER BY CURRENT_RUNS DESC)
  FROM [ltd_dw].[rpt].[VOMS_DAILY_HOURLY_BUS]
 WHERE bustype = 'BUS'
  --ORDER BY calendar_id, HH
GO
