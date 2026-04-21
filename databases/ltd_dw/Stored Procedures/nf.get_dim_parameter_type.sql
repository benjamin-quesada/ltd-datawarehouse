SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   PROCEDURE [nf].[get_dim_parameter_type]
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


IF (SELECT COUNT(*) FROM sys.tables WHERE name = 'dim_parameter_type') = 0
BEGIN
CREATE TABLE model.dim_parameter_type (parameter_type_key INT IDENTITY(1,1) NOT NULL ,parameter_type INT NOT NULL, parameter_type_description VARCHAR(120) NOT NULL)
ON newflyer
END

INSERT model.dim_parameter_type(parameter_type,parameter_type_description)
	SELECT parameter_type, REPLACE(REPLACE(REPLACE(REPLACE (parameter_type_description,'GPS_Speed','GPS Speed'),'_',' '),' (PGN: 65349)',''),' (PGN: 65350)','')  parameter_type_description
	FROM dbo.newflyer_vehicleParameters s
	WHERE parameter_type NOT IN (280,281,13068)
	AND NOT EXISTS (SELECT 1 FROM model.dim_parameter_type WHERE parameter_type = s.parameter_type )
	GROUP BY parameter_type, REPLACE(REPLACE(REPLACE(REPLACE (parameter_type_description,'GPS_Speed','GPS Speed'),'_',' '),' (PGN: 65349)','') ,' (PGN: 65350)','')



GO
