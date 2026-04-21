SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   PROCEDURE [sbp].[MetricCreate] 
@sbpMETRICNameLabel VARCHAR(90) NULL,
@sbpMETRICNameDataedo VARCHAR(90) NULL,
@sbpMETRICCode VARCHAR(30) NULL,
@sbpMETRICDesc VARCHAR(256) NULL,
@sbpMETRICGroup VARCHAR(30) NULL,
@sbpMETRICDataType VARCHAR(90) NULL,
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
declare @newMetricKey INT

-- exec sbp.[MetricCreate] 'Operating Cost Per Test','Operating Cost Per Test','OCTEST','Test Description Plain Text','Finance','Decimal', 'LTD\Barb Eichberger'

	INSERT sbp.Metric (
	   [sbpMETRICNameDataedo]
      ,[sbpMETRICNameLabel]
      ,[sbpMETRICCode]
      ,[sbpMETRICDesc]
      ,[sbpMETRICGroup]
      ,[sbpMETRICDataType]
      ,[sbpMETRICCreatedBy]
	  ,[sbpMETRICHistoryRankorder]
		)
	OUTPUT INSERTED.[sbpMETRICKey] INTO @OutputTbl([Key])
	SELECT 
		 @sbpMETRICNameDataedo
		,@sbpMETRICNameLabel
		,@sbpMETRICCode
		,@sbpMETRICDesc
		,@sbpMETRICGroup
		,@sbpMETRICDataType
		,@sbpUser
		,1 -- [sbpMETRICHistoryRankorder] 
	where @sbpMetricCode not in (select [sbpMETRICCode] from [sbp].[Metric] 
								where [sbpMETRICNoLongerActiveDate] is null
								and [sbpMETRICCode] = @sbpMETRICCode
								)
	-- do not allow entering a new Metric with the same code, desc, group and ltdcode that is currently active
	-- can enter one combo that was deactivated previously
	-- select * from sbp.Metric delete from sbp.Metric where sbpMetricKey >= 19
	-- truncate table sbp.Metric
	select @newMetricKey = (select top(1) [Key] from @OutputTbl ORDER BY [Key])
	UPDATE sbp.Metric
	SET [historysbpMETRICKey] = @newMetricKey
	WHERE [historysbpMETRICKey] is null and [sbpMETRICKey] = @newMetricKey
	
-- output back to report
SELECT [sbpMetricKey]
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
WHERE [sbpMETRICHistoryRankorder] = 1 AND sbpMetricKey = @newMetricKey
		
END
GO
