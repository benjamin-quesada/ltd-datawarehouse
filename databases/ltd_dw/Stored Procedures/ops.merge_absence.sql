SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   PROCEDURE [ops].[merge_absence]
AS
/*-----------LTD_GLOSSARY---------------
 created by	:  b. eichberger
 created dt	:  2024-02-23
 purpose	:  merge ops.absence from ltd-ops.midas.dbo.absence
 use		:  exec ops.merge_absence

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

BEGIN TRY

DECLARE @sdt DATETIME2 = SYSDATETIME()
DECLARE @outputTbl TABLE (actionNm VARCHAR(32));
DECLARE @fdt DATETIME = (SELECT CAST('1900-01-01 00:00' as SMALLDATETIME))

MERGE ltd_dw.ops.absence AS t
USING [LTD-OPS].midas.dbo.absence AS s
ON ( t.emp_SID = s.emp_SID 
AND t.absCode = s.absCode COLLATE SQL_Latin1_General_CP850_CI_AS
AND t.absDateBegin = s.absDateBegin 
AND t.absTimeBegin = s.absTimeBegin )
WHEN MATCHED AND
(
ISNULL(t.absFlags,0) <> ISNULL(s.absFlags,0) 
OR ISNULL(t.absDateEnd,@fdt) <> ISNULL(s.absDateEnd ,cast('1900-01-01 00:00' as SMALLDATETIME))
OR ISNULL(t.absTimeEnd,0) <> ISNULL(s.absTimeEnd ,0)
OR ISNULL(t.stampBeginDate,@fdt) <> ISNULL(s.stampBeginDate,cast('1900-01-01 00:00' as SMALLDATETIME))
OR ISNULL(t.stampBeginUser,'') <> ISNULL(s.stampBeginUser COLLATE SQL_Latin1_General_CP850_CI_AS,'' )
OR ISNULL(t.stampEndDate,@fdt) <> ISNULL(s.stampEndDate,cast('1900-01-01 00:00' as SMALLDATETIME))
OR ISNULL(t.stampEndUser,'') <> ISNULL(s.stampEndUser COLLATE SQL_Latin1_General_CP850_CI_AS,'' )
OR ISNULL(t.callBegin,@fdt) <> ISNULL(s.callBegin,cast('1900-01-01 00:00' as SMALLDATETIME))
OR ISNULL(t.callEnd,@fdt) <> ISNULL(s.callEnd,cast('1900-01-01 00:00' as SMALLDATETIME))
OR ISNULL(t.prepayDate,@fdt) <> ISNULL(s.prepayDate,cast('1900-01-01 00:00' as SMALLDATETIME))
OR ISNULL(t.prepayCode,'') <> ISNULL(s.prepayCode COLLATE SQL_Latin1_General_CP850_CI_AS,'' )
OR ISNULL(t.comments,'') <> ISNULL(s.comments COLLATE SQL_Latin1_General_CP850_CI_AS,'' )
OR ISNULL(t.daysEffective,0) <> ISNULL(s.daysEffective ,0)
OR ISNULL(t.familyFMLA,0) <> ISNULL(s.familyFMLA ,0)
OR ISNULL(t.personalFMLA,0) <> ISNULL(s.personalFMLA,0)
OR ISNULL(t.reviewFMLAStampDate,@fdt) <> ISNULL(s.reviewFMLAStampDate,cast('1900-01-01' as datetime)) 
OR ISNULL(t.reviewFMLAStampUser,'') <> ISNULL(s.reviewFMLAStampUser COLLATE SQL_Latin1_General_CP850_CI_AS,'' )
OR ISNULL(t.mailFMLAStampDate,@fdt) <> ISNULL(s.mailFMLAStampDate,cast('1900-01-01' as datetime)) 
OR ISNULL(t.mailFMLAStampUser,'') <> ISNULL(s.mailFMLAStampUser COLLATE SQL_Latin1_General_CP850_CI_AS,'' )
OR ISNULL(t.absenceReason,'') <> ISNULL(s.absenceReason COLLATE SQL_Latin1_General_CP850_CI_AS,'' )
OR ISNULL(t.runNumber,'') <> ISNULL(s.runNumber COLLATE SQL_Latin1_General_CP850_CI_AS,'' )
OR ISNULL(t.empRelation,'') <> ISNULL(s.empRelation COLLATE SQL_Latin1_General_CP850_CI_AS,'' )
OR ISNULL(t.runPayOption,0) <> ISNULL(s.runPayOption,0)  )
THEN UPDATE SET 
t.absDateEnd = s.absDateEnd
,t.absTimeEnd = s.absTimeEnd
,t.absFlags = s.absFlags
	,t.stampBeginDate = s.stampBeginDate
	,t.stampBeginUser = s.stampBeginUser
	,t.stampEndDate = s.stampEndDate
	,t.stampEndUser = s.stampEndUser
	,t.callBegin = s.callBegin
	,t.callEnd = s.callEnd
	,t.prepayDate = s.prepayDate
	,t.prepayCode = s.prepayCode
	,t.comments = s.comments
	,t.daysEffective = s.daysEffective
	,t.familyFMLA = s.familyFMLA
	,t.personalFMLA = s.personalFMLA
	,t.reviewFMLAStampDate = s.reviewFMLAStampDate
	,t.reviewFMLAStampUser = s.reviewFMLAStampUser
	,t.mailFMLAStampDate = s.mailFMLAStampDate
	,t.mailFMLAStampUser = s.mailFMLAStampUser
	,t.absenceReason = s.absenceReason
	,t.runNumber = s.runNumber
	,t.empRelation = s.empRelation
	,t.runPayOption = s.runPayOption
	,t.record_updated_date = SYSDATETIME()
WHEN NOT MATCHED BY TARGET THEN INSERT (
emp_SID
,absCode
,absDateBegin
,absTimeBegin
,absDateEnd
,absTimeEnd
,absFlags
,stampBeginDate
,stampBeginUser
,stampEndDate
,stampEndUser
,callBegin
,callEnd
,prepayDate
,prepayCode
,comments
,daysEffective
,familyFMLA
,personalFMLA
,reviewFMLAStampDate
,reviewFMLAStampUser
,mailFMLAStampDate
,mailFMLAStampUser
,absenceReason
,runNumber
,empRelation
,runPayOption
)
VALUES
(s.emp_SID
,s.absCode
,s.absDateBegin
,s.absTimeBegin
,s.absDateEnd
,s.absTimeEnd
,s.absFlags
,s.stampBeginDate
,s.stampBeginUser
,s.stampEndDate
,s.stampEndUser
,s.callBegin
,s.callEnd
,s.prepayDate
,s.prepayCode
,s.comments
,s.daysEffective
,s.familyFMLA
,s.personalFMLA
,s.reviewFMLAStampDate
,s.reviewFMLAStampUser
,s.mailFMLAStampDate
,s.mailFMLAStampUser
,s.absenceReason
,s.runNumber
,s.empRelation
,s.runPayOption)
WHEN NOT MATCHED BY SOURCE THEN DELETE	
OUTPUT $action INTO @outputTbl;


DECLARE @ins INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'INSERT')
DECLARE @upd INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'UPDATE')
DECLARE @del INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'DELETE')
DECLARE @prg VARCHAR(90) = @@SERVERNAME + '.ltd_dw.ops.merge_absence'

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
'ltd_dw.ops.absence',
'MIDAS',
@prg,
isnull(@ins,0) ,ISNULL(@upd,0),ISNULL(@del,0),
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

       EXEC msdb.dbo.sp_send_dbmail @profile_name = @profile
             ,@recipients = 'barb.eichberger@ltd.org' 
             ,@subject = @sub
             ,@body = @errormsg;

       RAISERROR (
                    @errormsg
                    ,@errsev
                    ,1
                    )
END CATCH
GO
