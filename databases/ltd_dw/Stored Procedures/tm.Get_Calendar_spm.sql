SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE   PROCEDURE [tm].[Get_Calendar_spm]
as

-- =============================================
-- Author:		B. Eichberger
-- Create date: 20210817
-- Description:	Centralized Calendar with foundation in Service Calendar from TMMain
-- 				Now WITH seconds past midnight (spm) expansion for new flyer/API/more
-- Exec Sample: exec [tm].[Get_Calendar_spm]
-- =============================================

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


DECLARE @CutoffDate DATE = (SELECT GETDATE())
DECLARE @NumberOfYears INT = -1;

DECLARE @StartDate DATE = DATEADD(YEAR, @NumberOfYears, GETDATE());

DROP TABLE IF EXISTS #dimDate
CREATE TABLE #dimDate
(
  [date]       DATE PRIMARY KEY, 
  calendar_id as convert(varchar(32),date,112)+100000000
  --,
  --[day]        AS DATEPART(DAY,      [date]),
  --[month]      AS DATEPART(MONTH,    [date]),
  --FirstOfMonth AS CONVERT(DATE, DATEADD(MONTH, DATEDIFF(MONTH, 0, [date]), 0)),
  --[MonthName]  AS DATENAME(MONTH,    [date]),
  --[week]       AS DATEPART(WEEK,     [date]),
  --[ISOweek]    AS DATEPART(ISO_WEEK, [date]),
  --[DayOfWeek]  AS DATEPART(WEEKDAY,  [date]),
  --[quarter]    AS DATEPART(QUARTER,  [date]),
  --[year]       AS DATEPART(YEAR,     [date]),
  --FirstOfYear  AS CONVERT(DATE, DATEADD(YEAR,  DATEDIFF(YEAR,  0, [date]), 0)),
  --Style112     AS CONVERT(CHAR(8),   [date], 112),
  --Style101     AS CONVERT(CHAR(10),  [date], 101)
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
    -- on my system this would support > 5 million days
    ORDER BY s1.[object_id]
  ) AS x
) AS y


if (select count(*) from sys.tables where name = 'DW_CALENDAR_SPM') = 0
BEGIN

CREATE TABLE [tm].[DW_CALENDAR_SPM](
	[CAL_SPM_KEY] [BIGINT] NOT NULL,
	[CALENDAR_ID] [NUMERIC](10, 0) NOT NULL,
	[SPM] [INT] NOT NULL,
	[YYYYMMDD] [VARCHAR](30) NULL,
	[Calendar Date Time] [DATETIME2](7) NOT NULL,
	[CALENDAR_DATE] [DATE] NOT NULL 
) ON [PRIMARY]
END


--truncate table [LTD_DW].[tm].[DW_CALENDAR_SPM]
DECLARE @min bigint, @max bigint
SELECT @Min=0 ,@Max=86400;
;
 With countdays AS (
                SELECT * FROM (
                SELECT [CALENDAR_DATE],ROW_NUMBER() OVER (PARTITION BY 1 ORDER BY [CALENDAR_DATE] DESC) CountDateNumber 
				FROM [LTD-TMDATA].[TMMain].dbo.[service_calendar] Where datepart("dw",[CALENDAR_DATE]) IN (2,3,4,5,6) AND [CALENDAR_DATE] < GETDATE()
                ) o WHERE CountDateNumber <= 120
				)
, spm as (
SELECT TOP (@Max-@Min+1) @Min-1+row_number() over(order by t1.number) as N
FROM master..spt_values t1 
    CROSS JOIN master..spt_values t2)
	
INSERT tm.DW_CALENDAR_SPM (
[CAL_SPM_KEY]
      ,[CALENDAR_ID]
      ,[SPM]
      ,[YYYYMMDD]
      ,[Calendar Date Time]
      ,[CALENDAR_DATE]
     )
SELECT CAST(d.[CALENDAR_ID] AS varchar(32)) + RIGHT('000000'+ CAST(spm.N AS varchar(32)),6) 
	  ,d.[CALENDAR_ID]
	  ,spm.N
	  ,CONVERT(VARCHAR, d.Date, 112) AS [YYYYMMDD]
  ,CAST(CAST(d.[Date] AS DATE) AS VARCHAR(32)) + ' '+RIGHT(CONVERT(varchar, spm.N / 86400 ) + ':' + -- Days
		CONVERT(varchar, DATEADD(ms, ( spm.N % 86400 ) * 1000, 0), 114),12) [Calendar Date Time]
  ,cast(d.[Date] AS DATE) as CALENDAR_DATE 
FROM #dimDate d
  LEFT join [LTD-TMDATA].[TMMain].dbo.[service_calendar] sc on sc.calendar_id = d.calendar_id 
  LEFT join countdays c on c.Calendar_Date = d.Date
  CROSS JOIN spm
  WHERE d.[date] <= cast(getdate() as date)
AND NOT EXISTS (SELECT 1 FROM tm.DW_CALENDAR_SPM WHERE CALENDAR_ID = d.calendar_id)

END TRY	  

BEGIN CATCH

       DECLARE @profile VARCHAR(255) = (
                    SELECT NAME
                    FROM msdb.dbo.sysmail_profile
                    )
       DECLARE @errormsg VARCHAR(max)
             ,@error INT
             ,@message VARCHAR(max)
             ,@xstate INT
             ,@errsev INT
             ,@sub VARCHAR(255);

       SELECT @error = ERROR_NUMBER()
             ,@errsev = ERROR_SEVERITY()
             ,@message = ERROR_MESSAGE()
             ,@xstate = XACT_STATE();

       SELECT @errormsg = 'Error in ' + isnull(@SPROC, '') + ': ' + cast(isnull(@error, '') AS NVARCHAR(32)) + '|' + coalesce(@message, '') + '|' + cast(isnull(@xstate, '') AS NVARCHAR(32)) + '|' +cast(isnull(@errsev, '') AS NVARCHAR(32))

       SELECT @sub = 'ERROR: ' + @SPROC

       EXEC msdb.dbo.sp_send_dbmail @profile_name = @profile
             ,@recipients = 'barb.eichberger@ltd.org' 
             ,@subject = @sub
             ,@body = @errormsg;

       RAISERROR (
                    @errormsg
                    ,@errsev
                    ,1
                    )
END CATCH
GO
