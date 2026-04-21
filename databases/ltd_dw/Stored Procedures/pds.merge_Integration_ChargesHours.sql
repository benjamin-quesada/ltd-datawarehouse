SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [pds].[merge_Integration_ChargesHours]
AS
/*-----------LTD_GLOSSARY---------------
created by	:  b. eichberger
created dt	:  2024-07-30
purpose		:  merge Integration_ChargesHour from ph_charges - PDS
use			:  exec [pds].[merge_Integration_ChargesHours]
 
UPDATED BY	:  Sopheap Suy
UPDATED DT	:  10/31/2024
purpose		:  Add object activities on who, what, when call this object
			   write this data to aud.object_activity table everytime it is 
			   called 

*/
 
SET NOCOUNT ON
 
DECLARE @SPROC VARCHAR(100)
SET @SPROC = OBJECT_SCHEMA_NAME(@@PROCID) + '.' + OBJECT_NAME(@@PROCID)
 
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

DROP TABLE IF EXISTS #tempstage
 
--Clean the data 
SELECT DISTINCT 
ISNULL(s.[person_id],0)[person_id]
,ISNULL(s.[charge_code], '')[charge_code]
,ISNULL(s.[charge_number], '')[charge_number]
,ISNULL(s.[charge_date],'01-01-1900')[charge_date]
,ISNULL(s.[charge_hours],0)[charge_hours]
,ISNULL(s.[charge_amount],0)[charge_amount]
,ISNULL(s.[context_user_id],'')[context_user_id]
,ISNULL(s.[ph_id], 0)[ph_id]
,ISNULL(s.[phcntl_id], 0)[phcntl_id]
,ISNULL(s.[name], '')[name]
,ISNULL(s.[last_name],'')[last_name]
,ISNULL(s.[first_name],'')[first_name]
,ISNULL(s.[middle_name],'')[middle_name]
,ISNULL(s.[middle_initial],'')[middle_initial]
,ISNULL(s.[aka], '')[aka]
,ISNULL(s.[employee_id],0)[employee_id]
,ISNULL(s.[company_code],'')[company_code]
,ISNULL(s.[company],'')[company]
,ISNULL(s.[check_number],'')[check_number]
,ISNULL(s.[check_date],'01-01-1900')[check_date]
,ISNULL(s.[period_end_date],'01-01-1900')[period_end_date]
,ISNULL(s.[charge_seq],0)[charge_seq]
,ISNULL(s.[charge_position_code],'')[charge_position_code]
,ISNULL(s.[charge_job_code],'')[charge_job_code]
,ISNULL(s.[location_code],'')[location_code]
,ISNULL(s.[distribution_code],'')[distribution_code]
,ISNULL(s.[org_code], '')[org_code]
,ISNULL(s.[charge_shift_code],'')[charge_shift_code]
,CASE WHEN TRY_PARSE(cast([charge_shift_amount] AS VARCHAR(50)) AS DECIMAL) = 0 THEN null 
	  WHEN [charge_shift_amount] NOT LIKE '%[0-9]%' THEN NULL 
	  ELSE s.[charge_shift_amount] END AS [charge_shift_amount]
,CASE WHEN TRY_PARSE(cast(charge_rate AS VARCHAR(50)) AS DECIMAL) = 0 THEN null 
	  WHEN charge_rate NOT LIKE '%[0-9]%' THEN NULL 
		 ELSE s.charge_rate END AS [charge_rate]
,CASE WHEN TRY_PARSE(cast([charge_base_rate] AS VARCHAR(50)) AS DECIMAL) = 0 THEN null 
	  WHEN [charge_base_rate] NOT LIKE '%[0-9]%' THEN NULL 
		 ELSE s.[charge_base_rate] END AS [charge_base_rate]
,CASE WHEN TRY_PARSE(cast([charge_percent] AS VARCHAR(50)) AS DECIMAL) = 0  THEN null 
	  WHEN [charge_percent] NOT LIKE '%[0-9]%' THEN NULL 
		 ELSE s.[charge_percent] END AS [charge_percent]
,ISNULL(s.[shift_name] ,'')[shift_name]
,ISNULL(s.[is_overtime],'')[is_overtime]
INTO #tempStage 
FROM [pds].[Integration_ChargesHours_Stage] s
 



