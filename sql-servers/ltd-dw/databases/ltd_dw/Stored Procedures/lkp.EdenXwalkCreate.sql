SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create PROCEDURE [lkp].[EdenXwalkCreate] 
@pEdenXwalkCode VARCHAR(32)  NULL
,@pEdenXwalkName VARCHAR(255)  NULL
,@pEdenXwalkTouchPassName VARCHAR(30) NULL
,@pLTDEdenXwalkCode varchar(30) NULL
,@pUserName varchar(90) NULL
AS

DECLARE @OutputTbl TABLE ([Key] INT)
declare @newEdenXwalkKey INT

-- exec lkp.[EdenXwalkCreate] 'TRIP','TRIP', 'CENTENE',NULL, 'Barb Eichberger'
-- truncate table dbo.EdenXwalk


	INSERT lkp.EdenXwalk (
		[EdenXwalkCode]
		,[EdenXwalkName]
		,[EdenXwalkTouchPassName]
		,[LTDEdenXwalkCode]
		,[EdenXwalkCreatedBy]
		,[EdenXwalkHistoryRankorder]
		)
	OUTPUT INSERTED.EdenXwalkKey INTO @OutputTbl([Key])
	SELECT @pEdenXwalkCode
		,@pEdenXwalkName
		,@pEdenXwalkTouchPassName
		,@pLTDEdenXwalkCode
		,@pUserName
		,1 -- [EdenXwalkHistoryRankorder] 
	where @pEdenXwalkCode not in (select [EdenXwalkCode] from [lkp].[EdenXwalk] 
								where EdenXwalkNoLongerActiveDate is null
								and [EdenXwalkCode] = @pEdenXwalkCode
								and [EdenXwalkName] = @pEdenXwalkName
								and EdenXwalkTouchPassName = @pEdenXwalkTouchPassName
								and LTDEdenXwalkCode = @pLTDEdenXwalkCode
								 and [EdenXwalkHistoryRankorder] = 1)
	-- do not allow entering a new EdenXwalk with the same code, desc, group and ltdcode that is currently active
	-- can enter one combo that was deactivated previously

	select @newEdenXwalkKey = (select top 1 [Key] from @OutputTbl)
	UPDATE lkp.EdenXwalk
	SET historyEdenXwalkKey = @newEdenXwalkKey
	WHERE [historyEdenXwalkKey] is null and EdenXwalkKey = @newEdenXwalkKey
	
-- output back to report
SELECT [EdenXwalkKey]
	,[historyEdenXwalkKey]
	,[EdenXwalkCode]
	,[EdenXwalkName]
	,[EdenXwalkTouchPassName]
	,[LTDEdenXwalkCode]
	,[EdenXwalkCreateDate]
	,[EdenXwalkCreatedBy]
	,[EdenXwalkUpdatedLast]
	,[EdenXwalkUpdatedBy]
	,[EdenXwalkNoLongerActiveDate]
	,[EdenXwalkHistoryRankorder] 
FROM lkp.EdenXwalk 
WHERE [EdenXwalkHistoryRankorder] = 1 and EdenXwalkKey = @newEdenXwalkKey
		
		grant execute on [lkp].[EdenXwalkCreate]  to rpt_reader
GO
