SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE view [process].[ColumnsOfPII_unmasked]
as
SELECT  [rowid]
      ,[db]
      ,[Column]
      ,[PII]
      ,[PII Data Domain]
      ,[GDPR Classification]
      ,[GDPR Data Domain]
      ,[recordDate]
  FROM [ltd_dw].[process].[PII_Column_Info] WITH (NOLOCK)
  where recordDate = (select max(recordDate) from [ltd_dw].[process].[PII_Column_Info] with (nolock))
  and [db] <> 'Novus_HST'
GO
