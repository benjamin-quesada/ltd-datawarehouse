SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [ops].[z merge_Operator_Absence]
AS
/*-----------LTD_GLOSSARY---------------
 created by	:  b. eichberger
 created dt	:  2024-03-11
 purpose	:  merge ops.Operator_Absence reporting source from ltd-dw 
			:  needs rework to accomplish type II changes
 use		:  exec ops.merge_Operator_Absence
			   for Operator Absence Report
			   http://ltd-test-bi/reports/report/Transit%20Operations/Operations%20Absences%20-%20Printable
 
*/
SET NOCOUNT ON;

  DECLARE @SPROC VARCHAR(100)
  SET @SPROC = OBJECT_SCHEMA_NAME(@@PROCID) + '.' + OBJECT_NAME(@@PROCID)


BEGIN TRY
DECLARE @sdt DATETIME2 = SYSDATETIME()
DECLARE @outputTbl TABLE (actionNm VARCHAR(32));

MERGE [ops].[Operator_Absence] AS t
USING [ops].[operator_absence_v] AS s
ON (t.badge = s.badge
AND t.absCode = s.absCode COLLATE SQL_Latin1_General_CP850_CI_AS
AND t.absDateBegin = s.absDateBegin 
AND t.absTimeBegin = s.absTimeBegin 
AND t.absPayCode = s.absPayCode
AND t.sup_initial = s.sup_initial COLLATE SQL_Latin1_General_CP850_CI_AS
AND t.opdate = s.opdate
)
WHEN MATCHED AND (t.operator <> ISNULL(s.operator,'')
OR t.current_status_pds <> ISNULL(s.current_status_pds,'')
OR t.current_status <> ISNULL(s.current_status,'') COLLATE SQL_Latin1_General_CP850_CI_AS
OR t.supervisor <> ISNULL(s.supervisor,'')
OR t.[absdateend] <> ISNULL(s.[absdateend],'')
OR t.sup_name <> ISNULL(s.sup_name,'')
OR t.abscode_absence_or_late <> ISNULL(s.abscode_absence_or_late,'')
OR t.absencereason <> ISNULL(s.absencereason,'')
OR t.comments <> ISNULL(s.comments,'')
OR t.formatOpDt <> ISNULL(s.formatOpDt,'')
OR t.paidtime <> ISNULL(s.paidtime,''))
THEN UPDATE SET t.operator = s.operator
		,t.current_status_pds = s.current_status_pds
		,t.current_status = s.current_status
		,t.sup_name = s.sup_name
		,t.supervisor = s.supervisor
		,t.absdateend = s.absdateend
		,t.abscode_absence_or_late = s.abscode_absence_or_late
		,t.absencereason = s.absencereason
		,t.comments = s.comments
		,t.opdate = s.opdate
		,t.formatOpDt = s.formatOpDt
		,t.paidtime = s.paidtime
		,t.record_updated_date = SYSDATETIME()
WHEN NOT MATCHED BY TARGET THEN INSERT (
operator
,badge
,current_status_pds
,current_status
,sup_name
,sup_initial
,supervisor
,absdatebegin
,abstimebegin
,absdateend
,abscode
,abscode_absence_or_late
,absencereason
,comments
,opdate
,formatOpDt
,abspaycode
,paidtime
)
VALUES
(s.operator, s.badge, s.current_status_pds, s.current_status, s.sup_name, s.sup_initial, s.supervisor, s.absdatebegin, s.abstimebegin, s.absdateend, s.abscode, s.abscode_absence_or_late, s.absencereason, s.comments, s.opdate, s.formatOpDt, s.abspaycode, s.paidtime)
WHEN NOT MATCHED BY SOURCE THEN DELETE
OUTPUT $action INTO @outputTbl;


DECLARE @ins INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'INSERT')
DECLARE @upd INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'UPDATE')
DECLARE @del INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'DELETE')
DECLARE @prg varchar(90) = @@SERVERNAME + '.ltd_dw.ops.merge_Operator_Absence'

insert process.mergeLogs
(		[MergeCode]
           ,[ObjectDestination]
           ,[ObjectSource]
           ,[ObjectProgram]
           ,[recInsert]
           ,[recUpdate]
           ,[recDelete]
           ,[MergeBeginDatetime]
           ,[MergeEndDatetime])
select 'OPSA',
'ltd_dw.ops.Operator_Absence',
'MIDAS',
@prg,
isnull(@ins,0) ,ISNULL(@upd,0),ISNULL(@upd,0),
@sdt,
sysdatetime()



END TRY	  

BEGIN CATCH

       DECLARE @profile VARCHAR(255) = (
                    SELECT [NAME]
                    FROM msdb.dbo.sysmail_profile
                    )
       DECLARE @errormsg VARCHAR(MAX)
             ,@error INT
             ,@message VARCHAR(MAX)
             ,@xstate INT
             ,@errsev INT
             ,@sub VARCHAR(255);

       SELECT @error = ERROR_NUMBER()
             ,@errsev = ERROR_SEVERITY()
             ,@message = ERROR_MESSAGE()
             ,@xstate = XACT_STATE();

       SELECT @errormsg = 'Error in ' + ISNULL(@SPROC, '') + ': ' + CAST(ISNULL(@error, '') AS NVARCHAR(32)) + '|' + COALESCE(@message, '') + '|' + CAST(ISNULL(@xstate, '') AS NVARCHAR(32)) + '|' +CAST(ISNULL(@errsev, '') AS NVARCHAR(32))

       SELECT @sub = 'ERROR: ' + @SPROC

       --EXEC msdb.dbo.sp_send_dbmail @profile_name = @profile
       --      ,@recipients = 'barb.eichberger@ltd.org' 
       --      ,@subject = @sub
       --      ,@body = @errormsg;

       RAISERROR (
                    @errormsg
                    ,@errsev
                    ,1
                    )
END CATCH

GO
