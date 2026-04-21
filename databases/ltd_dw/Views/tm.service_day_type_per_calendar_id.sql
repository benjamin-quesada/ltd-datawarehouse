SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






CREATE VIEW [tm].[service_day_type_per_calendar_id]
AS
SELECT [calendar_id]  = sc.calendar_id
      ,[the_date]     = sc.calendar_date 
      ,[service_type] = (SELECT TOP 1 CASE WHEN CHARINDEX('Sa', st.service_abbr) > 0 THEN 'Saturday' 
		WHEN CHARINDEX('Su', st.service_abbr) > 0 THEN 'Sunday' ELSE 'Weekday' END AS day_type 
			FROM [ltd-tmdata].tmmain.dbo.service_selection ss INNER JOIN [ltd-tmdata].tmmain.dbo.service_type st 
					ON st.service_type_id = ss.service_type_id WHERE ss.calendar_id = sc.calendar_id)
  FROM [ltd-tmdata].tmmain.dbo.service_calendar sc

GO
