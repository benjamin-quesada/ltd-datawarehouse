SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create PROCEDURE [ops].[z get_dailyEmployee]
AS

/*---------------LTD_GLOSSARY----------------
CREATED DT:		20231211
CREATED BY	:	B. Eichberger
PURPOSE		:	Merge Operations daily Employee Info to DW
USAGE		:	exec [ops].[get_dailyEmployee]
			    Run Daily

SOURCE		:	midas.dbo.dailyEmployee	
DESTINATION	:	ltd_dw.ops.dailyEmployee				
*/


BEGIN TRY
	SET NOCOUNT ON;

	DECLARE @SPROC VARCHAR(100);
	SET @SPROC = OBJECT_SCHEMA_NAME(@@PROCID) + '.' + OBJECT_NAME(@@PROCID);

;WITH src as (
    select division COLLATE SQL_Latin1_General_CP1_CI_AS division
		  ,opDate
		  ,emp_SID
		  ,workStatus COLLATE SQL_Latin1_General_CP1_CI_AS workStatus
		  ,timeBegin
		  ,timeEnd
		  ,timeWorked
		  ,workWeek COLLATE SQL_Latin1_General_CP1_CI_AS workWeek
		  ,dailyGenFlags
		  ,otherDiv COLLATE SQL_Latin1_General_CP1_CI_AS otherDiv
		  ,noteText COLLATE SQL_Latin1_General_CP1_CI_AS noteText
		  ,dailyWorkFlags
		  ,dailyTKFlags
		  ,OTafterTime
		  ,section15Rate
		  ,timeWorkedSleep
		  ,timeBeginSleep
		  ,timeEndSleep
		  ,actingForEmp_SID
		  ,boardRating
		  ,dailyPayRules COLLATE SQL_Latin1_General_CP1_CI_AS dailyPayRules
		  ,clientFlags
		  ,boardStatus COLLATE SQL_Latin1_General_CP1_CI_AS boardStatus
		  ,weeklyPayRules COLLATE SQL_Latin1_General_CP1_CI_AS weeklyPayRules
		  ,tradeEmp_SID
    from [ltd-ops].[midas].[dbo].[dailyEmployee] WHERE opdate >= DATEADD(DAY, 1,EOMONTH(DATEADD(MONTH,-60,GETDATE())))
)
MERGE ops.dailyEmployee AS tgt
USING src
     ON src.[division] = tgt.[division]
    AND src.[opDate] = tgt.[opDate]
    AND src.[emp_SID] = tgt.[emp_SID]
WHEN MATCHED 
AND (
    tgt.[workStatus] <> src.[workStatus] OR
    tgt.[timeBegin] <> src.[timeBegin] OR
    tgt.[timeEnd] <> src.[timeEnd] OR
    tgt.[timeWorked] <> src.[timeWorked] OR
    tgt.[workWeek] <> src.[workWeek] OR
    tgt.[dailyGenFlags] <> src.[dailyGenFlags] OR
    tgt.[otherDiv] <> src.[otherDiv] OR
    tgt.[noteText] <> src.[noteText] OR
    tgt.[dailyWorkFlags] <> src.[dailyWorkFlags] OR
    tgt.[dailyTKFlags] <> src.[dailyTKFlags] OR
    tgt.[OTafterTime] <> src.[OTafterTime] OR
    tgt.[section15Rate] <> src.[section15Rate] OR
    tgt.[timeWorkedSleep] <> src.[timeWorkedSleep] OR
    tgt.[timeBeginSleep] <> src.[timeBeginSleep] OR
    tgt.[timeEndSleep] <> src.[timeEndSleep] OR
    tgt.[actingForEmp_SID] <> src.[actingForEmp_SID] OR
    tgt.[boardRating] <> src.[boardRating] OR
    tgt.[dailyPayRules] <> src.[dailyPayRules] OR
    tgt.[clientFlags] <> src.[clientFlags] OR
    tgt.[boardStatus] <> src.[boardStatus] OR
    tgt.[weeklyPayRules] <> src.[weeklyPayRules] OR
    tgt.[tradeEmp_SID] <> src.[tradeEmp_SID]
	)
