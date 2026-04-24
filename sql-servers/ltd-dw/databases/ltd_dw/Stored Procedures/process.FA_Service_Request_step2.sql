SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






CREATE   PROCEDURE [process].[FA_Service_Request_step2]

@currentUser VARCHAR(42), @fasrkeynumber VARCHAR(42)
--EXEC process.FA_Service_Request_step2 'LTD\Barb Eichberger',1738678090

AS
/*
=================LTD_GLOSSARY================
Author:		B. Eichberger
Create date: 202404236
Description:	Process FA Service Request
			Step 2: kick off processing and confirm for
					the @currentUser

UPDATED BY:	Sopheap Suy
UPDATED DT:  10/31/2024
purpose	 :  Add object activities on who, what, when call this object
			write this data to aud.object_activity table everytime it's called 


UPDATED BY:	Ben Quesada
UPDATED DT:  9/22/2025
purpose	 :  removed unused variable
			corrected description logic to remove leading spaces and moved null check to outside the in statement so it can hit both scenarios
			updated notification email 

=============================================			
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
 
--declare @currentUser VARCHAR(42) = 'LTD\Barb Eichberger'
--declare @fasrkeynumber VARCHAR(42) = 1766424455


DECLARE @p_vehicle_id varchar(12), @p_reason_code varchar(6), @p_work_class_code char(1), @p_comments varchar(255), @p_description varchar(255),@reportedBy varchar(50),@mobileuid varchar(36)

select @p_vehicle_id = (select veh from [process].[JobStepDataFAServiceReq] where FASR_Key = @fasrkeynumber)
select @p_reason_code = (select left(substring(reason,charindex(';',reason)+2,999),6) from [process].[JobStepDataFAServiceReq] where FASR_Key = @fasrkeynumber)
select @p_work_class_code = 4
select @p_comments = (select cast(@fasrkeynumber as varchar(42))+'^'+ replace(@currentUser,'LTD\','') + '^'+left(isnull(describeService,''),255)
						from [process].[JobStepDataFAServiceReq] where FASR_Key = @fasrkeynumber)
select @p_description = (select case when 
								(busExchanged in ('Unknown','Not Exchanged') or [busExchanged] is null)
								then left(replace(describeService,'^',' ') + ' Username: ' + replace(@currentUser,'LTD\',''),255)
								else left(replace(describeService,'^',' ') + ' was replaced with ' + busExchanged + ' Username: ' + replace(@currentUser,'LTD\',''),255) end
								from [process].[JobStepDataFAServiceReq] where FASR_Key = @fasrkeynumber)
select @reportedBy = (select replace(@currentUser,'LTD\',''))
select @mobileuid = cast(@fasrkeynumber as varchar(28)) 
--SELECT @p_vehicle_id
--SELECT @p_reason_code
--SELECT @p_work_class_code
--SELECT @p_comments
--SELECT @p_description
--SELECT @reportedBy


-- INSERT FASR to EAM								
EXEC [LTD-EAM].ltd_db.[dbo].[insert_service_request_new] @p_vehicle_id, @p_reason_code, @p_work_class_code, @p_comments, @p_description, @reportedBy, @mobileuid


waitfor delay '00:00:05'

EXEC [process].[FA_Service_Request_Alert] @currentUser, @fasrkeynumber

waitfor delay '00:00:05'


select '
Your FA Service Request has been submitted. 

You can close this page.
 '
 as banner


end try

begin catch

       declare @profile varchar(255) = (
                    select NAME
                    from msdb.dbo.sysmail_profile
                    )
       declare @errormsg varchar(max)
             ,@error int
             ,@message varchar(max)
             ,@xstate int
             ,@errsev int
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
END CATCH


GO
