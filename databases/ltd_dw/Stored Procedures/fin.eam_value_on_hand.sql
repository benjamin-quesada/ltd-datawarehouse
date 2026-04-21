SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [fin].[eam_value_on_hand] (@startPeriod date, @endPeriod date)
AS
BEGIN
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


	SELECT
		v.prd_product_category, v.prd_product_category_descripton, CAST(v.date AS DATE) [date], v.value_on_hand
	FROM
		[ltd-eam].ltd_db.dbo.value_on_hand_by_gl_number_and_date v
	WHERE
	DAY(CAST(v.date AS DATE)) = 1 
	AND CAST(v.date AS DATE) >= @startPeriod
	AND CAST(v.date AS DATE) <= @endPeriod

END
GO
