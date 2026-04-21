SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE view [ops].[dailyEmployeeTimeDetail_v]
as

/*

------------------LTD_GLOSSARY---------------
created by: b eichberger
created dt: 2024-05-28

*/

select [opDate]
      ,[division]
      ,[emp_SID]
      ,[detailSequence]
      ,[paySource]
      ,[payType]
      ,[payDate]
      ,[workDivision]
      ,[runNumber]
      ,[blockRoute]
      ,[blockID]
      ,[workClass]
      ,[keyTime]
      ,[originalTime]
      ,[paidTime]
      ,[calcTime]
      ,[timeAtStraight]
      ,[timeAtOT]
      ,[dailyTKDetailFlags]
      ,[workAccount]
      ,[recType]
      ,[userID]
      ,[userTime]
      ,[comment]
  from [LTD-OPS].[midas].[dbo].[dailyEmployeeTimeDetail] with (nolock)
GO
