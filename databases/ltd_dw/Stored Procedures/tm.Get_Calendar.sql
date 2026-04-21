SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		B. Eichberger
-- Create date: 12/17/2018
-- Description:	Centralized Calendar with foundation in Service Calendar from TMMain
-- Exec Sample: exec [tm].[Get_Calendar]
-- =============================================

CREATE   PROCEDURE [tm].[Get_Calendar]
AS



/*------------------LTD_GLOSSARY---------------
UPDATED BY:	Sopheap Suy
UPDATED DT:  10/31/2024
purpose	 :  Add object activities on who, what, when call this object
			write this data to aud.object_activity table everytime it's called */

SET NOCOUNT ON

DECLARE @SPROC VARCHAR(100)
SET @SPROC = OBJECT_SCHEMA_NAME(@@PROCID) + '.' + OBJECT_NAME(@@PROCID)

INSERT INTO DBA.[aud].[Object_Activity]
	([server_name], [database_name] ,[host_name], [System_User], [object_name]
	,[client_net_address], [local_net_address], [auth_Scheme], [last_read], [last_write]
	,[most_recent_sql_handle], [Timestamp], object_type)
SELECT DISTINCT @@SERVERNAME, DB_NAME(),HOST_NAME(),SYSTEM_USER, @SPROC,
	client_net_address, local_net_address , auth_Scheme, last_read, last_write 
	,most_recent_sql_handle, CURRENT_TIMESTAMP AS [Timestamp], 'PROC'
FROM sys.dm_exec_connections 
WHERE session_id = @@SPID ;

BEGIN TRY


DECLARE @StartDate DATE = '19980101', @NumberOfYears INT = 40;

DECLARE @CutoffDate DATE = DATEADD(YEAR, @NumberOfYears, @StartDate);

CREATE TABLE #dimDate
(
  [date]       DATE PRIMARY KEY, 
  calendar_id as convert(varchar(32),date,112)+100000000,
  [day]        AS DATEPART(DAY,      [date]),
  [month]      AS DATEPART(MONTH,    [date]),
  FirstOfMonth AS CONVERT(DATE, DATEADD(MONTH, DATEDIFF(MONTH, 0, [date]), 0)),
  [MonthName]  AS DATENAME(MONTH,    [date]),
  [week]       AS DATEPART(WEEK,     [date]),
  [ISOweek]    AS DATEPART(ISO_WEEK, [date]),
  [DayOfWeek]  AS DATEPART(WEEKDAY,  [date]),
  [quarter]    AS DATEPART(QUARTER,  [date]),
  [year]       AS DATEPART(YEAR,     [date]),
  FirstOfYear  AS CONVERT(DATE, DATEADD(YEAR,  DATEDIFF(YEAR,  0, [date]), 0)),
  Style112     AS CONVERT(CHAR(8),   [date], 112),
  Style101     AS CONVERT(CHAR(10),  [date], 101)
);

-- use the catalog views to generate as many rows as we need

INSERT #dimDate([date]) 
SELECT d
FROM
(
  SELECT d = DATEADD(DAY, rn - 1, @StartDate)
  FROM 
  (
    SELECT TOP (DATEDIFF(DAY, @StartDate, @CutoffDate)) 
      rn = ROW_NUMBER() OVER (ORDER BY s1.[object_id])
    FROM sys.all_objects AS s1
    CROSS JOIN sys.all_objects AS s2 
    ORDER BY s1.[object_id]
  ) AS x
) AS y;


-- drop TABLE [tm].[DW_CALENDAR]
if (select count(*) from sys.tables where name = 'DW_CALENDAR') = 0
BEGIN

