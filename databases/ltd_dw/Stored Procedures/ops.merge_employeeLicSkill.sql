SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE   PROCEDURE [ops].[merge_employeeLicSkill]
AS
/*-----------LTD_GLOSSARY---------------
 created by	:  b. eichberger
 created dt	:  2024-02-26
 purpose	:  merge ops.employeeLicSkill from ltd-ops.midas.dbo.code
 use		:  exec ops.merge_employeeLicSkill

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

SELECT recType
	  ,emp_SID
	  ,code
	  ,date1
	  ,[sequence]
	  ,date2
	  ,comments
	  ,stampDate
	  ,stampUser
	  ,text1
	  ,text2
	  ,lastDateWorked
	  ,qualifPayCode
	  ,qualifPayTime
	  ,qualifMode
	  ,createdProcCode
	  ,instructor
	  ,clientFlags INTO #els FROM [LTD-OPS].midas.[dbo].[employeeLicSkill] 

MERGE [ops].[employeeLicSkill] AS t
USING #els AS s
ON (t.recType = s.recType COLLATE SQL_Latin1_General_CP850_CI_AS
AND t.emp_SID = s.emp_SID
AND t.code = s.code COLLATE SQL_Latin1_General_CP850_CI_AS
AND t.date1 = s.date1
AND t.[sequence] = s.[sequence]
)
WHEN MATCHED AND (
   ISNULL(t.date2, '1/1/1900') <> ISNULL(s.date2, '1/1/1900')
OR ISNULL(t.comments, '') <> ISNULL(s.comments COLLATE SQL_Latin1_General_CP850_CI_AS, '')
OR ISNULL(t.stampDate, '1/1/1900') <> ISNULL(s.stampDate, '1/1/1900')
OR ISNULL(t.stampUser, '') <> ISNULL(s.stampUser COLLATE SQL_Latin1_General_CP850_CI_AS, '')
OR ISNULL(t.text1, '') <> ISNULL(s.text1 COLLATE SQL_Latin1_General_CP850_CI_AS, '')
OR ISNULL(t.text2, '') <> ISNULL(s.text2 COLLATE SQL_Latin1_General_CP850_CI_AS, '')
OR ISNULL(t.lastDateWorked, '1/1/1900') <> ISNULL(s.lastDateWorked, '1/1/1900')
OR ISNULL(t.qualifPayCode, '') <> ISNULL(s.qualifPayCode COLLATE SQL_Latin1_General_CP850_CI_AS, '')
OR ISNULL(t.qualifPayTime, 0) <> ISNULL(s.qualifPayTime, 0)
OR ISNULL(t.qualifMode, '') <> ISNULL(s.qualifMode COLLATE SQL_Latin1_General_CP850_CI_AS, '')
OR ISNULL(t.createdProcCode, '') <> ISNULL(s.createdProcCode COLLATE SQL_Latin1_General_CP850_CI_AS, '')
OR ISNULL(t.instructor, '') <> ISNULL(s.instructor COLLATE SQL_Latin1_General_CP850_CI_AS, '')
OR ISNULL(t.clientFlags, 0) <> ISNULL(s.clientFlags, 0))
THEN UPDATE SET t.recType = s.recType
	,t.emp_SID = s.emp_SID
	,t.code = s.code
	,t.date1 = s.date1
	,t.sequence = s.sequence
	,t.date2 = s.date2
	,t.comments = s.comments
	,t.stampDate = s.stampDate
	,t.stampUser = s.stampUser
	,t.text1 = s.text1
	,t.text2 = s.text2
	,t.lastDateWorked = s.lastDateWorked
	,t.qualifPayCode = s.qualifPayCode
	,t.qualifPayTime = s.qualifPayTime
	,t.qualifMode = s.qualifMode
	,t.createdProcCode = s.createdProcCode
	,t.instructor = s.instructor
	,t.clientFlags = s.clientFlags
	,t.record_updated_date = SYSDATETIME()
WHEN NOT MATCHED BY TARGET
THEN INSERT (
		 recType
		,emp_SID
		,code
		,date1
		,sequence
		,date2
		,comments
		,stampDate
		,stampUser
		,text1
		,text2
		,lastDateWorked
		,qualifPayCode
		,qualifPayTime
		,qualifMode
		,createdProcCode
		,instructor
		,clientFlags
	 )
	 VALUES
	 ( s.recType, s.emp_SID, s.code, s.date1, s.sequence, s.date2, s.comments, s.stampDate, s.stampUser, s.text1, s.text2, s.lastDateWorked, s.qualifPayCode, s.qualifPayTime, s.qualifMode, s.createdProcCode, s.instructor, s.clientFlags)
WHEN NOT MATCHED BY SOURCE
THEN DELETE
OUTPUT $action INTO @outputTbl;



DECLARE @ins INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'INSERT')
DECLARE @upd INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'UPDATE')
DECLARE @del INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'DELETE')
DECLARE @prg varchar(90) = @@SERVERNAME + '.ltd_dw.ops.merge_employeeLicSkill'

INSERT PROCESS.mergeLogs
(		[MergeCode]
           ,[ObjectDestination]
           ,[ObjectSource]
           ,[ObjectProgram]
           ,[recInsert]
           ,[recUpdate]
           ,[recDelete]
           ,[MergeBeginDatetime]
           ,[MergeEndDatetime])
SELECT 'OPSEL',
'ltd_dw.ops.employeeLicSkill',
'MIDAS',
@prg,
ISNULL(@ins,0) ,ISNULL(@upd,0),ISNULL(@del,0),
@sdt,
SYSDATETIME()



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
