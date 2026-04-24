SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   PROCEDURE [ops].[merge_dailyAbsence]
AS
/*-----------LTD_GLOSSARY---------------
 created by	:  b. eichberger
 created dt	:  2024-02-23
 purpose	:  merge ops.absence from ltd-ops.midas.dbo.absence
 use		:  exec ops.merge_dailyAbsence

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

SELECT emp_SID
	  ,division
	  ,opDate
	  ,absCode
	  ,absDateBegin
	  ,absTimeBegin
	  ,codeDateBegin
	  ,paidTime
	  ,workDateBegin
	  ,absPayCode
	  ,premiumTime
	  ,leaveTime
	  ,includeInWorkTime
	  ,detailFlags
	  ,accrualLeaveType
	  ,accrualLeaveYearID
	  ,initialTime INTO #tempAbsenceDaily
FROM [LTD-OPS].midas.dbo.dailyAbsence

MERGE ltd_dw.ops.dailyAbsence AS t
USING #tempAbsenceDaily AS s
ON (t.emp_SID = s.emp_SID
AND t.division = s.division COLLATE SQL_Latin1_General_CP850_CI_AS 
AND t.opDate = s.opDate
AND t.absCode = s.absCode COLLATE SQL_Latin1_General_CP850_CI_AS
AND t.absDateBegin = s.absDateBegin
AND t.absTimeBegin = s.absTimeBegin
AND t.codeDateBegin = s.codeDateBegin
AND t.workDateBegin = s.workDateBegin
AND t.absPayCode = s.absPayCode COLLATE SQL_Latin1_General_CP850_CI_AS
)
WHEN MATCHED AND (
   ISNULL(t.paidTime,0) <> ISNULL(s.paidTime,0)
OR ISNULL(t.premiumTime,0) <> ISNULL(s.premiumTime,0)
OR ISNULL(t.leaveTime,0) <> ISNULL(s.leaveTime,0)
OR ISNULL(t.includeInWorkTime,0) <> ISNULL(s.includeInWorkTime,0)
OR ISNULL(t.detailFlags,0) <> ISNULL(s.detailFlags,0)
OR ISNULL(t.accrualLeaveType,'') <> ISNULL(s.accrualLeaveType COLLATE SQL_Latin1_General_CP850_CI_AS,'')
OR ISNULL(t.accrualLeaveYearID,'') <> ISNULL(s.accrualLeaveYearID COLLATE SQL_Latin1_General_CP850_CI_AS,'')
OR ISNULL(t.initialTime,0) <> ISNULL(s.initialTime,0)) 
THEN UPDATE SET t.paidTime = s.paidTime
	,t.premiumTime = s.premiumTime
	,t.leaveTime = s.leaveTime
	,t.includeInWorkTime = s.includeInWorkTime
	,t.detailFlags = s.detailFlags
	,t.accrualLeaveType = s.accrualLeaveType
	,t.accrualLeaveYearID = s.accrualLeaveYearID
	,t.initialTime = s.initialTime
	,t.record_updated_date = SYSDATETIME()
WHEN NOT MATCHED BY TARGET THEN INSERT (
emp_SID
,division
,opDate
,absCode
,absDateBegin
,absTimeBegin
,codeDateBegin
,paidTime
,workDateBegin
,absPayCode
,premiumTime
,leaveTime
,includeInWorkTime
,detailFlags
,accrualLeaveType
,accrualLeaveYearID
,initialTime
)
VALUES
( s.emp_SID, s.division, s.opDate, s.absCode, s.absDateBegin, s.absTimeBegin, s.codeDateBegin, s.paidTime, s.workDateBegin, s.absPayCode, s.premiumTime, s.leaveTime, s.includeInWorkTime, s.detailFlags, s.accrualLeaveType, s.accrualLeaveYearID, s.initialTime)
WHEN NOT MATCHED BY SOURCE THEN DELETE	
OUTPUT $action INTO @outputTbl;


DECLARE @ins INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'INSERT')
DECLARE @upd INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'UPDATE')
DECLARE @del INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'DELETE')
DECLARE @prg varchar(90) = @@SERVERNAME + '.ltd_dw.ops.merge_dailyAbsence'

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
'ltd_dw.ops.dailyAbsence',
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