CREATE TABLE [tm].[DW_CALENDAR](
	[CALENDAR_ID] [numeric](10, 0) NOT NULL,
	[TRANSIT_DIV_ID] [numeric](5, 0) NULL,
	[ACTIVATION_TIME] [datetime] NULL,
	[DEACTIVATION_TIME] [datetime] NULL,
	[EXCLUDE_DAY] [bit] NULL,
	[SECT15_SERVICE_TYPE_ID] [numeric](3, 0) NULL,
	[YYYYMMDD] [varchar](30) NULL,
	[CALENDAR_DATE] [date] NULL,
	[DayNo] [int] NULL,
	[DayOfWeek] [nvarchar](30) NULL,
	[DayOfWeekNbr] [int] NULL,
	[DayOfYear] [int] NULL,
	[WeekOfYear] [int] NULL,
	[WeekofYearKey] [int] NULL,
	[WeekOfMonth] [int] NULL,
	[WeekOfMonthKey] [int] NULL,
	[Month] [int] NULL,
	[MonthName] [nvarchar](33) NULL,
	[MonthNameText] [nvarchar](30) NULL,
	[FiscalPeriod] [int] NOT NULL,
	[Quarter] [varchar](2) NULL,
	[QuarterName] [varchar](2) NULL,
	[Fiscal Quarter] [int] NULL,
	[Fiscal Quarter Name] [nvarchar](32) NULL,
	[Year] [int] NULL,
	[FiscalYear] [int] NULL,
	[Fiscal Year Name] [varchar](32) NULL,
	[isHoliday] [int] NOT NULL,
	[CalculatedMonthAge] [int] NULL,
	[IsCurrentMonth] [bit] NULL,
	[Current MTD This Year] [bit] NULL,
	[Current MTD Last Year] [bit] NULL,
	[Last 30 Days] [bit] NULL,
	[Last 60 Days] [bit] NULL,
	[Last 90 Days] [bit] NULL,
	[Prior 90 Days] [bit] NULL,
	[Last 10 Working Days] [bit] NULL,
	[Last 30 Working Days] [bit] NULL,
	[Last 60 Working Days] [bit] NULL,
	[Last 90 Working Days] [bit] NULL,
	[YearMonth] [varchar](34) NULL,
	[Last Full Month] [bit] NULL,
	[Last Full 6 Months] [bit] NULL,
	[Last Full 12 Months] [bit] NULL,
	[Last Full 9 Months] [bit] NULL,
	[Last 9 Months To Date] [bit] NULL,
	[Previous Date Full 6 Months] [bit] NULL
) ON [PRIMARY]
END

DROP TABLE IF EXISTS #tm_Calendar

--truncate table [LTD_DW].[tm].[DW_CALENDAR]
;
 With countdays AS (
                SELECT * FROM (
                SELECT [CALENDAR_DATE],ROW_NUMBER() OVER (PARTITION BY 1 ORDER BY [CALENDAR_DATE] DESC) CountDateNumber 
				FROM [LTD-TMDATA].[TMMain].dbo.[service_calendar] Where datepart("dw",[CALENDAR_DATE]) IN (2,3,4,5,6) AND [CALENDAR_DATE] < GETDATE()
                ) o WHERE CountDateNumber <= 120
				)

