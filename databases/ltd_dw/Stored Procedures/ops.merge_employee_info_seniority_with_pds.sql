SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   PROCEDURE [ops].[merge_employee_info_seniority_with_pds]
AS
/*-----------LTD_GLOSSARY---------------
 created by	:  b. eichberger
 created dt	:  20240403
 purpose	:  merge through ltd-dw view from from ltd-ops.midas
 use		:  exec [ops].[merge_employee_info_seniority_with_pds]


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


MERGE ltd_dw.[ops].[employee_info_seniority_with_pds] AS t
USING ltd_dw.ops.[employee_info_seniority_with_pds_v] AS s
ON (t.personnelid = s.personnelid COLLATE SQL_Latin1_General_CP850_CI_AS)
WHEN MATCHED AND (
   ISNULL(t.lastname,'') <> ISNULL(s.lastname  COLLATE SQL_Latin1_General_CP850_CI_AS,'')
OR ISNULL(t.firstname,'') <> ISNULL(s.firstname  COLLATE SQL_Latin1_General_CP850_CI_AS,'')
OR ISNULL(t.[status],'') <> ISNULL(s.[status]  COLLATE SQL_Latin1_General_CP850_CI_AS,'')
OR ISNULL(t.lottery,0) <> ISNULL(s.lottery,0)
OR ISNULL(t.dateseniority,'1/1/1900') <> ISNULL(s.dateseniority,'1/1/1900')
OR ISNULL(t.seniority_seq,'') <> ISNULL(s.seniority_seq,'')
OR ISNULL(t.retire_date,'1/1/1900') <> ISNULL(s.retire_date,'1/1/1900')
OR ISNULL(t.emp_sid,'') <> ISNULL(s.emp_sid,0)
OR ISNULL(t.dw_emp_id,'') <> ISNULL(s.dw_emp_id,0)
OR ISNULL(t.dw_status,'') <> ISNULL(s.dw_status  COLLATE SQL_Latin1_General_CP850_CI_AS,'')
OR ISNULL(t.seniority_date_pds,'1/1/1900') <> ISNULL(s.seniority_date_pds,'1/1/1900')
OR ISNULL(t.pds_person_id,'') <> ISNULL(s.pds_person_id,0)
OR ISNULL(t.employee_id,'') <> ISNULL(s.employee_id  COLLATE SQL_Latin1_General_CP850_CI_AS,'')
OR ISNULL(t.hire_date,'1/1/1900') <> ISNULL(s.hire_date,'1/1/1900')
OR ISNULL(t.rehire_date_pds,'1/1/1900') <> ISNULL(s.rehire_date_pds,'1/1/1900')
OR ISNULL(t.termination_date_pds,'1/1/1900') <> ISNULL(s.termination_date_pds,'1/1/1900')
OR ISNULL(t.review_date_pds,'1/1/1900') <> ISNULL(s.review_date_pds,'1/1/1900')
OR ISNULL(t.adjusted_service_date_pds,'1/1/1900') <> ISNULL(s.adjusted_service_date_pds,'1/1/1900')
OR ISNULL(t.return_date_pds,'1/1/1900') <> ISNULL(s.return_date_pds,'1/1/1900'))
THEN UPDATE SET t.lastname = s.lastname
		,t.firstname = s.firstname
		,t.[status] = s.[status]
		,t.lottery = s.lottery
		,t.dateseniority = s.dateseniority
		,t.seniority_seq = s.seniority_seq
		,t.retire_date = s.retire_date
		,t.emp_sid = s.emp_sid
		,t.dw_emp_id = s.dw_emp_id
		,t.dw_status = s.dw_status
		,t.seniority_date_pds = s.seniority_date_pds
		,t.pds_person_id = s.pds_person_id
		,t.employee_id = s.employee_id
		,t.hire_date = s.hire_date
		,t.rehire_date_pds = s.rehire_date_pds
		,t.termination_date_pds = s.termination_date_pds
		,t.review_date_pds = s.review_date_pds
		,t.adjusted_service_date_pds = s.adjusted_service_date_pds
		,t.return_date_pds = s.return_date_pds
		,t.record_updated_date = SYSDATETIME()
WHEN NOT MATCHED BY TARGET THEN INSERT (
lastname
,firstname
,personnelid
,[status]
,lottery
,dateseniority
,seniority_seq
,retire_date
,emp_sid
,dw_emp_id
,dw_status
,seniority_date_pds
,pds_person_id
,employee_id
,hire_date
,rehire_date_pds
,termination_date_pds
,review_date_pds
,adjusted_service_date_pds
,return_date_pds
)
VALUES
(s.lastname, s.firstname, s.personnelid, s.[status], s.lottery, s.dateseniority, s.seniority_seq, s.retire_date, s.emp_sid, s.dw_emp_id, s.dw_status, s.seniority_date_pds, s.pds_person_id, s.employee_id, s.hire_date, s.rehire_date_pds, s.termination_date_pds, s.review_date_pds, s.adjusted_service_date_pds, s.return_date_pds)
WHEN NOT MATCHED BY SOURCE THEN DELETE	
OUTPUT $action INTO @outputTbl;


DECLARE @ins INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'INSERT')
DECLARE @upd INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'UPDATE')
DECLARE @del INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'DELETE')
DECLARE @prg VARCHAR(90) = @@SERVERNAME + '.ltd_dw.ops.merge_employee_info_seniority_with_pds'

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
select 'OPSEN',
'ltd_dw.ops.employee_info_seniority_with_pds',
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
