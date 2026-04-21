SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [ops].[z Update_Absence]
AS

BEGIN TRY


set nocount on;
----
DECLARE @SPROC VARCHAR(100)
SET @SPROC = OBJECT_SCHEMA_NAME(@@PROCID) + '.' + OBJECT_NAME(@@PROCID)

UPDATE a
   SET a.[absDateEnd] = b.absDateEnd, 
      a.[absTimeEnd] = b.absTimeEnd, 
      a.[absFlags] = b.absFlags, 
      a.[stampBeginDate] = b.stampBeginDate, 
      a.[stampBeginUser] = b.stampBeginUser, 
      a.[stampEndDate] = b.stampEndDate, 
      a.[stampEndUser] = b.stampEndUser, 
      a.[callBegin] = b.callBegin, 
      a.[callEnd] = b.callEnd, 
      a.[prepayDate] = b.prepayDate, 
      a.[prepayCode] = b.prepayCode, 
      a.[comments] = b.comments, 
      a.[daysEffective] = b.daysEffective, 
      a.[familyFMLA] = b.familyFMLA, 
      a.[personalFMLA] = b.personalFMLA, 
      a.[reviewFMLAStampDate] = b.reviewFMLAStampDate, 
      a.[reviewFMLAStampUser] = b.reviewFMLAStampUser, 
      a.[mailFMLAStampDate] = b.mailFMLAStampDate, 
      a.[mailFMLAStampUser] = b.mailFMLAStampUser, 
      a.[absenceReason] = b.absenceReason, 
      a.[runNumber] = b.runNumber, 
      a.[empRelation] = b.empRelation, 
      a.[runPayOption] = b.runPayOption,
	  a.[record_updated_date] = SYSDATETIME()
FROM [ops].[absence] a
INNER JOIN [ltd-ops].midas.dbo.absence b ON 
					    b.[emp_SID] = a.[emp_SID] 
					AND b.[absCode] COLLATE SQL_Latin1_General_CP850_CI_AS = a.[absCode] COLLATE SQL_Latin1_General_CP850_CI_AS
					AND b.[absDateBegin] = a.[absDateBegin]
					AND b.[absTimeBegin] = a.[absTimeBegin]
 WHERE (a.[absDateEnd] <> b.absDateEnd OR  
      a.[absTimeEnd] <> b.absTimeEnd OR  
      a.[absFlags] <> b.absFlags OR  
      a.[stampBeginDate] <> b.stampBeginDate OR  
      a.[stampBeginUser] COLLATE SQL_Latin1_General_CP850_CI_AS <> b.stampBeginUser COLLATE SQL_Latin1_General_CP850_CI_AS OR  
      a.[stampEndDate] <> b.stampEndDate OR  
      a.[stampEndUser] COLLATE SQL_Latin1_General_CP850_CI_AS <> b.stampEndUser COLLATE SQL_Latin1_General_CP850_CI_AS OR  
      a.[callBegin] <> b.callBegin OR  
      a.[callEnd] <> b.callEnd OR  
      a.[prepayDate] <> b.prepayDate OR  
      a.[prepayCode] COLLATE SQL_Latin1_General_CP850_CI_AS <> b.prepayCode COLLATE SQL_Latin1_General_CP850_CI_AS OR  
      a.[comments] COLLATE SQL_Latin1_General_CP850_CI_AS <> b.comments COLLATE SQL_Latin1_General_CP850_CI_AS OR  
      a.[daysEffective] <> b.daysEffective OR  
      a.[familyFMLA] <> b.familyFMLA OR  
      a.[personalFMLA] <> b.personalFMLA OR  
      a.[reviewFMLAStampDate] <> b.reviewFMLAStampDate OR  
      a.[reviewFMLAStampUser] COLLATE SQL_Latin1_General_CP850_CI_AS <> b.reviewFMLAStampUser COLLATE SQL_Latin1_General_CP850_CI_AS OR  
      a.[mailFMLAStampDate] <> b.mailFMLAStampDate OR  
      a.[mailFMLAStampUser] COLLATE SQL_Latin1_General_CP850_CI_AS <> b.mailFMLAStampUser COLLATE SQL_Latin1_General_CP850_CI_AS OR  
      a.[absenceReason] COLLATE SQL_Latin1_General_CP850_CI_AS <> b.absenceReason COLLATE SQL_Latin1_General_CP850_CI_AS OR  
      a.[runNumber] COLLATE SQL_Latin1_General_CP850_CI_AS <> b.runNumber COLLATE SQL_Latin1_General_CP850_CI_AS OR  
      a.[empRelation] COLLATE SQL_Latin1_General_CP850_CI_AS <> b.empRelation COLLATE SQL_Latin1_General_CP850_CI_AS OR  
      a.[runPayOption] <> b.runPayOption)


	
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
