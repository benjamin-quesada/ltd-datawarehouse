SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   PROCEDURE [sbp].[MetricGoalCreate] 
-- grant execute on [sbp].[MetricGoalCreate] to rpt_reader
	@sbphistoryMetricKey INT NULL ,
	@sbpMETRICGoal VARCHAR(90) NULL,
	@sbpMETRICGoalContext VARCHAR(256) NULL,
	@sbpMETRICGoalEffectiveDate DATE NULL,
	@sbpMETRICGoalExpireDate DATE NULL,
	@sbpUser VARCHAR(90)
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



DECLARE @OutputTbl TABLE ([Key] INT)
declare @newMetricGoalKey INT

-- exec sbp.[MetricGoalCreate] 1,35,'gdra aseaeae dfaefa sedfasef aefaef.','7/1/2021',NULL, 'LTD\Barb Eichberger'


	INSERT sbp.MetricGoal (
	   [historysbpMetricKey]
      ,[sbpMETRICGoal]
      ,[sbpMETRICGoalContext]
      ,[sbpMETRICGoalEffectiveDate]
	  ,[sbpMETRICGoalExpireDate]
      ,[sbpMETRICGoalCreatedBy]
      ,[sbpMETRICGoalHistoryRankorder])
	OUTPUT INSERTED.[sbpMetricGoalKey] INTO @OutputTbl([Key])
	  SELECT 
		 @sbphistoryMetricKey
		,@sbpMETRICGoal
		,@sbpMETRICGoalContext
		,@sbpMETRICGoalEffectiveDate
	    ,@sbpMETRICGoalExpireDate
		,@sbpUser
		,1 -- [sbpMETRICHistoryRankorder] 
	where @sbphistoryMetricKey not in (select 1 from [sbp].[MetricGoal] 
								where (sbpMETRICGoalExpireDate is NULL OR sbpMETRICGoalExpireDate > GETDATE())
                                AND [historysbpMetricKey] = @sbphistoryMetricKey
								AND historysbpMETRICGoalKey = (select top(1) [Key] from @OutputTbl ORDER BY [Key])
								)
	-- above--^  do not allow entering a new Metric Goal with the same name and dates and that is currently active
	-- can enter one combo that was deactivated previously
	-- select * from sbp.Metric delete from sbp.Metric where sbpMetricGoalKey >= 19
	-- truncate table sbp.MetricGoal

	select @newMetricGoalKey = (select top(1) [Key] from @OutputTbl ORDER BY [Key])

	UPDATE sbp.MetricGoal
	SET [historysbpMetricGoalKey] = @newMetricGoalKey
	WHERE [historysbpMetricGoalKey] is null and [sbpMetricGoalKey] = @newMetricGoalKey

	UPDATE sbp.MetricGoal
	SET [sbpMETRICGoalExpireDate] = DATEADD(DAY,-1,@sbpMETRICGoalEffectiveDate) 
	WHERE [historysbpMetricKey] = @sbphistoryMetricKey
	AND historysbpMETRICGoalKey < @newMetricGoalKey



	
-- output back to report
SELECT g.[sbpMETRICGoalKey]
      ,g.[historysbpMETRICGoalKey]
      ,g.[historysbpMetricKey]
	  ,m.sbpMETRICNameDataedo
	  ,m.sbpMETRICNameLabel
	  ,m.sbpMETRICCode
      ,g.[sbpMETRICGoal]
      ,g.[sbpMETRICGoalContext]
      ,g.[sbpMETRICGoalEffectiveDate]
      ,g.[sbpMETRICGoalExpireDate]
      ,g.[sbpMETRICGoalCreateDate]
      ,g.[sbpMETRICGoalCreatedBy]
      ,g.[sbpMETRICGoalUpdatedLast]
      ,g.[sbpMETRICGoalUpdatedBy]
      ,g.[sbpMETRICGoalHistoryRankorder]
FROM sbp.MetricGoal g
LEFT JOIN sbp.METRIC m ON m.[historysbpMetricKey] = g.[historysbpMetricKey]
WHERE g.[sbpMETRICGoalHistoryRankorder] = 1 
AND g.sbpMetricGoalKey = @newMetricGoalKey
AND m.sbpMETRICHistoryRankorder = 1
		
END
GO
