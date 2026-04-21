SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   PROCEDURE [apc].[remove_survey]
@filesrc NVARCHAR(256)
AS

BEGIN
	
	/* ------------------LTD_GLOSSARY---------------
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

	DELETE FROM apc.apc_survey_trips WHERE fileSource = @filesrc
	DELETE FROM apc.apc_survey_data WHERE fileSource = @filesrc
END
GO
