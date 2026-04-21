SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   PROCEDURE [sbp].[MetricUpdate]
 @sbphistoryMetricKey INT NULL
,@sbpMetricKey INT NULL
,@sbpMETRICNameLabel VARCHAR(90) NULL
,@sbpMETRICCode VARCHAR(30) NULL
,@sbpMETRICDesc VARCHAR(256) NULL
,@sbpMETRICGroup VARCHAR(30) NULL
,@sbpMETRICDataType VARCHAR(90) NULL
,@sbpUserName varchar(90) NULL
,@sbpNoLongerActive DATE  NULL
AS
BEGIN

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




IF OBJECT_ID('tempdb..#MetricTemp') IS NOT NULL
	DROP TABLE #MetricTemp

--create a temp table for old and new values
CREATE TABLE #MetricTemp (
	Direction VARCHAR(90) NOT NULL,
    [sbpMetricKey] INT NULL,
	[historysbpMETRICKey] [INT] NULL,
	[sbpMETRICNameDataedo] [VARCHAR](90) NOT NULL,
	[sbpMETRICNameLabel] [VARCHAR](90) NOT NULL,
	[sbpMETRICCode] [VARCHAR](30) NOT NULL,
	[sbpMETRICDesc] [VARCHAR](256) NOT NULL,
	[sbpMETRICGroup] [VARCHAR](30) NOT NULL,
	[sbpMETRICDataType] [VARCHAR](90) NOT NULL,
	[sbpMETRICCreateDate] [DATETIME2](7) NOT NULL,
	[sbpMETRICCreatedBy] [VARCHAR](90) NOT NULL,
	[sbpMETRICUpdatedLast] [DATETIME2](7) NULL,
	[sbpMETRICUpdatedBy] [VARCHAR](90) NULL,
	[sbpMETRICNoLongerActiveDate] [DATETIME] NULL,
	[sbpMETRICHistoryRankorder] [INT] NULL,
	)

-- get the previous values
INSERT INTO #MetricTemp (
	   Direction
	  ,[sbpMetricKey]
	  ,[historysbpMETRICKey]
      ,[sbpMETRICNameDataedo]
      ,[sbpMETRICNameLabel]
      ,[sbpMETRICCode]
      ,[sbpMETRICDesc]
      ,[sbpMETRICGroup]
      ,[sbpMETRICDataType]
      ,[sbpMETRICCreateDate]
      ,[sbpMETRICCreatedBy]
      ,[sbpMETRICUpdatedLast]
      ,[sbpMETRICUpdatedBy]
      ,[sbpMETRICNoLongerActiveDate]
      ,[sbpMETRICHistoryRankorder]
	)
SELECT 'Previous Value'
      ,[sbpMetricKey]
	  ,[historysbpMETRICKey]
      ,[sbpMETRICNameDataedo]
      ,[sbpMETRICNameLabel]
      ,[sbpMETRICCode]
      ,[sbpMETRICDesc]
      ,[sbpMETRICGroup]
      ,[sbpMETRICDataType]
      ,[sbpMETRICCreateDate]
      ,[sbpMETRICCreatedBy]
      ,[sbpMETRICUpdatedLast]
      ,[sbpMETRICUpdatedBy]
      ,[sbpMETRICNoLongerActiveDate]
      ,[sbpMETRICHistoryRankorder]
FROM sbp.Metric
WHERE [historysbpMETRICKey] = 1--  @sbphistoryMetricKey
	AND sbpMETRICHistoryRankorder = 1
	
SELECT * FROM #MetricTemp

	update sbp.Metric 
	set [sbpMETRICHistoryRankorder] = [sbpMETRICHistoryRankorder] + 1
	FROM sbp.metric
	WHERE historysbpMETRICKey = @sbphistoryMetricKey
	


	INSERT sbp.Metric (
	  [historysbpMETRICKey]
      ,[sbpMETRICNameDataedo]
      ,[sbpMETRICNameLabel]
      ,[sbpMETRICCode]
      ,[sbpMETRICDesc]
      ,[sbpMETRICGroup]
      ,[sbpMETRICDataType]
      ,[sbpMETRICCreateDate]
      ,[sbpMETRICCreatedBy]
      ,[sbpMETRICUpdatedLast]
      ,[sbpMETRICUpdatedBy]
      ,[sbpMETRICNoLongerActiveDate]
      ,[sbpMETRICHistoryRankorder]
		)
	select [historyMetricKey] = @sbpMetricKey
	  , [sbpMETRICNameDataedo]
	  , [sbpMETRICNameLabel] = @sbpMETRICNameLabel
	  , [sbpMETRICCode] = @sbpMetricCode
      ,[sbpMETRICDesc] = @sbpMetricDesc
      ,[MetricGroup] = @sbpMetricGroup
      ,[sbpMETRICDataType] = @sbpMETRICDataType
	  ,[sbpMETRICCreateDate]
	  ,[sbpMETRICCreatedBy]
      ,[sbpMETRICUpdatedLast] = SYSDATETIME()
      ,[sbpMETRICUpdatedBy] = @sbpUserName
	  ,@sbpNoLongerActive
	  ,0 
	  from #MetricTemp
	
	
	update sbp.Metric 
	set [sbpMETRICHistoryRankorder] = [sbpMETRICHistoryRankorder] + 1
	WHERE [historysbpMETRICKey] = @sbphistoryMetricKey AND [sbpMETRICHistoryRankorder] = 0

-- output back to report
SELECT [sbpMETRICKey]
	  ,[historysbpMETRICKey]
      ,[sbpMETRICNameDataedo]
      ,[sbpMETRICNameLabel]
      ,[sbpMETRICCode]
      ,[sbpMETRICDesc]
      ,[sbpMETRICGroup]
      ,[sbpMETRICDataType]
      ,[sbpMETRICCreateDate]
      ,[sbpMETRICCreatedBy]
      ,[sbpMETRICUpdatedLast]
      ,[sbpMETRICUpdatedBy]
      ,[sbpMETRICNoLongerActiveDate]
	  ,[sbpMETRICHistoryRankorder]
FROM sbp.Metric
WHERE [historysbpMETRICKey] = @sbpMetricKey
and [sbpMETRICHistoryRankorder] = 1
END
GO
