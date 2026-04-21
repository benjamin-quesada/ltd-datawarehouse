SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE   PROCEDURE [tm].[Get_Calendar_SPM27_plus1]
AS

-- =============LTD_GLOSSARY================================
-- Author:		B. Eichberger
-- Create date: 20220727
-- Description:	Centralized Calendar with foundation in Service Calendar from TMMain
-- 				Now WITH seconds past midnight (spm) expansion for new flyer/API/more
--				This version now runs day before, fills to tomorrow date (getdate() plus 1

-- Modified DT: 20240126
-- Modified By: Sopheap Suy fixed [Calendar Date Time] for spm >= 86400

-- Exec Sample: exec [tm].[Get_Calendar_SPM27_plus1]
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


DECLARE @CutoffDate DATE = (SELECT GETDATE()+2)
DECLARE @NumberOfYears INT = -1;

DECLARE @StartDate DATE = DATEADD(YEAR, @NumberOfYears, GETDATE());

--SELECT @CutoffDate
DROP TABLE IF EXISTS #dimDate
CREATE TABLE #dimDate
(
  [date]       DATE PRIMARY KEY, 
  calendar_id as convert(varchar(32),date,112)+100000000
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
 
 --select * from #dimDate order by calendar_id desc

if (select count(*) from sys.tables where name = 'DW_CALENDAR_SPM27_plus1') = 0
BEGIN

CREATE TABLE [tm].[DW_CALENDAR_SPM27_plus1](
	[CAL_SPM_KEY] [BIGINT] NOT NULL,
	[CALENDAR_ID] [NUMERIC](10, 0) NOT NULL,
	[SPM] [INT] NOT NULL,
	[YYYYMMDD] [VARCHAR](30) NULL,
	[Calendar Date Time] [DATETIME2](7) NOT NULL,
	[CALENDAR_DATE] [DATE] NOT NULL 
) ON [PRIMARY]
END


truncate table -- select top(100) * from 
[LTD_DW].[tm].[DW_CALENDAR_SPM27_plus1] -- ORDER BY [calendar date time] desc
DECLARE @min bigint, @max bigint
SELECT @Min=0 ,@Max=97200;
;
 WITH countdays AS (
                SELECT * FROM (
                SELECT [CALENDAR_DATE],ROW_NUMBER() OVER (PARTITION BY 1 ORDER BY [CALENDAR_DATE] DESC) CountDateNumber 
				FROM [LTD-TMDATA].tmmain.dbo.[service_calendar] WHERE [CALENDAR_DATE] < GETDATE()+2
					) o WHERE CountDateNumber <= 120
				
				)
, spm AS (
SELECT TOP (@Max-@Min+1) @Min-1+ROW_NUMBER() OVER(ORDER BY t1.number) AS N
FROM master..spt_values t1 
    CROSS JOIN master..spt_values t2
	)
	
INSERT tm.DW_CALENDAR_SPM27_plus1 (
[CAL_SPM_KEY]
      ,[CALENDAR_ID]
      ,[SPM]
      ,[YYYYMMDD]
      ,[Calendar Date Time]
      ,[CALENDAR_DATE]
     )
SELECT spm_key, a.calendar_id, a.N, a.YYYYMMDD
, CASE a.n WHEN 97200 THEN DATEADD(HOUR, 3,  a.[Calendar Date Time]) 
	ELSE a.[Calendar Date Time] END AS [Calendar Date Time]
, a.CALENDAR_DATE
FROM (
SELECT CAST(CAST(d.[CALENDAR_ID] AS VARCHAR(32)) + RIGHT('000000'+ CAST(spm.N AS VARCHAR(32)),6) AS BIGINT) AS spm_key
	  ,d.[CALENDAR_ID]
	  ,spm.N
	  , CONVERT(VARCHAR, d.Date, 112) AS [YYYYMMDD]	  
	  ,CASE WHEN (spm.n >= 86400) THEN 
				CAST( DATEADD(DAY, 1,CAST(d.[Date] AS DATE)) AS VARCHAR(32))
				+ ' '+RIGHT(CONVERT(VARCHAR, spm.N / 97200 ) + ':' + -- Days
					CONVERT(VARCHAR, DATEADD(ms, ( spm.N % 97200 ) * 1000, 0), 114),12)
			ELSE CAST(CAST(d.[Date] AS DATE) AS VARCHAR(32)) + ' '+ RIGHT(CONVERT(VARCHAR, spm.N / 97200 ) + ':' + -- Days
				CONVERT(VARCHAR, DATEADD(ms, ( spm.N % 97200 ) * 1000, 0), 114),12) END [Calendar Date Time]
	,CAST(d.[Date] AS DATE) AS CALENDAR_DATE 
FROM #dimDate d
  LEFT JOIN [LTD-TMDATA].[TMMain].dbo.[service_calendar] sc ON sc.calendar_id = d.calendar_id 
  LEFT JOIN countdays c ON c.Calendar_Date = d.Date
  CROSS JOIN spm
  WHERE d.[date] <= CAST(GETDATE()+2 AS DATE)
AND NOT EXISTS (SELECT 1 FROM tm.DW_CALENDAR_SPM27_plus1 WHERE CALENDAR_ID = d.calendar_id)
) a


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
