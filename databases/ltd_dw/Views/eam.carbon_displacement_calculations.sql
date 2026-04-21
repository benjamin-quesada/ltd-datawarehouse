SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [eam].[carbon_displacement_calculations]
as
--grant select on eam.carbon_displacement_calculations to rpt_reader

SELECT z.Calendar_Date
,CASE WHEN ElectricNotElectric = 'Electric' THEN Vehicle_miles END AS ElectricMiles	
--,MAX(CASE WHEN ElectricNotElectric = 'Non Electric' THEN Vehicle_miles END) AS NonElectricMiles	
,carbon_tons_displaced = ((CASE WHEN ElectricNotElectric = 'Electric' THEN Vehicle_miles END)*1078)/907185.0
FROM (
SELECT CAST(a."[Vehicle].[Electric or Non Electric].[Electric or Non Electric].[MEMBER_CAPTION]" AS VARCHAR(32)) AS ElectricNotElectric,
CAST(a."[Calendar].[Calendar Date].[Calendar Date].[MEMBER_CAPTION]" AS VARCHAR(32)) AS Calendar_Date,
isnull(CAST(a."[Measures].[Miles by Date]" AS NUMERIC(12,4)),0) AS Vehicle_Miles
FROM OPENQUERY([LTD-ANALYSIS],' SELECT NON EMPTY { [Measures].[Miles by Date] } ON COLUMNS, NON EMPTY { ([Vehicle].[Electric or Non Electric].[Electric or Non Electric].ALLMEMBERS * [Calendar].[Calendar Date].[Calendar Date].ALLMEMBERS ) } DIMENSION PROPERTIES MEMBER_CAPTION, MEMBER_UNIQUE_NAME ON ROWS FROM [Model] CELL PROPERTIES VALUE, BACK_COLOR, FORE_COLOR, FORMATTED_VALUE, FORMAT_STRING, FONT_NAME, FONT_SIZE, FONT_FLAGS') as a
where len(CAST(a."[Vehicle].[Electric or Non Electric].[Electric or Non Electric].[MEMBER_CAPTION]" AS VARCHAR(32))) > 0
) z
JOIN tm.DW_CALENDAR c ON c.CALENDAR_DATE = z.Calendar_Date
WHERE c.DayOfWeekNbr not in ( 7,1)
and CASE WHEN ElectricNotElectric = 'Electric' THEN isnull(Vehicle_miles,0) END > 0
--GROUP BY z.Calendar_Date
--ORDER BY CAST(z.Calendar_date AS DATE)
GO
