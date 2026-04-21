SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [tm].[get_significant_tps]
@bid VARCHAR(8)

AS
/*

CREATED ON:	20230103
CREATED BY: B. EICHBERGER
PURPOSE	  : Test Migration of Action SSRS - point to LTD-ETL

CREATED ON:	20230103
CREATED BY: B. EICHBERGER
PURPOSE	  : Update significant tps loader to include history storage
			and allow for simple start job option for SP&M

USE		  : exec tm.get_significant_tps '1709'

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

--DECLARE @bid VARCHAR(8)  = 2302

WHILE EXISTS
   (SELECT 1 FROM [ltd-etl].msdb.dbo.sysjobactivity y
							JOIN [ltd-etl].msdb.dbo.sysjobs j ON j.job_id = y.job_id
						WHERE j.name = 'File Processing - Significant Time Point from Excel to Stage'
						AND y.stop_execution_date IS NULL AND y.start_execution_date IS NOT NULL)
	BEGIN
		WAITFOR DELAY '00:00:04'; 
		
	END

EXEC [ltd-etl].msdb.dbo.sp_start_job @job_name = N'File Processing - Significant Time Point from Excel to Stage'						 

WAITFOR DELAY '00:00:04'

WHILE EXISTS
   (SELECT 1 FROM [ltd-etl].msdb.dbo.sysjobactivity y
							JOIN msdb..sysjobs j ON j.job_id = y.job_id
						WHERE j.name = 'File Processing - Significant Time Point from Excel to Stage'
						AND y.stop_execution_date IS NULL AND y.start_execution_date IS NOT NULL)
	BEGIN
		WAITFOR DELAY '00:00:04'; 
		
	END


IF (SELECT COUNT(*) FROM [ltd_dw].[tm].[significant_tps_history] WHERE bid = @bid ) <> 0
BEGIN
DELETE FROM tm.significant_tps_history WHERE bid = @bid
END

IF (SELECT COUNT(*) FROM [ltd_dw].[tm].[significant_tps_history] WHERE bid = @bid ) = 0
BEGIN

-- TRUNCATE TABLE [ltd_dw].[tm].[significant_tps_history]
INSERT [ltd_dw].[tm].[significant_tps_history](
[significant_tp_key]
      ,[bid]
      ,[route]
      ,[dir]
      ,[direction]
      ,[tp]
      ,[significant]
      ,[stps_record_created_date])
SELECT [significant_tp_key]
      ,[bid]
      ,[route]
      ,[dir]
      ,[direction]
      ,[tp]
      ,[significant]
      ,[record_created_date]
  FROM [ltd_dw].[tm].[significant_tps]

TRUNCATE TABLE [ltd_dw].[tm].[significant_tps];

INSERT INTO [tm].[significant_tps]
           ([bid]
           ,[route]
           ,[dir]
           ,[direction]
           ,[tp]
           ,[significant])
SELECT [bid]
        ,[route]
        ,[dir]
        ,[direction]
        ,[tp]
        ,[significant] FROM tm.stage_significant_tps


INSERT [ltd_dw].[tm].[significant_tps_history](
[significant_tp_key]
      ,[bid]
      ,[route]
      ,[dir]
      ,[direction]
      ,[tp]
      ,[significant]
      ,[stps_record_created_date])
SELECT [significant_tp_key]
      ,[bid]
      ,[route]
      ,[dir]
      ,[direction]
      ,[tp]
      ,[significant]
      ,[record_created_date]
  FROM [ltd_dw].[tm].[significant_tps]

END


END TRY	  

BEGIN CATCH

       DECLARE @profile VARCHAR(255) = (
                    SELECT NAME
                    FROM msdb.dbo.sysmail_profile
                    )
       DECLARE @errormsg VARCHAR(max)
             ,@error INT
             ,@message VARCHAR(max)
             ,@xstate INT
             ,@errsev INT
             ,@sub VARCHAR(255);

       SELECT @error = ERROR_NUMBER()
             ,@errsev = ERROR_SEVERITY()
             ,@message = ERROR_MESSAGE()
             ,@xstate = XACT_STATE();

       SELECT @errormsg = 'Error in ' + isnull(@SPROC, '') + ': ' + cast(isnull(@error, '') AS NVARCHAR(32)) + '|' + coalesce(@message, '') + '|' + cast(isnull(@xstate, '') AS NVARCHAR(32)) + '|' +cast(isnull(@errsev, '') AS NVARCHAR(32))

       SELECT @sub = 'ERROR: ' + @SPROC

       EXEC msdb.dbo.sp_send_dbmail @profile_name = @profile
             ,@recipients = 'barb.eichberger@ltd.org'--;data@ltd.org' 
             ,@subject = @sub
             ,@body = @errormsg;

       RAISERROR (
                    @errormsg
                    ,@errsev
                    ,1
                    )
END CATCH
GO
