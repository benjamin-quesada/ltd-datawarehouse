SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   PROCEDURE [ftk].[FuelTicketUpdate]
@historyFuelTicketKey INT NULL,
@FuelTicketKey INT NULL ,
@FuelTicketDateStart VARCHAR(90) NULL,
@FuelTicketDateEnd VARCHAR(90) NULL,
@FuelTicketContext VARCHAR(30) NULL,
@PricePerkWh VARCHAR(256) NULL,
@ftkUser VARCHAR(90)
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

IF OBJECT_ID('tempdb..#FuelTicketTemp') IS NOT NULL
	DROP TABLE #FuelTicketTemp

--create a temp table for old and new values
CREATE TABLE #FuelTicketTemp (
	Direction VARCHAR(90) NOT NULL,
    [FuelTicketKey] [INT] IDENTITY(1,1) NOT NULL,
	[historyFuelTicketKey] [INT] NULL,
	[FuelTicketDateStart] [DATE] NOT NULL,
	[FuelTicketDateEnd] [DATE] NOT NULL,
	[FuelTicketContext] [VARCHAR](120) NOT NULL,
	[PricePerkWh] [DECIMAL](7, 3) NOT NULL,
	[FuelTicketCreatedBy] [VARCHAR](90) NOT NULL,
	[FuelTicketCreateDate] [DATETIME2](7) NOT NULL,
	[FuelTicketUpdatedBy] [VARCHAR](90) NULL,
	[FuelTicketUpdatedLast] [DATETIME2](7) NULL,
	[FuelTicketHistoryRankorder] [INT] NULL
	)

-- get the previous values
INSERT INTO #FuelTicketTemp (
	   Direction
	  ,[FuelTicketKey]
      ,[historyFuelTicketKey]
      ,[FuelTicketDateStart]
      ,[FuelTicketDateEnd]
      ,[FuelTicketContext]
      ,[PricePerkWh]
      ,[FuelTicketCreatedBy]
      ,[FuelTicketCreateDate]
      ,[FuelTicketUpdatedBy]
      ,[FuelTicketUpdatedLast]
      ,[FuelTicketHistoryRankorder]
	)
SELECT 'Previous Value'
      ,[FuelTicketKey]
      ,[historyFuelTicketKey]
      ,[FuelTicketDateStart]
      ,[FuelTicketDateEnd]
      ,[FuelTicketContext]
      ,[PricePerkWh]
      ,[FuelTicketCreatedBy]
      ,[FuelTicketCreateDate]
      ,[FuelTicketUpdatedBy]
      ,[FuelTicketUpdatedLast]
      ,[FuelTicketHistoryRankorder]
FROM ftk.FuelTicket
WHERE [historyFuelTicketKey] = 1--  @historyFuelTicketKey
	AND FuelTicketHistoryRankorder = 1
	
SELECT * FROM #FuelTicketTemp

	update ftk.FuelTicket 
	set [FuelTicketHistoryRankorder] = [FuelTicketHistoryRankorder] + 1
	FROM ftk.FuelTicket
	WHERE historyFuelTicketKey = @historyFuelTicketKey
	


	INSERT ftk.FuelTicket (
	  [historyFuelTicketKey]
      ,[FuelTicketDateStart]
      ,[FuelTicketDateEnd]
      ,[FuelTicketContext]
      ,[PricePerkWh]
      ,[FuelTicketCreatedBy]
      ,[FuelTicketCreateDate]
      ,[FuelTicketUpdatedBy]
      ,[FuelTicketUpdatedLast]
      ,[FuelTicketHistoryRankorder]
		)
	select [historyFuelTicketKey] = @FuelTicketKey
	  , [FuelTicketDateStart]
	  , [FuelTicketDateEnd] = @FuelTicketDateStart
	  , [FuelTicketCode] = @FuelTicketDateEnd
      ,[FuelTicketContext] = @FuelTicketContext
      ,[PricePerkWh] = @PricePerkWh
      ,[FuelTicketCreatedBy]
      ,[FuelTicketUpdatedBy] = @ftkUser
      ,[FuelTicketUpdatedLast] = SYSDATETIME()
	  ,0 
	  from #FuelTicketTemp
	
	
	update ftk.FuelTicket 
	set [FuelTicketHistoryRankorder] = [FuelTicketHistoryRankorder] + 1
	WHERE [historyFuelTicketKey] = @historyFuelTicketKey AND [FuelTicketHistoryRankorder] = 0

-- output back to report
SELECT [FuelTicketKey]
      ,[historyFuelTicketKey]
      ,[FuelTicketDateStart]
      ,[FuelTicketDateEnd]
      ,[FuelTicketContext]
      ,[PricePerkWh]
      ,[FuelTicketCreatedBy]
      ,[FuelTicketCreateDate]
      ,[FuelTicketUpdatedBy]
      ,[FuelTicketUpdatedLast]
      ,[FuelTicketHistoryRankorder]
FROM ftk.FuelTicket
WHERE [historyFuelTicketKey] = @FuelTicketKey
and [FuelTicketHistoryRankorder] = 1
END
GO
