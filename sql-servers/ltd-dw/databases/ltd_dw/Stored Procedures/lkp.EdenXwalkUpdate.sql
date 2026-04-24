SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   PROCEDURE [lkp].[EdenXwalkUpdate]  
@phistoryEdenXwalkKey INT NULL
,@pEdenXwalkKey INT NULL
,@pEdenXwalkCode VARCHAR(32)  NULL
,@pEdenXwalkName VARCHAR(255)  NULL
,@pEdenXwalkTouchPassName VARCHAR(30) NULL
,@pUserName varchar(90) NULL
,@pNoLongerActive DATE  NULL
AS


---- grant execute on [lkp].[EdenCustomerXwalkUpdate] to rpt_reader
---- exec [lkp].[EdenCustomerXwalkUpdate]  6,10,'REIMB','REIMBURSEMENT','Centene','A0090','LTD\Barb Eichberger','7/15/2019 15:30'
--declare @phistoryEdenXwalkKey INT = 47
--,@pEdenXwalkCode VARCHAR(32) = 'REIMB'
--,@pEdenXwalkName VARCHAR(255)  = 'REIMBURSEMENT'
--,@pEdenXwalkTouchPassName VARCHAR(30)='Centene'
--,@pLTDEdenXwalkCode varchar(30)='A0090'
--,@pUserName varchar(90)='LTD\Barb Eichberger'
--,@pNoLongerActive DATE  = NULL


/* ------------------LTD_GLOSSARY---------------
UPDATED BY:	Sopheap Suy
UPDATED DT:  10/31/2024
purpose	 :  Add object activities on who, what, when call this object
			write this data to aud.object_activity table everytime it's called */

SET NOCOUNT ON

INSERT INTO DBA.[aud].[Object_Activity]
	([server_name], [database_name] ,[host_name], [System_User], [object_name]
	,[client_net_address], [local_net_address], [auth_Scheme], [last_read], [last_write]
	,[most_recent_sql_handle], [Timestamp], object_type)
SELECT DISTINCT @@SERVERNAME, DB_NAME(),HOST_NAME(),SYSTEM_USER, '',
	client_net_address, local_net_address , auth_Scheme, last_read, last_write 
	,most_recent_sql_handle, CURRENT_TIMESTAMP AS [Timestamp], 'PROC'
FROM sys.dm_exec_connections 
WHERE session_id = @@SPID ;

IF OBJECT_ID('tempdb..#EdenXwalkTemp') IS NOT NULL
	DROP TABLE #EdenXwalkTemp

--create a temp table for old and new values
CREATE TABLE #EdenXwalkTemp (
	Direction VARCHAR(90) NOT NULL,
	[historyEdenXwalkKey] [int] NULL,
	[EdenXwalkCode] [varchar](30) NULL,
	[EdenXwalkName] [varchar](120) NULL,
	[EdenXwalkTouchPassName] [varchar](30) NOT NULL,
	[EdenXwalkCreateDate] [datetime2](7) NOT NULL,
	[EdenXwalkCreatedBy] [varchar](90) NULL,
	[EdenXwalkUpdatedLast] [datetime2](7) NULL,
	[EdenXwalkUpdatedBy] [varchar](90) NULL,
	[EdenXwalkNoLongerActiveDate] [datetime] NULL,
	[EdenXwalkHistoryRankorder] [int] NULL
	)

-- get the previous values
INSERT INTO #EdenXwalkTemp (
	Direction
	,[historyEdenXwalkKey]
	 ,[EdenXwalkCode]
      ,[EdenXwalkName]
      ,[EdenXwalkTouchPassName]
      ,[EdenXwalkCreateDate]
      ,[EdenXwalkCreatedBy]
      ,[EdenXwalkUpdatedLast]
      ,[EdenXwalkUpdatedBy]
      ,[EdenXwalkNoLongerActiveDate]
      ,[EdenXwalkHistoryRankorder]
	)
