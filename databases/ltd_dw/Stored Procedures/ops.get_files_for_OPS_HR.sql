SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   PROCEDURE [ops].[get_files_for_OPS_HR]
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


EXECUTE sp_configure 'show advanced options', 1;
RECONFIGURE;

EXECUTE sp_configure 'xp_cmdshell', 1;
RECONFIGURE;



declare @netuse1 nvarchar(255) = 'IF EXIST R: (net use R: /DELETE) > nul 2>&1'
exec master..xp_cmdshell @netuse1

waitfor delay '00:00:02'
declare @netuse2 nvarchar(255)
SELECT @netuse2 = 'net use R: \\ltd-cifsna1\Workgroup\OPS\OPS-HR > nul 2>&1'
exec master..xp_cmdshell @netuse2

 
declare  @xpcmd varchar(255)
select @xpcmd = 'xcopy R:\*FMLA*.xlsx E:\filedrop\ops_internal\ /Y > nul 2>&1'
exec master..xp_cmdshell @xpcmd

EXECUTE sp_configure 'xp_cmdshell', 0;
RECONFIGURE;
EXECUTE sp_configure 'show advanced options', 0;
RECONFIGURE;
;
GO
