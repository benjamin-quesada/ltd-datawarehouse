SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [ops].[dailyPieceDetail_v]
as
SELECT [division]
      ,[timeCode]
      ,[opDate]
      ,[blockRoute]
      ,[schWorkTime]
      ,[actWorkTime]
      ,[blockID]
      ,[workClass]
      ,[keyTime]
      ,[schAllowedTime]
      ,[actAllowedTime]
      ,[pieceDtFlag]
  FROM [LTD-OPS].midas.[dbo].[dailyPieceDetail]
GO
