SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*---LTD_GLOSSARY----------------------
CREATED		: 10/10/2019
AUTHOR		: B Eichberger
PURPOSE		: 

Updated		: 06/27/2024
UPDATED BY	: Sopheap Suy
PURPOSE		: add distinct to query

*/




CREATE VIEW [itk].[vehicle_accidents_v]
AS
SELECT DISTINCT
	dr.number FileNumber
      ,dr.CreatedBy
      ,dr.Occured
      ,CAST(e.EmployeeID AS NUMERIC(6,0)) EmployeeNumber
      ,dr.specific
      ,dr.category
	  ,dr.[Type]
      ,ai.BusNumber
      ,ai.RouteNumber
      ,ai.Street
      ,ai.CrossStreet
      ,ai.BodilyInjury
      ,ai.PropertyDamage
      ,ai.Preventable
	  ,ds.SelectionText
  FROM [LTD-ITRAK].[iXData].[dbo].[ltd_vehicle_accident_iform]   ai
  LEFT JOIN [LTD-ITRAK].[iXData].[dbo].[DetailedReport]        dr ON dr.number            = ai.FileNumber
  LEFT JOIN [LTD-ITRAK].[iXData].[dbo].[ParticipantAssignment] p  ON p.DetailedReportGUID = dr.DetailedReportGUID
  LEFT JOIN [LTD-ITRAK].[iXData].[dbo].[Employee]              e  ON e.EmployeeGUID       = p.ParticipantGUID
  LEFT JOIN [LTD-ITRAK].[iXData].[dbo].[DropDownSelection]     ds ON ds.SelectionGUID     = p.ParticipantRole 
WHERE dr.Number IS NOT NULL 
      AND dr.CreatedBy IS NOT NULL
      AND dr.Occured IS NOT NULL
      AND dr.specific IS NOT NULL
      AND dr.category IS NOT NULL
	  AND dr.[Type] IS NOT NULL
      AND ai.BusNumber IS NOT NULL
      AND ai.RouteNumber IS NOT NULL
      AND ai.Street IS NOT NULL
      AND ai.CrossStreet IS NOT NULL
      AND ai.BodilyInjury IS NOT NULL
      AND ai.PropertyDamage IS NOT NULL
	  AND ds.SelectionText IS NOT NULL

GO
