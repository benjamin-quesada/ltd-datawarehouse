SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE PROCEDURE [process].[z_FA_Service_Request_step2_deprecate_20251231]

@currentUser VARCHAR(42), @fasrkeynumber VARCHAR(42)

--EXEC process.FA_Service_Request_step2 'LTD\Barb Eichberger',1738678090

AS

-- =============================================
-- Author:		B. Eichberger
-- Create date: 202404236
-- Description:	Process FA Service Request
--				Step 2: kick off processing and confirm for
--						the @currentUser
--
-- =============================================

/*------------------LTD_GLOSSARY---------------
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
 

DECLARE @fixedUser VARCHAR(90) =  (SELECT CASE WHEN @currentUser LIKE '%Heather%' THEN 'LTD\Heather Lindsay' ELSE @currentUser END)	

DECLARE @p_vehicle_id varchar(12), @p_reason_code varchar(6), @p_work_class_code char(1), @p_comments varchar(255), @p_description varchar(255)
,@reportedBy VARCHAR(50),@mobileuid varchar(36)

SELECT @p_vehicle_id = (SELECT veh from [process].[JobStepDataFAServiceReq] WHERE FASR_Key = @fasrkeynumber)
SELECT @p_reason_code = (SELECT LEFT(SUBSTRING(reason,CHARINDEX(';',reason)+2,999),6) from [process].[JobStepDataFAServiceReq] WHERE FASR_Key = @fasrkeynumber)
SELECT @p_work_class_code = 4
SELECT @p_comments = (SELECT CAST(@fasrkeynumber AS VARCHAR(42))+'^'+ REPLACE(@currentUser,'LTD\','') + '^'+LEFT(ISNULL(describeService,''),255)
						FROM [process].[JobStepDataFAServiceReq] WHERE FASR_Key = @fasrkeynumber)
SELECT @p_description = (SELECT CASE WHEN 
								busExchanged NOT IN (' Unknown',' Not Exchanged',NULL)
								THEN LEFT(REPLACE(describeService,'^',' ') + ' was replaced with ' + busExchanged + ' Username: ' + REPLACE(@currentUser,'LTD\',''),255)
								ELSE LEFT(REPLACE(describeService,'^',' ') + ' Username: ' + REPLACE(@currentUser,'LTD\',''),255) END
								FROM [process].[JobStepDataFAServiceReq] WHERE FASR_Key = @fasrkeynumber)
SELECT @reportedBy = (SELECT REPLACE(@currentUser,'LTD\',''))
SELECT @mobileuid = CAST(@fasrkeynumber AS VARCHAR(28)) 
--SELECT @p_vehicle_id
--SELECT @p_reason_code
--SELECT @p_work_class_code
--SELECT @p_comments
--SELECT @p_description
--SELECT @reportedBy

---- INSERT FASR to EAM								
EXEC [LTD-EAM].ltd_db.[dbo].[insert_service_request_new] @p_vehicle_id, @p_reason_code, @p_work_class_code, @p_comments, @p_description, @reportedBy, @mobileuid


EXEC [process].[FA_Service_Request_Alert] @currentUser, @fasrkeynumber



SELECT '
Your FA Service Request has been submitted. 

You can close this page.
 '
 AS banner


END TRY

BEGIN CATCH

       DECLARE @profile VARCHAR(255) = (
                    SELECT NAME
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
GRANT EXECUTE ON  [process].[z_FA_Service_Request_step2_deprecate_20251231] TO [public]
GO
