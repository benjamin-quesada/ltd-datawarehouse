SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE   PROCEDURE [pds].[merge_Integration_EmpRoleHistory]
AS

/*-----------LTD_GLOSSARY---------------
CREATED BY	: B Eichberger
CREATED DT	:  02/26/2026 
purpose		:  merge pds.Integration_EmpRoleHistory from pds.Integration_EmpRoleHistory_Stage
use			:  exec pds.merge_Integration_EmpRoleHistory
 
*/

SET NOCOUNT ON;

BEGIN TRY

DECLARE @SPROC VARCHAR(100);
SET @SPROC = OBJECT_SCHEMA_NAME(@@PROCID) + '.' + OBJECT_NAME(@@PROCID);


INSERT INTO DBA.[aud].[Object_Activity]
	([server_name], [database_name] ,[host_name], [System_User], [object_name]
	,[client_net_address], [local_net_address], [auth_Scheme], [last_read], [last_write]
	,[most_recent_sql_handle], [Timestamp], object_type)
SELECT DISTINCT @@SERVERNAME, DB_NAME(),HOST_NAME(),SYSTEM_USER, @SPROC,
	client_net_address, local_net_address , auth_Scheme, last_read, last_write 
	,most_recent_sql_handle, CURRENT_TIMESTAMP AS [Timestamp], 'PROC'
FROM sys.dm_exec_connections 
WHERE session_id = @@SPID ;

DECLARE @cnt INT;

SELECT @cnt = COUNT(*)FROM pds.Integration_EmpRoleHistory_Stage;
IF (@cnt > 0)

DECLARE @lastDate DATE = (SELECT MIN(rcd) rcd FROM (
							SELECT MAX(record_created_date) rcd FROM [pds].Integration_EmpRoleHistory
							UNION
						    SELECT MAX(record_updated_date) FROM [pds].Integration_EmpRoleHistory WHERE record_updated_date IS NOT NULL
							) q )
						  


BEGIN

DECLARE @sdt DATETIME2 = SYSDATETIME();
DECLARE @outputTbl TABLE (actionNm VARCHAR(32));


MERGE pds.Integration_EmpRoleHistory AS t
USING pds.Integration_EmpRoleHistory_Stage AS s
ON t.person_id = s.person_id
   AND t.position_id = s.position_id
   AND t.pos_code = s.pos_code
   AND t.role_code = s.role_code
   AND t.[start_date] = s.[start_date]		 
WHEN MATCHED AND (
					 ISNULL(t.company_code, '') <> ISNULL(s.company_code, '')
					 OR ISNULL(t.role_name, '') <> ISNULL(s.role_name, '')
					 OR ISNULL(t.end_date, '') <> ISNULL(s.end_date, '')
					 OR ISNULL(t.emp_type, '') <> ISNULL(s.emp_type, '')
					 OR ISNULL(t.start_person_reason_code, '') <> ISNULL(s.start_person_reason_code, '')
					 OR ISNULL(t.start_person_reason, '') <> ISNULL(s.start_person_reason, '')
					 OR ISNULL(t.end_person_reason_code, '') <> ISNULL(s.end_person_reason_code, '')
					 OR ISNULL(t.end_person_reason, '') <> ISNULL(s.end_person_reason, '')
				 )
	THEN UPDATE SET
		 t.company_code = s.company_code
		,t.role_name = s.role_name
		,t.end_date = s.end_date
		,t.emp_type = s.emp_type
		,t.start_person_reason_code = s.start_person_reason_code
		,t.start_person_reason = s.start_person_reason
		,t.end_person_reason_code = s.end_person_reason_code
		,t.end_person_reason = s.end_person_reason
		,t.record_updated_date = GETDATE()
WHEN NOT MATCHED BY TARGET
	THEN INSERT
		 (
			 person_id
			,company_code
			,role_code
			,role_name
			,[start_date]
			,end_date
			,pos_code
			,position_id
			,emp_type
			,start_person_reason_code
			,start_person_reason
			,end_person_reason_code
			,end_person_reason
		 )
		 VALUES
		 (s.person_id, s.company_code, s.role_code, s.role_name, s.[start_date], s.end_date, s.pos_code, s.position_id,s.emp_type, s.start_person_reason_code, s.start_person_reason, s.end_person_reason_code, s.end_person_reason)
WHEN NOT MATCHED BY SOURCE AND t.[start_date] >= @lastDate  THEN DELETE
OUTPUT $action INTO @outputTbl;


TRUNCATE TABLE pds.Integration_EmpRoleHistory_Stage

;

DECLARE @ins INT = (SELECT COUNT(*)FROM @outputTbl WHERE actionNm = 'INSERT');
DECLARE @upd INT = (SELECT COUNT(*)FROM @outputTbl WHERE actionNm = 'UPDATE');
DECLARE @del INT = (SELECT COUNT(*)FROM @outputTbl WHERE actionNm = 'DELETE');
DECLARE @prg VARCHAR(90) = @@SERVERNAME + '.ltd_dw.' + @SPROC;

INSERT process.MergeLogs
(
	[MergeCode]
   ,[ObjectDestination]
   ,[ObjectSource]
   ,[ObjectProgram]
   ,[recInsert]
   ,[recUpdate]
   ,[recDelete]
   ,[MergeBeginDatetime]
   ,[MergeEndDatetime]
)
SELECT 'PDSER'
,'ltd_dw.pds.Integration_EmpRoleHistory'
,'PDS'
,@prg
,ISNULL(@ins, 0)
,ISNULL(@upd, 0)
,ISNULL(@del, 0)
,@sdt
,SYSDATETIME();

END

END TRY

BEGIN CATCH

DECLARE @profile VARCHAR(255) =
		(
			SELECT [name] FROM msdb.dbo.sysmail_profile
		);
DECLARE @errormsg VARCHAR(MAX)
,@error INT
,@message VARCHAR(MAX)
,@xstate INT
,@errsev INT
,@sub VARCHAR(255);

SELECT @error = ERROR_NUMBER()
,@errsev = ERROR_SEVERITY()
,@message = ERROR_MESSAGE()
,@xstate = XACT_STATE();

SELECT @errormsg = 'Error in ' + ISNULL(@SPROC, '') + ':' + CAST(ISNULL(@error, '') AS NVARCHAR(32)) + '|' + COALESCE(@message, '') + '|' + CAST(ISNULL(@xstate, '') AS NVARCHAR(32)) + '|' + CAST(ISNULL(@errsev, '') AS NVARCHAR(32));

SELECT @sub = 'ERROR: ' + @SPROC;

EXEC msdb.dbo.sp_send_dbmail @profile_name = @profile
,@recipients = 'data@ltd.org'
,@subject = @sub
,@body = @errormsg;

RAISERROR(@errormsg, @errsev, 1);
END CATCH;
GO