--write into #tm_Calendar table instead              
--INSERT tm.DW_CALENDAR
SELECT d.[CALENDAR_ID]
      ,[TRANSIT_DIV_ID]
      ,[ACTIVATION_TIME]
      ,[DEACTIVATION_TIME]
      ,[EXCLUDE_DAY]
      ,[SECT15_SERVICE_TYPE_ID]
	  ,CONVERT(VARCHAR, d.Date, 112) AS [YYYYMMDD]
  ,CAST(d.[Date] AS DATE) AS CALENDAR_DATE 
  ,DATEPART(DAY, d.Date) AS [DayNo]
  ,DATENAME(dw, d.Date) AS [DayOfWeek]
  ,DATEPART(dw, d.Date) AS [DayOfWeekNBR]
  ,DATEPART(DAYOFYEAR, d.Date) AS [DayOfYear]
  ,DATEPART(WEEK, d.Date) AS [WeekOfYear]
  ,[WeekofYearKey] = CAST([Year] AS VARCHAR(32))
		+ RIGHT('00'+CAST([month] AS VARCHAR(3)),2)
		+ RIGHT('00'+CAST(DATEPART(WEEK, d.Date) AS VARCHAR(3)),2) 
  ,(DATEPART(WEEK, d.Date) + 1 - DATEPART(WEEK, CAST(DATEPART(MONTH, d.Date) AS VARCHAR) + '/1/' + CAST(DATEPART(YEAR, d.Date) AS VARCHAR))) AS [WeekOfMonth]
  ,[WeekOfMonthKey] = CAST([Year] AS VARCHAR(32))
		+ RIGHT('00'+CAST([month] AS VARCHAR(3)),2)
		+ RIGHT('00'+CAST((DATEPART(WEEK, d.Date) + 1 - DATEPART(WEEK, CAST(DATEPART(MONTH, d.Date) AS VARCHAR) + '/1/' + CAST(DATEPART(YEAR, d.Date) AS VARCHAR))) AS VARCHAR(3)),2) 
  ,DATEPART(MONTH, d.Date) AS [Month]
  ,RIGHT('00' + CAST(DATEPART(MONTH, d.Date) AS VARCHAR(32)), 2) + ' ' + DATENAME(MONTH, d.Date) AS [MonthName]
  ,DATENAME(MONTH, d.Date) AS [MonthNameText]
  ,CASE WHEN DATEPART(MONTH, d.Date) BETWEEN 7 AND 12 THEN DATEPART(MONTH,d.Date) - 6
		WHEN DATEPART(MONTH, d.Date) BETWEEN 1 AND 6 THEN DATEPART(MONTH,d.Date) + 6
			END FiscalPeriod 
  ,DATEPART(QUARTER, d.Date) AS [Quarter]
  ,CASE DATEPART(QUARTER, d.Date)
   WHEN 1
    THEN 'Q1'
   WHEN 2
    THEN 'Q2'
   WHEN 3
    THEN 'Q3'
   WHEN 4
    THEN 'Q4'
   END AS [QuarterName]
   ,CASE DATEPART(QUARTER, d.Date)
   WHEN 1
    THEN 3
   WHEN 2
    THEN 4
   WHEN 3
    THEN 1
   WHEN 4
    THEN 2
   END AS [FiscalQuarter]
   ,CASE DATEPART(QUARTER, d.Date)
   WHEN 1
    THEN 'Fiscal Qtr 3'
   WHEN 2
    THEN 'Fiscal Qtr 4'
   WHEN 3
    THEN 'Fiscal Qtr 1'
   WHEN 4
    THEN 'Fiscal Qtr 2'
   END AS [FiscalQuarterName]
  ,DATEPART(YEAR, d.Date) AS [Year]
  ,FiscalYear = (SELECT CAST(REPLACE(shortFY,'FY','') AS INT) FROM [dbo].[ltd_FiscalYear_Tbl](d.[CALENDAR_ID]))
  ,[Fiscal Year Name] = (SELECT longFY FROM [dbo].[ltd_FiscalYear_Tbl](d.[CALENDAR_ID]))
	--	cast(case when DATEPART(MONTH, d.Date) between 1 and 6 then DATEPART(YEAR, d.Date) 
	--else DATEPART(YEAR, d.Date) + 1 END - 1 as varchar(32)) + ' - ' + cast(case when DATEPART(MONTH, d.Date) between 1 and 6 then DATEPART(YEAR, d.Date) 
	--else DATEPART(YEAR, d.Date) + 1 END  as varchar(32)) 
 ,CASE WHEN DAY(d.Date) = 1 AND MONTH(d.Date) = 1 THEN 1
   WHEN DAY(d.Date) = 19 AND MONTH(d.Date) = 1 THEN 1
   WHEN DAY(d.Date) = 16 AND MONTH(d.Date) = 2 THEN 1
   WHEN DAY(d.Date) = 25 AND MONTH(d.Date) = 5 THEN 1
   WHEN DAY(d.Date) = 3 AND MONTH(d.Date) = 7 THEN 1
   WHEN DAY(d.Date) = 4 AND MONTH(d.Date) = 7 THEN 1
   WHEN DAY(d.Date) = 7 AND MONTH(d.Date) = 9 THEN 1
   WHEN DAY(d.Date) = 12 AND MONTH(d.Date) = 10 THEN 1
   WHEN DAY(d.Date) = 11 AND MONTH(d.Date) = 11 THEN 1
   WHEN DAY(d.Date) = 26 AND MONTH(d.Date) = 11 THEN 1
   WHEN DAY(d.Date) = 25 AND MONTH(d.Date) = 12 THEN 1
   ELSE 0 END AS isHoliday
   ,DATEDIFF(MONTH,EOMONTH(GETDATE()),d.Date) AS CalculatedMonthAge
   ,CAST(CASE WHEN MONTH(d.Date) = MONTH(GETDATE()) AND YEAR(d.Date) = YEAR(GETDATE()) THEN 1 ELSE 0 END AS BIT) AS [IsCurrentMonth]
                ,CAST(CASE WHEN MONTH(d.Date) = MONTH(GETDATE()) AND YEAR(d.Date) = YEAR(GETDATE()) 
                   AND CAST(d.Date AS DATE) < CAST(GETDATE() AS DATE)  THEN 1 ELSE 0 END AS BIT) AS [Current MTD This Year]
                ,CAST(CASE WHEN MONTH(d.Date) = MONTH(GETDATE()) AND YEAR(d.Date) = YEAR(GETDATE())-1 
                   AND DATEPART(DAY,CAST(d.Date AS DATE)) < DATEPART(DAY,CAST(GETDATE() AS DATE))  THEN 1 ELSE 0 END AS BIT) AS [Current MTD Last Year]
                ,CAST(CASE WHEN d.Date>=GETDATE()-31  AND CAST(d.Date AS DATE) < CAST(GETDATE() AS DATE)  THEN 1 ELSE 0 END AS BIT) AS [Last 30 Days]
                ,CAST(CASE WHEN d.Date>=GETDATE()-61  AND CAST(d.Date AS DATE) < CAST(GETDATE() AS DATE)  THEN 1 ELSE 0 END AS BIT) AS [Last 60 Days]
                ,CAST(CASE WHEN d.Date>=GETDATE()-91  AND CAST(d.Date AS DATE) < CAST(GETDATE() AS DATE)  THEN 1 ELSE 0 END AS BIT) AS [Last 90 Days]
                ,CAST(CASE WHEN d.Date >= GETDATE()-121 AND d.Date <= GETDATE()-31 AND CAST(d.Date AS DATE) < CAST(GETDATE() AS DATE)  THEN 1 ELSE 0 END AS BIT) AS [Prior 90 Days]
                ,CAST(CASE WHEN ISNULL(c.CountDateNumber,-1)>0 AND c.CountDateNumber<=11 AND CAST(d.Date AS DATE) < CAST(GETDATE() AS DATE) THEN 1 ELSE 0 END AS BIT) AS [Last 10 Working Days]
                ,CAST(CASE WHEN ISNULL(c.CountDateNumber,-1)>0 AND c.CountDateNumber<=31 AND CAST(d.Date AS DATE) < CAST(GETDATE() AS DATE) THEN 1 ELSE 0 END AS BIT) AS [Last 30 Working Days]
                ,CAST(CASE WHEN ISNULL(c.CountDateNumber,-1)>0 AND c.CountDateNumber<=61 AND CAST(d.Date AS DATE) < CAST(GETDATE() AS DATE) THEN 1 ELSE 0 END AS BIT) AS [Last 60 Working Days]
                ,CAST(CASE WHEN ISNULL(c.CountDateNumber,-1)>0 AND c.CountDateNumber<=91 AND CAST(d.Date AS DATE) < CAST(GETDATE() AS DATE) THEN 1 ELSE 0 END AS BIT) AS [Last 90 Working Days]
                ,CAST(YEAR(d.Date) AS VARCHAR(32)) + RIGHT('00'+CAST(MONTH(d.Date) AS VARCHAR(32)),2) AS YearMonth
                ,CAST(CASE WHEN DATEDIFF(MONTH,EOMONTH(GETDATE()),d.Date) = -1 THEN 1 ELSE 0 END AS BIT) AS [Last Full Month]
                ,CAST(CASE WHEN DATEDIFF(MONTH,EOMONTH(GETDATE()),d.Date) IN (-1,-2,-3,-4,-5,-6) THEN 1 ELSE 0 END AS BIT) AS [Last Full 6 Months]
                ,CAST(CASE WHEN DATEDIFF(MONTH,EOMONTH(GETDATE()),d.Date) IN (-1,-2,-3,-4,-5,-6,-7,-8,-9,-10,-11,-12) THEN 1 ELSE 0 END AS BIT) AS [Last Full 12 Months]
                ,CAST(CASE WHEN DATEDIFF(MONTH,EOMONTH(GETDATE()),d.Date) IN (-1,-2,-3,-4,-5,-6,-7,-8,-9) THEN 1 ELSE 0 END AS BIT) AS [Last Full 9 Months]
                ,CAST(CASE WHEN DATEDIFF(MONTH,EOMONTH(GETDATE()),d.Date) IN (0,-1,-2,-3,-4,-5,-6,-7,-8) AND CAST(d.Date AS DATE) < CAST(GETDATE() AS DATE) THEN 1  ELSE 0 END AS BIT) AS [Last 9 Months To Date]
                ,CAST(CASE WHEN DATEDIFF(MONTH,EOMONTH(GETDATE()),d.Date) IN (-1,-2,-3,-4,-5,-6) THEN 1 ELSE 0 END AS BIT) AS [Previous Date Full 6 Months]
  INTO #tm_Calendar
  FROM #dimDate d
  LEFT JOIN [LTD-TMDATA].[TMMain].dbo.[service_calendar] sc ON sc.calendar_id = d.calendar_id 
  LEFT JOIN countdays c ON c.Calendar_Date = d.Date
  WHERE d.[date] <= CAST(GETDATE() AS DATE)
 
  --insert new rows
  INSERT tm.DW_CALENDAR( [CALENDAR_ID]
      ,[TRANSIT_DIV_ID]
      ,[ACTIVATION_TIME]
      ,[DEACTIVATION_TIME]
      ,[EXCLUDE_DAY]
      ,[SECT15_SERVICE_TYPE_ID]
      ,[YYYYMMDD]
      ,[CALENDAR_DATE]
      ,[DayNo]
      ,[DayOfWeek]
      ,[DayOfWeekNbr]
      ,[DayOfYear]
      ,[WeekOfYear]
      ,[WeekofYearKey]
      ,[WeekOfMonth]
      ,[WeekOfMonthKey]
      ,[Month]
      ,[MonthName]
      ,[MonthNameText]
      ,[FiscalPeriod]
      ,[Quarter]
      ,[QuarterName]
      ,[Fiscal Quarter]
      ,[Fiscal Quarter Name]
      ,[Year]
      ,[FiscalYear]
      ,[Fiscal Year Name]
      ,[isHoliday]
      ,[CalculatedMonthAge]
      ,[IsCurrentMonth]
      ,[Current MTD This Year]
      ,[Current MTD Last Year]
      ,[Last 30 Days]
      ,[Last 60 Days]
      ,[Last 90 Days]
      ,[Prior 90 Days]
      ,[Last 10 Working Days]
      ,[Last 30 Working Days]
      ,[Last 60 Working Days]
      ,[Last 90 Working Days]
      ,[YearMonth]
      ,[Last Full Month]
      ,[Last Full 6 Months]
      ,[Last Full 12 Months]
      ,[Last Full 9 Months]
      ,[Last 9 Months To Date]
      ,[Previous Date Full 6 Months])
  
  SELECT  [CALENDAR_ID]
      ,[TRANSIT_DIV_ID]
      ,[ACTIVATION_TIME]
      ,[DEACTIVATION_TIME]
      ,[EXCLUDE_DAY]
      ,[SECT15_SERVICE_TYPE_ID]
      ,[YYYYMMDD]
      ,[CALENDAR_DATE]
      ,[DayNo]
      ,[DayOfWeek]
      ,[DayOfWeekNbr]
      ,[DayOfYear]
      ,[WeekOfYear]
      ,[WeekofYearKey]
      ,[WeekOfMonth]
      ,[WeekOfMonthKey]
      ,[Month]
      ,[MonthName]
      ,[MonthNameText]
      ,[FiscalPeriod]
      ,[Quarter]
      ,[QuarterName]
      ,[FiscalQuarter]
      ,[FiscalQuarterName]
      ,[Year]
      ,[FiscalYear]
      ,[Fiscal Year Name]
      ,[isHoliday]
      ,[CalculatedMonthAge]
      ,[IsCurrentMonth]
      ,[Current MTD This Year]
      ,[Current MTD Last Year]
      ,[Last 30 Days]
      ,[Last 60 Days]
      ,[Last 90 Days]
      ,[Prior 90 Days]
      ,[Last 10 Working Days]
      ,[Last 30 Working Days]
      ,[Last 60 Working Days]
      ,[Last 90 Working Days]
      ,[YearMonth]
      ,[Last Full Month]
      ,[Last Full 6 Months]
      ,[Last Full 12 Months]
      ,[Last Full 9 Months]
      ,[Last 9 Months To Date]
      ,[Previous Date Full 6 Months] 
  FROM #tm_Calendar c
  WHERE NOT EXISTS (SELECT 1 FROM tm.DW_CALENDAR d
	WHERE c.calendar_id = d.CALENDAR_ID
	AND c.CALENDAR_DATE = d.CALENDAR_DATE )

	-- update element that could change	
  UPDATE c
  SET c.TRANSIT_DIV_ID = d.TRANSIT_DIV_ID,
	  c.ACTIVATION_TIME = d.ACTIVATION_TIME,
	  c.DEACTIVATION_TIME = d.DEACTIVATION_TIME,
	  c.EXCLUDE_DAY = d.EXCLUDE_DAY,
	  c.SECT15_SERVICE_TYPE_ID = d.SECT15_SERVICE_TYPE_ID,
	  c.YYYYMMDD = d.YYYYMMDD,
	  c.CALENDAR_DATE = d.CALENDAR_DATE,
	  c.DayNo = d.DayNo,
	  c.[DayOfWeek] = d.[DayOfWeek],
  	  c.DayOfWeekNbr = d.DayOfWeekNBR,
	  c.[DayOfYear] = d.[DayOfYear],
	  c.WeekOfYear = d.WeekOfYear,
	  c.WeekofYearKey = d.WeekofYearKey,
	  c.WeekOfMonth = d.WeekOfMonth,
	  c.WeekOfMonthKey = d.WeekOfMonthKey,
	  c.[Month] = d.[Month],
	  c.[MonthName] = d.[MonthName],
	  c.MonthNameText = d.MonthNameText,
	  c.FiscalPeriod = d.FiscalPeriod,
	  c.[Quarter] = d.[Quarter],
	  c.QuarterName = d.QuarterName,
	  c.[Fiscal Quarter] = d.FiscalQuarter,
	  c.[Fiscal Quarter Name] = d.FiscalQuarterName,
	  c.[Year] = d.[Year],
	  c.FiscalYear = d.FiscalYear,
	  c.[Fiscal Year Name] = d.[Fiscal Year Name],
	  c.isHoliday = d.isHoliday,

	  c.CalculatedMonthAge = d.CalculatedMonthAge,
	  c.IsCurrentMonth = d.IsCurrentMonth,
	  c.[Current MTD This Year] = d.[Current MTD This Year],
	  c.[Current MTD Last Year] = d.[Current MTD Last Year],
	  c.[Last 30 Days] = d.[Last 30 Days],
	  c.[Last 60 Days] = d.[Last 60 Days],
	  c.[Last 90 Days] = d.[Last 90 Days],
	  c.[Prior 90 Days] = d.[Prior 90 Days],
	  c.[Last 10 Working Days] = d.[Last 10 Working Days],
	  c.[Last 30 Working Days] = d.[Last 30 Working Days],
	  c.[Last 60 Working Days] = d.[Last 60 Working Days],
	  c.[Last 90 Working Days] = d.[Last 90 Working Days],
	  c.[Last Full Month] = d.[Last Full Month],
	  c.[Last Full 6 Months] = d.[Last Full 6 Months],
	  c.[Last Full 12 Months] = d.[Last Full 12 Months],
	  c.[Last Full 9 Months] = d.[Last Full 9 Months],
	  c.[Last 9 Months To Date] = d.[Last 9 Months To Date],
	  c.[Previous Date Full 6 Months] = d.[Previous Date Full 6 Months]
  --SELECT d.*
  FROM tm.DW_CALENDAR c 
  INNER JOIN #tm_Calendar d
	ON  c.calendar_id = d.CALENDAR_ID
	AND c.CALENDAR_DATE = d.CALENDAR_DATE 
  WHERE (c.CalculatedMonthAge <> d.CalculatedMonthAge
	 OR c.IsCurrentMonth <> d.IsCurrentMonth
	 OR c.[Current MTD This Year] <> d.[Current MTD This Year]
	 OR c.[Current MTD Last Year] <> d.[Current MTD Last Year]
	 OR c.[Last 30 Days] <> d.[Last 30 Days]
	 OR c.[Last 60 Days] <> d.[Last 60 Days]
	 OR c.[Last 90 Days] <> d.[Last 90 Days]
	 OR c.[Prior 90 Days] <> d.[Prior 90 Days]
	 OR c.[Last 10 Working Days] <> d.[Last 10 Working Days]
	 OR c.[Last 30 Working Days] <> d.[Last 30 Working Days]
	 OR c.[Last 60 Working Days] <> d.[Last 60 Working Days]
	 OR c.[Last 90 Working Days] <> d.[Last 90 Working Days]
	 OR c.[Last Full Month] <> d.[Last Full Month]
	 OR c.[Last Full 6 Months] <> d.[Last Full 6 Months]
	 OR c.[Last Full 12 Months] <> d.[Last Full 12 Months]
	 OR c.[Last Full 9 Months] <> d.[Last Full 9 Months]
	 OR c.[Last 9 Months To Date] <> d.[Last 9 Months To Date]
	 OR c.[Previous Date Full 6 Months] <> d.[Previous Date Full 6 Months]
	 
	 OR ISNULL( c.TRANSIT_DIV_ID,0) <> ISNULL(d.TRANSIT_DIV_ID,0)
	 OR ISNULL( c.ACTIVATION_TIME,'1900-01-01') <> ISNULL(d.ACTIVATION_TIME,'1900-01-01')
	 OR ISNULL(c.DEACTIVATION_TIME,'1900-01-01') <> ISNULL(d.DEACTIVATION_TIME,'1900-01-01')
	 OR ISNULL(c.EXCLUDE_DAY,0) <> ISNULL(d.EXCLUDE_DAY,0)
	 OR ISNULL(c.SECT15_SERVICE_TYPE_ID,0) <> ISNULL(d.SECT15_SERVICE_TYPE_ID,0)
	 OR c.YYYYMMDD <> d.YYYYMMDD
	 OR c.CALENDAR_DATE <> d.CALENDAR_DATE
	 OR c.DayNo <> d.DayNo
	 OR c.[DayOfWeek] <> d.[DayOfWeek]
  	 OR c.DayOfWeekNbr <> d.DayOfWeekNBR
	 OR c.[DayOfYear] <> d.[DayOfYear]
	 OR c.WeekOfYear <> d.WeekOfYear
	 OR c.WeekofYearKey <> d.WeekofYearKey
	 OR c.WeekOfMonth <> d.WeekOfMonth
	 OR c.WeekOfMonthKey <> d.WeekOfMonthKey
	 OR c.[Month] <> d.[Month]
	 OR c.[MonthName] <> d.[MonthName]
	 OR c.MonthNameText <> d.MonthNameText
	 OR c.FiscalPeriod <> d.FiscalPeriod
	 OR c.[Quarter] <> d.[Quarter]
	 OR c.QuarterName <> d.QuarterName
	 OR c.[Fiscal Quarter] <> d.FiscalQuarter
	 OR c.[Fiscal Quarter Name] <> d.FiscalQuarterName
	 OR c.[Year] <> d.[Year]
	 OR c.FiscalYear <> d.FiscalYear
	 OR c.[Fiscal Year Name] <> d.[Fiscal Year Name]
	 OR c.isHoliday <> d.isHoliday
	 )


