SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [pds].[merge_Integration_EmpExtended]
AS
/*-----------LTD_GLOSSARY---------------
created by	:  B. Eichberger
created dt	:  2025-07-16
purpose		:  merge Integration_EmpExtended from PDS
use			:  exec [pds].[merge_Integration_EmpExtended]

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
					  


DROP TABLE IF EXISTS #empExtended_stage

SELECT DISTINCT *
	  INTO #empExtended_stage
  FROM [ltd_dw].[pds].[Integration_EmpExtended_Stage]

DECLARE @allCount INT = (SELECT ISNULL(COUNT(*),0) FROM #empExtended_stage)

IF @allcount > 0 
BEGIN


MERGE [pds].[Integration_EmpExtended] AS t
USING #empExtended_stage AS s
ON (
	   t.[person_id] = s.[pdt]
	
   )
WHEN MATCHED AND ( 
				ISNULL(t.bdt,'1/1/1900') <> ISNULL(s.bdt,'1/1/1900')
				 
		)
	THEN UPDATE SET
		t.bdt = s.bdt
		,t.record_updated_date = SYSDATETIME()
WHEN NOT MATCHED BY TARGET
	THEN INSERT
		 (
		 person_id
		,bdt
		 )
		 VALUES
		 (s.pdt, s.bdt)
OUTPUT $action INTO @outputTbl;


DECLARE @ins INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'INSERT')
DECLARE @upd INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'UPDATE')
DECLARE @del INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'DELETE')
DECLARE @prg varchar(90) = @@SERVERNAME + '.ltd_dw.pds.merge_Integration_EmpExtended: ' + CAST(@allCount AS VARCHAR(12))

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
SELECT 'PDSEXT',
'ltd_dw.pds.Integration_EmpExtended',
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
