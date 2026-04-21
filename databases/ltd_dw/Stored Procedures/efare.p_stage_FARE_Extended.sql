SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   PROCEDURE [efare].[p_stage_FARE_Extended]
@activefile varchar(255) -- = 'DRKfare637015646283641798.txt'
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

--declare @activefile varchar(255) = 'E:\filedrop\efare\loadedFiles\UMOfare638185188050023023.txt'
declare @sqlcmd nvarchar(max)
select @sqlcmd = ''
select @sqlcmd = @sqlcmd + '
SELECT
 p.txId
,p.ts
,p.type
,p.mediaUsed
,p.mediaType
,cardNumber = isnull(p.cardNumber,''0'')
,p.fareType
,accountId = isnull(p.accountId,''0'')
,p.stopName
,p.stopId
,p.routeName
,p.latitude
,p.longitude
,p.reader
,p.vehicle
,p.passUsed
,p.productAbbreviation
,p.trip
,p.readerPosition
,p.fare
,p.routeTypeId
,p.routeTypeName
,p.postedTs
,p.passFirstUsed
,p.lastModifiedTs
,p.stopGtfsId
,p.stopGtfsCode
FROM OPENROWSET (BULK '''+@activefile+ ''', SINGLE_CLOB) as j
CROSS APPLY OPENJSON(BulkColumn)
WITH (
 txId varchar(50),
    ts varchar(50),
	[type] varchar(50),
	mediaUsed varchar(50),
	mediaType varchar(50),
	cardNumber varchar(50),
    fareType varchar(50),
	accountId varchar(50),
	stopName varchar(90),
	stopId varchar(12),
	routeName varchar(50),
	latitude  varchar(50),
	longitude varchar(50),
	reader varchar(50),
	vehicle varchar(50),
	passUsed varchar(50),  
	productAbbreviation varchar(50), 
	trip varchar(50),
	readerPosition varchar(50),
	fare varchar(50),
	routeTypeId varchar(50),
	routeTypeName varchar(50),
	postedTs varchar(50),
	passFirstUsed varchar(50),
	lastModifiedTs varchar(50),
	stopGtfsId varchar(50),
	stopGtfsCode varchar(50)

) AS p
'

exec sp_executesql @sqlcmd
WITH RESULT SETS
(
       (
      txId varchar(50),
    ts varchar(50),
	[type] varchar(50),
	mediaUsed varchar(50),
	mediaType varchar(50),
	cardNumber varchar(50),
    fareType varchar(50),
	accountId varchar(50),
	stopName varchar(90),
	stopId varchar(12),
	routeName varchar(50),
	latitude  varchar(50),
	longitude varchar(50),
	reader varchar(50),
	vehicle varchar(50),
	passUsed varchar(50),  
	productAbbreviation varchar(50), 
	trip varchar(50),
	readerPosition varchar(50),
	fare varchar(50),
	routeTypeId varchar(50),
	routeTypeName varchar(50),
	postedTs varchar(50),
	passFirstUsed varchar(50),
	lastModifiedTs varchar(50),
	stopGtfsId varchar(50),
	stopGtfsCode varchar(50))
       ) 

END
GO
