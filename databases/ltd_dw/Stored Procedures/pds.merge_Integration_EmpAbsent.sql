SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE   PROCEDURE [pds].[merge_Integration_EmpAbsent]
AS
/*-----------LTD_GLOSSARY---------------
created by	:  b. eichberger
created dt	:  2024-02-23
purpose		:  merge ops.absence from PDS
use			:  exec [pds].[merge_Integration_EmpAbsent_Hist]

updated by :  Sopheap Suy
updated dt :  2024-08-02

UPDATED BY:	Sopheap Suy
UPDATED DT:  10/31/2024
purpose	 :  Add object activities on who, what, when call this object
			write this data to aud.object_activity table everytime it's called 

UPDATED BY:	Sopheap Suy
UPDATED DT:  04/25/2025			
purpose:	Add a new proc to process the full load instead of incremental load
			
			*/

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
DECLARE @lastProcess smalldatetime = (SELECT DATEADD(DAY,-30,MAX([MergeBeginDatetime]))
										from process.MergeLogs
										where [ObjectDestination] = 'ltd_dw.pds.Integration_EmpAbsent_Stage'
										and ObjectProgram like 'SSIS_ISC_PROCESS_Integration_EmpAbsent%'
										and ObjectProgram not like 'SSIS_ISC_PROCESS_Integration_EmpAbsentHistory%')
					  

					  


DROP TABLE IF EXISTS #empAbsent_Stage

SELECT DISTINCT person_id
              , context_user_id
              , row_id
              , name
              , last_name
              , first_name
              , middle_name
              , middle_initial
              , aka
              , employee_id
              , company_code
              , company
              , accrual_code
              , accrual
              , from_date
              , return_date
              , time_taken
              , grace_time_taken
              , is_active
              , is_external_time
              , update_code
              , update_description
              , phth_id
              , comments
              , leave_reason
              , leave_reason_description
	  INTO #empAbsent_stage
  FROM [ltd_dw].[pds].[Integration_EmpAbsent_Stage]
  where cast(from_date as date) >= @lastProcess


DECLARE @allCount INT = (SELECT ISNULL(COUNT(*),0) FROM #empAbsent_stage)

IF @allcount > 0 
BEGIN


MERGE [pds].[Integration_EmpAbsent] AS t
USING #empAbsent_stage AS s
ON (
	   t.[person_id] = s.[person_id]
	   AND t.[row_id] = s.[row_id]
	   AND t.[employee_id] = s.[employee_id]
	   AND t.[accrual_code] = s.[accrual_code]
	   AND t.from_date = s.from_date
   )
WHEN MATCHED AND ( 
				ISNULL(t.context_user_id,'') <> ISNULL(s.context_user_id,'')
				 OR ISNULL( t.company_code,'') <> ISNULL(s.company_code	,'')
				 OR ISNULL( t.company,'') <> ISNULL(s.company,'')		
				 OR ISNULL( t.accrual,'') <> ISNULL(s.accrual,'')		
				 OR ISNULL( t.return_date,'') <> ISNULL(s.return_date,'')
				 OR ISNULL( t.time_taken,0.0) <> ISNULL(s.time_taken,0.0)
				 OR ISNULL( t.is_active,'') <> ISNULL(s.is_active,'')
				 OR ISNULL( t.is_external_time,'') <> ISNULL(s.is_external_time,'')
				 OR ISNULL( t.update_description,'') <> ISNULL(s.update_description,'')
				 OR ISNULL( t.comments,'') <> ISNULL(s.comments,'')
				 OR ISNULL( t.update_code,'') <> ISNULL(s.update_code ,'')
				 OR ISNULL( t.leave_reason,'') <> ISNULL(s.leave_reason,'')
				 OR ISNULL( t.leave_reason_description,'') <> ISNULL(s.leave_reason_description,'')
		)
	THEN UPDATE SET
		t.context_user_id = s.context_user_id
		,t.company_code = s.company_code
		,t.company = s.company
		,t.accrual = s.accrual
		,t.return_date = s.return_date
		,t.time_taken = s.time_taken
		,t.update_code = s.update_code
		,t.is_active = s.is_active
		,t.is_external_time = s.is_external_time
		,t.update_description = s.update_description
		,t.comments = s.comments
		,t.leave_reason = s.leave_reason
		,t.leave_reason_description = s.leave_reason_description
		,t.record_updated_date = SYSDATETIME()
WHEN NOT MATCHED BY TARGET
	THEN INSERT
		 (
			person_id
			,context_user_id
			,row_id
			,employee_id
			,company_code
			,company
			,accrual_code
			,accrual
			,from_date
			,return_date
			,time_taken
			,is_active
			,is_external_time
			,update_code
			,update_description
			,comments
			,leave_reason
			,leave_reason_description
		 )
		 VALUES
		 (s.person_id, s.context_user_id, row_id, s.employee_id
		 , s.company_code, s.company, s.accrual_code, s.accrual, s.from_date, s.return_date, s.time_taken 
		 , s.is_active, s.is_external_time, s.update_code, s.update_description 
		 , s.comments, s.leave_reason, s.leave_reason_description)
when not matched by source and cast(t.from_date as date) >= @lastProcess then delete
OUTPUT $action INTO @outputTbl;


DECLARE @ins INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'INSERT')
DECLARE @upd INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'UPDATE')
DECLARE @del INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'DELETE')
DECLARE @prg varchar(90) = @@SERVERNAME + '.ltd_dw.pds.merge_Integration_EmpAbsent: ' + CAST(@allCount AS VARCHAR(12))

INSERT process.mergeLogs
(		[MergeCode]
           ,[ObjectDestination]
           ,[ObjectSource]
           ,[ObjectProgram]
           ,[recInsert]
           ,[recUpdate]
           ,[recDelete]
           ,[MergeBeginDatetime]
           ,[MergeEndDatetime])
SELECT 'PDSEAH',
'ltd_dw.pds.Integration_EmpAbsent',
'PDS',
@prg,
ISNULL(@ins,0) ,ISNULL(@upd,0),ISNULL(@del,0),
@sdt,
SYSDATETIME()

END

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
             ,@recipients = 'data@ltd.org' 
             ,@subject = @sub
             ,@body = @errormsg;

       RAISERROR (
                    @errormsg
                    ,@errsev
                    ,1
                    )
END CATCH;
GO
