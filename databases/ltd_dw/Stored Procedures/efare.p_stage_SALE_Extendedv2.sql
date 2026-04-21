SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   PROCEDURE [efare].[p_stage_SALE_Extendedv2]
@activefile VARCHAR(255) -- = 'UMOsale638907462040021487.txt'
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


IF LEN(@activefile) > 7
BEGIN

--declare @activefile varchar(255) = 'E:\filedrop\efare\UMOsale638907462040021487.txt'
DECLARE @sqlcmd NVARCHAR(MAX)
SELECT @sqlcmd = ''
SELECT @sqlcmd = @sqlcmd + '
SELECT
       p.txId,
       cast(p.ts as varchar(50)) ts,
	   p.[type] ,
       p.fareType,
       p.accountId,
	   p.passUsed,
	   p.salesUser,
	   p.salesUsername,
	   p.salesChannel,
	   p.retailerShortName, 
	   fundingSource,
	   locationDesc,
	   cost,
	   postedTs,
	   lastModifiedTs
FROM OPENROWSET (BULK '''+@activefile+ ''', SINGLE_CLOB) as j
CROSS APPLY OPENJSON(BulkColumn)
WITH (
       txId varchar(50),
       ts varchar(50),
	   [type] varchar(50),
       fareType varchar(50),
       accountId varchar(50),
	   passUsed varchar(90),
	   salesUser varchar(50),
	   salesUsername varchar(50),
	   salesChannel varchar(50),
	   retailerShortName varchar(120),
	   fundingSource varchar(50),
	   locationDesc varchar(50),
	   cost varchar(50) ,
	   postedTs varchar(50) ,
	   lastModifiedTs varchar(50) 
) AS p
'
print @sqlcmd
exec sp_executesql @sqlcmd
WITH RESULT SETS
(
       (
      txId varchar(50),
       ts varchar(50),
	   [type] varchar(50),
       fareType varchar(50),
       accountId varchar(50),
	   passused VARCHAR(90),
	   salesUser varchar(50),
	   salesUsername varchar(50),
	   salesChannel varchar(50),
	   retailerShortName VARCHAR(120),
	   fundingSource varchar(50),
	   locationDesc varchar(50),
	   cost varchar(50),
	   postedTs varchar(50) ,
	   lastModifiedTs varchar(50) 
       ) 
)

end
GO
