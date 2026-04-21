SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [ops].[z Get_Absence]
AS

BEGIN TRY


set nocount on;
----
DECLARE @SPROC VARCHAR(100)
SET @SPROC = OBJECT_SCHEMA_NAME(@@PROCID) + '.' + OBJECT_NAME(@@PROCID)

SELECT [emp_SID] ,[absCode] COLLATE SQL_Latin1_General_CP850_CI_AS [absCode]
		,[absDateBegin],[absTimeBegin] 
INTO #deleteAbsenceData
FROM [ltd-ops].midas.dbo.absence WITH (NOLOCK)


DELETE a 
-- select * 
FROM [ltd_dw].[ops].[Absence] a
	FULL OUTER JOIN #deleteAbsenceData b ON
	 b.[emp_SID] = a.[emp_SID]
	AND b.[absCode] COLLATE SQL_Latin1_General_CP850_CI_AS = a.[absCode] COLLATE SQL_Latin1_General_CP850_CI_AS
	AND b.[absDateBegin] = a.[absDateBegin]
	AND b.[absTimeBegin] = a.[absTimeBegin]
WHERE b.emp_SID IS NULL


INSERT INTO [ops].[Absence]
           ([emp_SID]
           ,[absCode]
           ,[absDateBegin]
           ,[absTimeBegin]
           ,[absDateEnd]
           ,[absTimeEnd]
           ,[absFlags]
           ,[stampBeginDate]
           ,[stampBeginUser]
           ,[stampEndDate]
           ,[stampEndUser]
           ,[callBegin]
           ,[callEnd]
           ,[prepayDate]
           ,[prepayCode]
           ,[comments]
           ,[daysEffective]
           ,[familyFMLA]
           ,[personalFMLA]
           ,[reviewFMLAStampDate]
           ,[reviewFMLAStampUser]
           ,[mailFMLAStampDate]
           ,[mailFMLAStampUser]
           ,[absenceReason]
           ,[runNumber]
           ,[empRelation]
           ,[runPayOption])
 SELECT 
 [emp_SID]
,[absCode] COLLATE SQL_Latin1_General_CP850_CI_AS
,[absDateBegin]
,[absTimeBegin]
,[absDateEnd]
,[absTimeEnd]
,[absFlags]
,[stampBeginDate]
,[stampBeginUser] COLLATE SQL_Latin1_General_CP850_CI_AS
,[stampEndDate]
,[stampEndUser] COLLATE SQL_Latin1_General_CP850_CI_AS
,[callBegin]
,[callEnd]
,[prepayDate]
,[prepayCode] COLLATE SQL_Latin1_General_CP850_CI_AS
,[comments] COLLATE SQL_Latin1_General_CP850_CI_AS
,[daysEffective]
,[familyFMLA]
,[personalFMLA]
,[reviewFMLAStampDate]
,[reviewFMLAStampUser] COLLATE SQL_Latin1_General_CP850_CI_AS
,[mailFMLAStampDate]
,[mailFMLAStampUser] COLLATE SQL_Latin1_General_CP850_CI_AS
,[absenceReason] COLLATE SQL_Latin1_General_CP850_CI_AS
,[runNumber] COLLATE SQL_Latin1_General_CP850_CI_AS
,[empRelation] COLLATE SQL_Latin1_General_CP850_CI_AS
,[runPayOption] 
FROM [ltd-ops].midas.dbo.absence a WITH (NOLOCK)
WHERE NOT EXISTS (SELECT 1 FROM ops.Absence WHERE 
					[emp_SID] = a.[emp_SID]
					AND [absCode] COLLATE SQL_Latin1_General_CP850_CI_AS = a.[absCode] COLLATE SQL_Latin1_General_CP850_CI_AS
					AND [absDateBegin] = a.[absDateBegin]
					AND [absTimeBegin] = a.[absTimeBegin])


	
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
             ,@recipients = 'barb.eichberger@ltd.org'--;servicedesk@ltd.org' 
             ,@subject = @sub
             ,@body = @errormsg;

       RAISERROR (
                    @errormsg
                    ,@errsev
                    ,1
                    )
END CATCH
GO
