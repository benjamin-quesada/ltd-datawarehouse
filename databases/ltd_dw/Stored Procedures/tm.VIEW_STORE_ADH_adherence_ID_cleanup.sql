SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE   PROCEDURE [tm].[VIEW_STORE_ADH_adherence_ID_cleanup]
AS


/* --------------LTD_GLOSSARY------------------------------

NAME			DATE INT	Ticket Order or Request Info
Sopheap Suy		2025032		Adherence_ID often got delete and readd as part of the nightly staging process
							This stored proc is to remove the orphan's adherence_id

exec tm.VIEW_STORE_ADH_adherence_ID_cleanup

*/

DECLARE @SPROC VARCHAR(100)
SET @SPROC = OBJECT_SCHEMA_NAME(@@PROCID) + '.' + OBJECT_NAME(@@PROCID)

SET NOCOUNT ON

INSERT INTO dba.[aud].[Object_Activity]
	([server_name], [database_name] ,[host_name], [System_User], [object_name]
	,[client_net_address], [local_net_address], [auth_Scheme], [last_read], [last_write]
	,[most_recent_sql_handle], [Timestamp], object_type)
SELECT DISTINCT @@SERVERNAME, DB_NAME(),HOST_NAME(),SYSTEM_USER, @SPROC,
	client_net_address, local_net_address , auth_Scheme, last_read, last_write 
	,most_recent_sql_handle, CURRENT_TIMESTAMP AS [Timestamp], 'PROC'
FROM sys.dm_exec_connections 
WHERE session_id = @@SPID  ;

BEGIN TRY

	TRUNCATE TABLE wrk.bad_Adherence_id

	INSERT INTO wrk.bad_Adherence_id 
	SELECT vsa.adherence_id 
	FROM tm.VIEW_STORE_ADH vsa
	WHERE NOT EXISTS (SELECT 1 FROM  [ltd-tmdata].tmdatamart.dbo.ADHERENCE a
						WHERE vsa.adherence_id = a.adherence_id
						) 

	DELETE vsa
	FROM tm.VIEW_STORE_ADH vsa
	INNER JOIN wrk.bad_Adherence_id b
	ON b.adherence_id = vsa.adherence_id

END TRY

BEGIN CATCH

       DECLARE @profile VARCHAR(255) = (
                    SELECT TOP(1) NAME
                    FROM msdb.dbo.sysmail_profile
					WHERE name LIKE '%SQLData%'
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
END CATCH


GO
