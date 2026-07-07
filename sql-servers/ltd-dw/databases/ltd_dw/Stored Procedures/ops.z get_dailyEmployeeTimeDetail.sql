SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [ops].[z get_dailyEmployeeTimeDetail]
AS

/*---------------LTD_GLOSSARY----------------
CREATED DT:		20231211
CREATED BY	:	B. Eichberger
PURPOSE		:	Merge Operations Time Details to DW
USAGE		:	exec [ops].[get_dailyEmployeeTimeDetail]
			    Run Daily

SOURCE		:	midas.dbo.dailyEmployeeTimeDetail	
DESTINATION	:	ops.dailyEmployeeTimeDetail				
*/


BEGIN TRY
	SET NOCOUNT ON;

	DECLARE @SPROC VARCHAR(100);
	SET @SPROC = OBJECT_SCHEMA_NAME(@@PROCID) + '.' + OBJECT_NAME(@@PROCID);

;WITH src
AS (SELECT opDate 
		  ,division COLLATE SQL_Latin1_General_CP1_CI_AS division
		  ,emp_SID
		  ,detailSequence
		  ,paySource COLLATE SQL_Latin1_General_CP1_CI_AS paySource
		  ,payType COLLATE SQL_Latin1_General_CP1_CI_AS payType
		  ,payDate
		  ,workDivision COLLATE SQL_Latin1_General_CP1_CI_AS workDivision
		  ,runNumber COLLATE SQL_Latin1_General_CP1_CI_AS runNumber
		  ,blockRoute COLLATE SQL_Latin1_General_CP1_CI_AS blockRoute
		  ,blockID  COLLATE SQL_Latin1_General_CP1_CI_AS blockID
		  ,workClass COLLATE SQL_Latin1_General_CP1_CI_AS workClass
		  ,keyTime
		  ,originalTime
		  ,paidTime
		  ,calcTime
		  ,timeAtStraight
		  ,timeAtOT
		  ,dailyTKDetailFlags
		  ,workAccount COLLATE SQL_Latin1_General_CP1_CI_AS workAccount
		  ,recType COLLATE SQL_Latin1_General_CP1_CI_AS recType
		  ,userID COLLATE SQL_Latin1_General_CP1_CI_AS userID
		  ,userTime
		  ,comment COLLATE SQL_Latin1_General_CP1_CI_AS comment
		  FROM [LTD-OPS].midas.dbo.dailyEmployeeTimeDetail 
	WHERE opdate >= DATEADD(DAY, 1,EOMONTH(DATEADD(MONTH,-2,GETDATE())))
	)
MERGE ops.dailyEmployeeTimeDetail AS tgt
USING src
ON src.[opDate] = tgt.[opDate]
   AND	src.[division]  COLLATE SQL_Latin1_General_CP1_CI_AS = tgt.[division]
   AND	src.[workDivision]  COLLATE SQL_Latin1_General_CP1_CI_AS = tgt.[workDivision]
   AND	src.[runNumber]  COLLATE SQL_Latin1_General_CP1_CI_AS = tgt.[runNumber]
   AND	src.[blockID]  COLLATE SQL_Latin1_General_CP1_CI_AS = tgt.[blockID]
   AND	src.[blockRoute]  COLLATE SQL_Latin1_General_CP1_CI_AS = tgt.[blockRoute]
   AND	src.[workClass]  COLLATE SQL_Latin1_General_CP1_CI_AS = tgt.[workClass]
   AND	src.[emp_SID] = tgt.[emp_SID]
   AND	src.[detailSequence] = tgt.[detailSequence]
WHEN MATCHED AND (
	tgt.[paySource] <> src.[paySource]
	OR tgt.[payType] <> src.[payType]
	OR tgt.[payDate] <> src.[payDate]
	OR tgt.[keyTime] <> src.[keyTime]
	OR tgt.[originalTime] <> src.[originalTime]
	OR tgt.[paidTime] <> src.[paidTime]
	OR tgt.[calcTime] <> src.[calcTime]
	OR tgt.[timeAtStraight] <> src.[timeAtStraight]
	OR tgt.[timeAtOT] <> src.[timeAtOT]
	OR tgt.[dailyTKDetailFlags] <> src.[dailyTKDetailFlags]
	OR tgt.[workAccount] <> src.[workAccount]
	OR tgt.[recType] <> src.[recType]
	OR tgt.[userID] <> src.[userID]
	OR tgt.[userTime] <> src.[userTime]
	OR tgt.[comment] <> src.[comment]
) THEN UPDATE SET tgt.[paySource] = src.[paySource]
	,tgt.[payType] = src.[payType]
	,tgt.[payDate] = src.[payDate]
	,tgt.[keyTime] = src.[keyTime]
	,tgt.[originalTime] = src.[originalTime]
	,tgt.[paidTime] = src.[paidTime]
	,tgt.[calcTime] = src.[calcTime]
	,tgt.[timeAtStraight] = src.[timeAtStraight]
	,tgt.[timeAtOT] = src.[timeAtOT]
	,tgt.[dailyTKDetailFlags] = src.[dailyTKDetailFlags]
	,tgt.[workAccount] = src.[workAccount]
	,tgt.[recType] = src.[recType]
	,tgt.[userID] = src.[userID]
	,tgt.[userTime] = src.[userTime]
	,tgt.[comment] = src.[comment]
	,tgt.[record_updated_date] = SYSDATETIME()
WHEN NOT MATCHED THEN INSERT (
[opDate]
,[opDateINT]
,[division]
,[workDivision]
,[runNumber]
,[blockID]
,[blockRoute]
,[workClass]
,[emp_SID]
,[detailSequence]
,[paySource]
,[payType]
,[payDate]
,[keyTime]
,[originalTime]
,[paidTime]
,[calcTime]
,[timeAtStraight]
,[timeAtOT]
,[dailyTKDetailFlags]
,[workAccount]
,[recType]
,[userID]
,[userTime]
,[comment]
)
VALUES
(src.[opDate],
[dbo].[F_DATE_TO_CALENDAR_ID](src.[opDate]),
src.[division], src.[workDivision], src.[runNumber], src.[blockID], src.[blockRoute], src.[workClass], src.[emp_SID], src.[detailSequence], src.[paySource], src.[payType], src.[payDate], src.[keyTime], src.[originalTime], src.[paidTime], src.[calcTime], src.[timeAtStraight], src.[timeAtOT], src.[dailyTKDetailFlags], src.[workAccount], src.[recType], src.[userID], src.[userTime], src.[comment]);



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
