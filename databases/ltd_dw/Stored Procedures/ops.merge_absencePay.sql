SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   PROCEDURE [ops].[merge_absencePay]
AS
/*-----------LTD_GLOSSARY---------------
 created by	:  b. eichberger
 created dt	:  2024-02-23
 purpose	:  merge ops.absencePay from ltd-ops.midas.dbo.absencePay
 use		:  exec [ops].[merge_absencePay]

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

SELECT * INTO #absOps FROM [LTD-OPS].midas.dbo.absencePay WITH (NOLOCK)

MERGE ltd_dw.ops.absencePay AS t
USING #absOps AS s
ON (
t.emp_SID = s.emp_SID
AND t.absCode = s.absCode COLLATE SQL_Latin1_General_CP850_CI_AS
AND t.absDateBegin = s.absDateBegin
AND t.[absTimeBegin] = s.[absTimeBegin]
AND t.codeDateBegin = s.codeDateBegin
AND t.absPayCode = s.absPayCode COLLATE SQL_Latin1_General_CP850_CI_AS
)
WHEN MATCHED AND 
( ISNULL(t.codeDateEnd,'1900-01-01') <> ISNULL(s.codeDateEnd,'1900-01-01')
OR ISNULL(t.stampCodeDate,'1900-01-01') <> ISNULL(s.stampCodeDate,'1900-01-01')
OR ISNULL(t.stampCodeUser,'') <> ISNULL(s.stampCodeUser COLLATE SQL_Latin1_General_CP850_CI_AS,'')
OR ISNULL(t.absPayDivision,'') <> ISNULL(s.absPayDivision COLLATE SQL_Latin1_General_CP850_CI_AS,'')
OR ISNULL(t.absPayFlags,0) <> ISNULL(s.absPayFlags,0)
OR ISNULL(t.absPayTime,0) <> ISNULL(s.absPayTime,0)
OR ISNULL(t.absPayAmount,0) <> ISNULL(s.absPayAmount,0)
OR ISNULL(t.stampNoPayDate,'1900-01-01') <> ISNULL(s.stampNoPayDate,'1900-01-01')
OR ISNULL(t.stampNoPayUser,'') <> ISNULL(s.stampNoPayUser COLLATE SQL_Latin1_General_CP850_CI_AS,'')
OR ISNULL(t.comments,'') <> ISNULL(s.comments COLLATE SQL_Latin1_General_CP850_CI_AS,'')
OR ISNULL(t.maxWorkTime,0) <> ISNULL(s.maxWorkTime,0))
THEN UPDATE 
SET t.codeDateEnd = s.codeDateEnd
	,t.stampCodeDate = s.stampCodeDate
	,t.stampCodeUser = s.stampCodeUser
	,t.absPayDivision = s.absPayDivision
	,t.absPayFlags = s.absPayFlags
	,t.absPayTime = s.absPayTime
	,t.absPayAmount = s.absPayAmount
	,t.stampNoPayDate = s.stampNoPayDate
	,t.stampNoPayUser = s.stampNoPayUser
	,t.comments = s.comments
	,t.maxWorkTime = s.maxWorkTime
	,t.record_updated_date = SYSDATETIME()
WHEN NOT MATCHED BY TARGET THEN INSERT (
emp_SID
,absCode
,absDateBegin
,absTimeBegin
,codeDateBegin
,absPayCode
,codeDateEnd
,stampCodeDate
,stampCodeUser
,absPayDivision
,absPayFlags
,absPayTime
,absPayAmount
,stampNoPayDate
,stampNoPayUser
,comments
,maxWorkTime
)
VALUES
(s.emp_SID, s.absCode, s.absDateBegin, s.absTimeBegin, s.codeDateBegin, s.absPayCode, s.codeDateEnd, s.stampCodeDate, s.stampCodeUser, s.absPayDivision, s.absPayFlags, s.absPayTime, s.absPayAmount, s.stampNoPayDate, s.stampNoPayUser, s.comments, s.maxWorkTime)
WHEN NOT MATCHED BY SOURCE THEN DELETE	
OUTPUT $action INTO @outputTbl;


DECLARE @ins INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'INSERT')
DECLARE @upd INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'UPDATE')
DECLARE @del INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'DELETE')
DECLARE @prg VARCHAR(90) = @@SERVERNAME + '.ltd_dw.ops.merge_absencePay'

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
select 'OPSP',
'ltd_dw.ops.absencePay',
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