END TRY	  

BEGIN CATCH

       DECLARE @profile VARCHAR(255) = (
                    SELECT NAME
                    FROM msdb.dbo.sysmail_profile
                    )
       DECLARE @errormsg VARCHAR(MAX)
             ,@error INT
             ,@message VARCHAR(MAX)
             ,@xstate INT
             ,@errsev INT
             ,@sub VARCHAR(255);

       SELECT @error = ERROR_NUMBER()
             ,@errsev = ERROR_SEVERITY()
             ,@message = ERROR_MESSAGE()
             ,@xstate = XACT_STATE();

       SELECT @errormsg = 'Error in ' + ISNULL(@SPROC, '') + ': ' + CAST(ISNULL(@error, '') AS NVARCHAR(32)) + '|' + COALESCE(@message, '') + '|' + CAST(ISNULL(@xstate, '') AS NVARCHAR(32)) + '|' +CAST(ISNULL(@errsev, '') AS NVARCHAR(32))

       SELECT @sub = 'ERROR: ' + @SPROC

       EXEC msdb.dbo.sp_send_dbmail @profile_name = @profile
             ,@recipients = 'barb.eichberger@ltd.org;servicedesk@ltd.org' 
             ,@subject = @sub
             ,@body = @errormsg;

       RAISERROR (
                    @errormsg
                    ,@errsev
                    ,1
                    )
END CATCH
GO
