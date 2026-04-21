SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		B. Eichberger
-- Create date: 20221213
-- Description:	to enable a job start order from ltd-tmdata
-- =============================================
CREATE   PROCEDURE [process].[start_dw_agent_job]
@jobName VARCHAR(255)

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.

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


	
	DECLARE @sqlcmd NVARCHAR(MAX) = ''
	SELECT @sqlcmd = @sqlcmd + 'EXEC msdb.dbo.sp_start_job '''+@jobName+''''
    --PRINT @sqlcmd 
	EXEC sp_executesql @sqlcmd

END
GO