DECLARE @allCount INT = (SELECT ISNULL(COUNT(*),0) FROM #tempStage)
 
IF (SELECT COUNT(*) FROM #tempStage) > 0
BEGIN
 
MERGE -- truncate table
[pds].[Integration_ChargesHours] AS t
USING #tempStage AS s
ON (
t.[person_id]   = s.[person_id]
AND t.charge_code    = s.charge_code
AND t.charge_date    = s.charge_date
and t.charge_number = s.charge_number
AND t.[charge_hours] = s.[charge_hours]
AND t.[charge_amount]= s.[charge_amount]
AND t.[name] = s.[name]
AND t.[last_name] = s.[last_name]
AND t.[first_name] = s.[first_name]
AND t.[employee_id]  = s.[employee_id]
AND t.[company] = s.[company]
AND t.[company_code] = s.[company_code]
AND  t.[check_number] = s.[check_number]
AND t.[check_date] = s.[check_date] 
AND t.[period_end_date] = s.[period_end_date]
AND t.[charge_seq] = s.[charge_seq]
 )
WHEN MATCHED AND ( 
    t.[context_user_id] <> s.[context_user_id]
 OR t.[ph_id] <> s.[ph_id]
 OR t.[phcntl_id] <> s.[phcntl_id]
 OR t.[middle_name]    <> s.[middle_name]
 OR t.[middle_initial]  <> s.[middle_initial]
 OR t.[aka] <> s.[aka]
 OR t.[charge_position_code] <>s.[charge_position_code] 
 OR t.[charge_job_code]  <> s.[charge_job_code] 
 OR t.[org_code] <> s.[org_code] 
 OR t.[charge_shift_code]<> s.[charge_shift_code]
 OR ISNULL(t.[charge_shift_amount],0) <> ISNULL(s.[charge_shift_amount],0) 
 OR ISNULL(t.[charge_rate],0) <> ISNULL(s.[charge_rate],0) 
 OR ISNULL(t.[charge_base_rate],0) <> ISNULL(s.[charge_base_rate] ,0)
 OR ISNULL(t.[charge_percent],0) <> ISNULL(s.[charge_percent],0)
 OR t.[shift_name] <> s.[shift_name] 
 OR t.[location_code] <> s.[location_code]
 OR t.[distribution_code] <> s.[distribution_code]
 OR t.[is_overtime] <> s.[is_overtime]
)
THEN UPDATE SET
 t.[charge_hours]  = s.[charge_hours]
, t.[charge_amount] = s.[charge_amount]
, t.[context_user_id] = s.[context_user_id]
, t.[ph_id] = s.[ph_id]
, t.[phcntl_id]=  s.[phcntl_id] 
, t.[name] =  s.[name] 
, t.[last_name] =   s.[last_name]
, t.[first_name] =  s.[first_name]
, t.[middle_name] =  s.[middle_name]
, t.[middle_initial] = s.[middle_initial]
, t.[aka] =  s.[aka]
, t.[company_code] = s.[company_code]
, t.[company] = s.[company]
, t.[location_code] = s.[location_code]
, t.[distribution_code] = s.[distribution_code]
, t.[org_code] = s.[org_code]
, t.[charge_shift_code] = s.[charge_shift_code]
, t.[charge_shift_amount] = s.[charge_shift_amount]
, t.[charge_rate] = s.[charge_rate]
, t.[charge_base_rate] = s.[charge_base_rate]
, t.[charge_percent] = s.[charge_percent]
, t.[shift_name] = s.[shift_name]
, t.[is_overtime] = s.[is_overtime]
, t.record_updated_date = SYSDATETIME()
WHEN NOT MATCHED BY TARGET
THEN INSERT
(
[person_id]
,[charge_code]
,[charge_number]
,[charge_date]
,[charge_hours]
,[charge_amount]
,[context_user_id]
,[ph_id]
,[phcntl_id]
,[name]
,[last_name]
,[first_name]
,[middle_name]
,[middle_initial]
,[aka]--
,[employee_id]
,[company_code]
,[company]
,[check_number]
,[check_date]
,[period_end_date]
,[charge_seq]
,[charge_position_code]
,[charge_job_code]
,[location_code]
,[distribution_code]
,[org_code]
,[charge_shift_code]
,[charge_shift_amount]
,[charge_rate]
,[charge_base_rate]
,[charge_percent]
,[shift_name]
,[is_overtime]
)
VALUES
(s.[person_id] 
,s.[charge_code] 
,s.[charge_number] 
,s.[charge_date] 
,s.[charge_hours] 
,s.[charge_amount] 
,s.[context_user_id]
,s.[ph_id]   
,s.[phcntl_id] 
,s.[name]   
,s.[last_name] 
,s.[first_name]
,s.[middle_name]
,s.[middle_initial]
,s.[aka]   
,s.[employee_id] 
,s.[company_code]
,s.[company] 
,s.[check_number]
,s.[check_date] 
,s.[period_end_date]
,s.[charge_seq] 
,s.[charge_position_code]
,s.[charge_job_code]
,s.[location_code]
,s.[distribution_code]
,s.[org_code] 
,s.[charge_shift_code]
,s.[charge_shift_amount]
,s.[charge_rate] 
,s.[charge_base_rate]
,s.[charge_percent]
,s.[shift_name] 
,s.[is_overtime])
OUTPUT $action INTO @outputTbl;
 
 
DECLARE @ins INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'INSERT')
DECLARE @upd INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'UPDATE')
DECLARE @del INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'DELETE')
DECLARE @prg varchar(90) = @@SERVERNAME + '.ltd_dw.pds.merge_Integration_ChargesHours: ' + CAST(@allCount AS VARCHAR(12))
 
INSERT process.mergeLogs
( [MergeCode]
           ,[ObjectDestination]
           ,[ObjectSource]
           ,[ObjectProgram]
           ,[recInsert]
           ,[recUpdate]
           ,[recDelete]
           ,[MergeBeginDatetime]
           ,[MergeEndDatetime])
SELECT 'PDSCH',
'ltd_dw.pds.Integration_ChargesHours',
'PDS',
@prg,
ISNULL(@ins,0) ,ISNULL(@upd,0),ISNULL(@del,0),
@sdt,
SYSDATETIME()
 
END
END TRY  
 
BEGIN CATCH
 
       DECLARE @profile VARCHAR(255) = (
                    SELECT [NAME]
                    FROM msdb.dbo.sysmail_profile
                    )
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
 
       SELECT @errormsg = 'Error in ' + ISNULL(@SPROC, '') + ': ' + CAST(ISNULL(@error, '') AS NVARCHAR(32)) + '|' + COALESCE(@message, '') + '|' + CAST(ISNULL(@xstate, '') AS NVARCHAR(32)) + '|' +CAST(ISNULL(@errsev, '') AS NVARCHAR(32))
 
       SELECT @sub = 'ERROR: ' + @SPROC
 
       EXEC msdb.dbo.sp_send_dbmail @profile_name = @profile
             ,@recipients = 'barb.eichberger@ltd.org' 
             ,@subject = @sub
             ,@body = @errormsg;
 
       RAISERROR (
                    @errormsg
                    ,@errsev
                    ,1
                    )
END CATCH; 
GO
