SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- ================LTD_GLOSSARY=============================
-- Author:		B. Eichberger
-- Create date: 20240423
-- Description:	Process FA Service Request Step 1 to submit through PBIRS-SSRS
-- example:	exec process.FA_Service_Request_step1 'LTD\Barb Eichberger', '1001', null,'accident',  'it was a mess', null

-- =============================================

CREATE   PROCEDURE [process].[z_FA_Service_Request_step1_deprecate_20251231]
@currentUser VARCHAR(42)
,@veh VARCHAR(42)
,@busExchanged VARCHAR(42) NULL
,@reason VARCHAR(255)
,@describeService VARCHAR(255)
,@fasrkeynumber BIGINT NULL
AS
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


	SELECT @busExchanged = ISNULL(@busExchanged,'Not Exchanged')

	select @fasrkeynumber = (SELECT CAST(DATEDIFF(s,'1970-01-01 00:00:00',GETDATE()) AS bigint))
	DECLARE @fixedUser VARCHAR(90) = (
				SELECT CASE WHEN @currentUser LIKE '%Heather%' THEN 'LTD\Heather Lindsay' ELSE @currentUser END
			);
-- DROP TABLE IF EXISTS process.JobStepDataFAServiceReq
	IF (
		SELECT COUNT(*)FROM sys.tables WHERE name = 'JobStepDataFAServiceReq'
	) = 0
	BEGIN
		CREATE TABLE process.JobStepDataFAServiceReq
		(	FASR_Key BIGINT NOT NULL 
		   ,Job_Name VARCHAR(90) NOT NULL
		   ,veh VARCHAR(42) NOT NULL
		   ,reason VARCHAR(255) NOT NULL
		   ,busExchanged VARCHAR(42) NULL
		   ,describeService VARCHAR(255) NOT NULL
		   ,VariableName VARCHAR(25) NOT NULL
		   ,VariableValue VARCHAR(25) NOT NULL
		   ,VariableValDate DATETIME2 DEFAULT SYSDATETIME() NOT NULL);
		--GRANT SELECT ON -- select * from -- truncate table 
		--process.JobStepDataFAServiceReq TO PUBLIC;
	END;
	--SELECT * FROM process.JobStepDataFAServiceReq ORDER BY VariableValDate desc
	INSERT INTO process.JobStepDataFAServiceReq
	(FASR_Key
	,Job_Name
	   ,veh
	   ,reason
	   ,busExchanged
	   ,describeService
	   ,VariableName
	   ,VariableValue
	)
	VALUES
	( @fasrkeynumber, 'FA Service Request', @veh, @reason, LTRIM(RTRIM(@busExchanged)), REPLACE(@describeService, '''', ''), 'UserFromPBIRS', @fixedUser);

	SELECT @fasrkeynumber AS fasrkeynbr,'
Greetings ' + LEFT(REPLACE(@fixedUser, 'LTD\', ''), CHARINDEX(' ', ISNULL(@fixedUser, 9999)) - 5) + ',
 
The values you entered for FA Service Request ' + CAST(@fasrkeynumber AS VARCHAR(22)) + ' are:

Vehicle: ' + @veh + '

Reason Category: ' + @reason + '

Bus Exchanged With: ' + @busExchanged + '

Description of the Issue/Situation/Problem: ' + REPLACE(@describeService, '''', '') + '

If these values are ok, then click here to process the FA Service Request. 

To try again: reset/refill/update the parameter fields at the top of the page then click [View Report] button. If ok, click here to process the request. 

If you wish to cancel just leave this page.

	 ' AS banner;



END TRY
BEGIN CATCH

	DECLARE @profile VARCHAR(255) = (
				SELECT TOP (1) name FROM msdb.dbo.sysmail_profile
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

	SELECT @errormsg = 'Error in ' + ISNULL(@SPROC, '') + ': ' + CAST(ISNULL(@error, '') AS NVARCHAR(32)) + '|' + COALESCE(@message, '') + '|' + CAST(ISNULL(@xstate, '') AS NVARCHAR(32)) + '|' + CAST(ISNULL(@errsev, '') AS NVARCHAR(32));

	SELECT @sub = 'ERROR: ' + @SPROC;

	EXEC msdb.dbo.sp_send_dbmail @profile_name = @profile
   ,@recipients = 'barb.eichberger@ltd.org'
   ,@subject = @sub
   ,@body = @errormsg;

	RAISERROR(@errormsg, @errsev, 1);
END CATCH;


GO
GRANT EXECUTE ON  [process].[z_FA_Service_Request_step1_deprecate_20251231] TO [public]
GO
