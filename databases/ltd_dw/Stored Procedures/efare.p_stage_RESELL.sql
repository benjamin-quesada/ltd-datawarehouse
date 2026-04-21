SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   PROCEDURE [efare].[p_stage_RESELL]
@activefile varchar(255) -- = 'DRKResell637043216192094522.txt'
as

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


if len(@activefile) > 7
BEGIN

--declare @activefile varchar(255) = 'E:\filedrop\efare\DRKResell637043308163501692.txt'
declare @sqlcmd nvarchar(max)
select @sqlcmd = ''
select @sqlcmd = @sqlcmd + '
SELECT
       p.Name,
       p.Id,
	   p.[Locations] 
FROM OPENROWSET (BULK '''+@activefile+ ''', SINGLE_CLOB) as j
CROSS APPLY OPENJSON(BulkColumn)
WITH (
       name varchar(50),
       id varchar(50),
	   locations nvarchar(max) as json
) AS p
'
--print @sqlcmd
exec sp_executesql @sqlcmd
WITH RESULT SETS
(
       (
       name varchar(50),
       id varchar(50),
	   locations nvarchar(max)
	   )
)

END
GO