SELECT 'Previous Value'
	,[historyEdenXwalkKey]
	 ,[EdenXwalkCode]
      ,[EdenXwalkName]
      ,[EdenXwalkTouchPassName]
      ,[EdenXwalkCreateDate]
      ,[EdenXwalkCreatedBy]
      ,[EdenXwalkUpdatedLast]
      ,[EdenXwalkUpdatedBy]
      ,[EdenXwalkNoLongerActiveDate]
      ,[EdenXwalkHistoryRankorder]
FROM lkp.EdenXwalk
WHERE [historyEdenXwalkKey] = @phistoryEdenXwalkKey
	AND [EdenXwalkHistoryRankorder] = 1

--select * from #EdenXwalkTemp where historyEdenXwalkKey = 47
	
	
	update lkp.EdenXwalk 
	set [EdenXwalkHistoryRankorder] = [EdenXwalkHistoryRankorder] + 1
	WHERE [historyEdenXwalkKey] = @phistoryEdenXwalkKey
	


	--select * from lkp.EdenXwalk where [historyEdenXwalkKey] = 47
		-- update only the most recent row (historyrankorder 1)

	-- put the previous row back in to preserve history
	INSERT lkp.EdenXwalk (
		[historyEdenXwalkKey]
	 ,[EdenXwalkCode]
      ,[EdenXwalkName]
      ,[EdenXwalkTouchPassName]
      ,[EdenXwalkCreateDate]
      ,[EdenXwalkCreatedBy]
      ,[EdenXwalkUpdatedLast]
      ,[EdenXwalkUpdatedBy]
      ,[EdenXwalkNoLongerActiveDate]
      ,[EdenXwalkHistoryRankorder]
		)
	SELECT [historyEdenXwalkKey]
	,[EdenXwalkCode]
      ,[EdenXwalkName]
      ,[EdenXwalkTouchPassName]
      ,[EdenXwalkCreateDate]
      ,[EdenXwalkCreatedBy]
      ,[EdenXwalkUpdatedLast]
      ,[EdenXwalkUpdatedBy]
      ,[EdenXwalkNoLongerActiveDate] 
      ,[EdenXwalkHistoryRankorder]
	FROM #EdenXwalkTemp
	WHERE Direction = 'Previous Value'

	INSERT lkp.EdenXwalk (
		[historyEdenXwalkKey]
	 ,[EdenXwalkCode]
      ,[EdenXwalkName]
      ,[EdenXwalkTouchPassName]
      ,[EdenXwalkCreateDate]
      ,[EdenXwalkCreatedBy]
      ,[EdenXwalkUpdatedLast]
      ,[EdenXwalkUpdatedBy]
      ,[EdenXwalkNoLongerActiveDate]
      ,[EdenXwalkHistoryRankorder]
		)
	select [historyEdenXwalkKey] = @phistoryEdenXwalkKey
	, [EdenXwalkCode] = @pEdenXwalkCode
      ,[EdenXwalkName] = @pEdenXwalkName
      ,[EdenXwalkTouchPassName] = @pEdenXwalkTouchPassName
       ,EdenXwalkCreateDate
	  ,[EdenXwalkCreatedBy]
      ,[EdenXwalkUpdatedLast] = SYSDATETIME()
      ,[EdenXwalkUpdatedBy] = @pUserName
	  ,@pNoLongerActive
	  ,0 
	  from #EdenXwalkTemp
	
	
	update lkp.EdenXwalk 
	set [EdenXwalkHistoryRankorder] = [EdenXwalkHistoryRankorder] + 1
	WHERE [historyEdenXwalkKey] = @phistoryEdenXwalkKey

-- output back to report
SELECT [EdenXwalkKey]
      ,[historyEdenXwalkKey]
      ,[EdenXwalkCode]
      ,[EdenXwalkName]
      ,[EdenXwalkTouchPassName]
      ,[EdenXwalkCreateDate]
      ,[EdenXwalkCreatedBy]
      ,[EdenXwalkUpdatedLast]
      ,[EdenXwalkUpdatedBy]
      ,[EdenXwalkNoLongerActiveDate]
      ,[EdenXwalkHistoryRankorder]
FROM lkp.EdenXwalk
WHERE historyEdenXwalkKey = @phistoryEdenXwalkKey
--and [EdenXwalkHistoryRankorder] = 1
GO