THEN UPDATE SET 
    tgt.[workStatus] = src.[workStatus],
    tgt.[timeBegin] = src.[timeBegin],
    tgt.[timeEnd] = src.[timeEnd],
    tgt.[timeWorked] = src.[timeWorked],
    tgt.[workWeek] = src.[workWeek],
    tgt.[dailyGenFlags] = src.[dailyGenFlags],
    tgt.[otherDiv] = src.[otherDiv],
    tgt.[noteText] = src.[noteText],
    tgt.[dailyWorkFlags] = src.[dailyWorkFlags],
    tgt.[dailyTKFlags] = src.[dailyTKFlags],
    tgt.[OTafterTime] = src.[OTafterTime],
    tgt.[section15Rate] = src.[section15Rate],
    tgt.[timeWorkedSleep] = src.[timeWorkedSleep],
    tgt.[timeBeginSleep] = src.[timeBeginSleep],
    tgt.[timeEndSleep] = src.[timeEndSleep],
    tgt.[actingForEmp_SID] = src.[actingForEmp_SID],
    tgt.[boardRating] = src.[boardRating],
    tgt.[dailyPayRules] = src.[dailyPayRules],
    tgt.[clientFlags] = src.[clientFlags],
    tgt.[boardStatus] = src.[boardStatus],
    tgt.[weeklyPayRules] = src.[weeklyPayRules],
    tgt.[tradeEmp_SID] = src.[tradeEmp_SID],
    tgt.record_updated_date = SYSDATETIME()
WHEN NOT MATCHED THEN INSERT
    (
        [division], 
        [opDate], 
        [emp_SID],  
        [workStatus], 
        [timeBegin], 
        [timeEnd], 
        [timeWorked], 
        [workWeek], 
        [dailyGenFlags], 
        [otherDiv], 
        [noteText], 
        [dailyWorkFlags], 
        [dailyTKFlags], 
        [OTafterTime], 
        [section15Rate], 
        [timeWorkedSleep], 
        [timeBeginSleep], 
        [timeEndSleep], 
        [actingForEmp_SID], 
        [boardRating], 
        [dailyPayRules], 
        [clientFlags], 
        [boardStatus], 
        [weeklyPayRules], 
        [tradeEmp_SID]
    )
    VALUES (
        src.[division], 
        src.[opDate], 
        src.[emp_SID], 
        src.[workStatus], 
        src.[timeBegin], 
        src.[timeEnd], 
        src.[timeWorked], 
        src.[workWeek], 
        src.[dailyGenFlags], 
        src.[otherDiv], 
        src.[noteText], 
        src.[dailyWorkFlags], 
        src.[dailyTKFlags], 
        src.[OTafterTime], 
        src.[section15Rate], 
        src.[timeWorkedSleep], 
        src.[timeBeginSleep], 
        src.[timeEndSleep], 
        src.[actingForEmp_SID], 
        src.[boardRating], 
        src.[dailyPayRules], 
        src.[clientFlags], 
        src.[boardStatus], 
        src.[weeklyPayRules], 
        src.[tradeEmp_SID]
    );

END TRY
BEGIN CATCH

	DECLARE @profile VARCHAR(255) =
			(SELECT [name] FROM msdb.dbo.sysmail_profile) ;
	DECLARE @errormsg VARCHAR(MAX)
		   ,@error INT
		   ,@message VARCHAR(MAX)
		   ,@xstate INT
		   ,@errsev INT
		   ,@sub VARCHAR(255) ;

	SELECT	@error = ERROR_NUMBER()
		   ,@errsev = ERROR_SEVERITY()
		   ,@message = ERROR_MESSAGE()
		   ,@xstate = XACT_STATE() ;

	SELECT	@errormsg = 'Error in ' + ISNULL(@SPROC, '') + ': ' + CAST(ISNULL(@error, '') AS NVARCHAR(32)) + '|' + COALESCE(@message, '') + '|' + CAST(ISNULL(@xstate, '') AS NVARCHAR(32)) + '|' + CAST(ISNULL(@errsev, '') AS NVARCHAR(32)) ;

	SELECT	@sub = 'ERROR: ' + @SPROC ;

	EXEC msdb.dbo.sp_send_dbmail @profile_name = @profile
								,@recipients = 'barb.eichberger@ltd.org'
								,@subject = @sub
								,@body = @errormsg ;

	RAISERROR(@errormsg, @errsev, 1) ;
END CATCH ;
GO
