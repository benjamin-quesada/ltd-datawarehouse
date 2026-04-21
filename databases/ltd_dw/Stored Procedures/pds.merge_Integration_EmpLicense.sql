SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


create PROCEDURE [pds].[merge_Integration_EmpLicense]
AS
/*-----------LTD_GLOSSARY---------------
created by	:  B. Eichberger
created dt	:  2026-02-18
purpose		:  merge Integration_EmpLicense from PDS
use			:  exec [pds].[merge_Integration_EmpLicense]

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
					  


DROP TABLE IF EXISTS #EmpLicense_stage

SELECT DISTINCT [person_id]
      ,[license]
      ,[license_code]
      ,[effective_date]
      ,[expiration_date]
      ,[license_number]
	  INTO #EmpLicense_stage
  FROM [ltd_dw].[pds].[Integration_EmpLicense_Stage]

DECLARE @allCount INT = (SELECT ISNULL(COUNT(*),0) FROM #EmpLicense_stage)

IF @allcount > 0 
BEGIN


MERGE [pds].[Integration_EmpLicense] AS t
USING #EmpLicense_stage AS s
ON (
	    t.[person_id] = s.[person_id]
	and t.license_code = s.license_code
	and t.license = s.license
	
   )
WHEN MATCHED AND ( 
				ISNULL(t.[effective_date],'1/1/1900') <> ISNULL(s.[effective_date],'1/1/1900')
			 or isnull(t.[expiration_date],'1/1/1900') <> ISNULL(s.[expiration_date],'1/1/1900')
			 or isnull(t.[license_number],'1/1/1900') <> ISNULL(s.[license_number],'1/1/1900')
				 
		)
	THEN UPDATE SET
	  t.[effective_date] = s.[effective_date]
	, t.[expiration_date] = s.[expiration_date]
	, t.[license_number] = s.[license_number]
	, t.record_updated_date = SYSDATETIME()
WHEN NOT MATCHED BY TARGET
	THEN INSERT
		 (
		 person_id
		,license 
		,license_code
		,[effective_date]
		,[expiration_date]
		,[license_number]
		 )
		 VALUES
		 (s.person_id, s.license, s.license_code, s.[effective_date], s.[expiration_date], s.[license_number])
OUTPUT $action INTO @outputTbl;


DECLARE @ins INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'INSERT')
DECLARE @upd INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'UPDATE')
DECLARE @del INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'DELETE')
DECLARE @prg varchar(90) = @@SERVERNAME + '.ltd_dw.pds.merge_Integration_EmpLicense: ' + CAST(@allCount AS VARCHAR(12))

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
SELECT 'PDSLIC',
'ltd_dw.pds.Integration_EmpLicense',
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
