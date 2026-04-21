SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   PROCEDURE [his].[VEHICLE_HISTORY]
@vehNbr VARCHAR(50)

AS
/*
CREATED DT	: 20240927
CREATED BY	: B. Eichberger
PURPOSE		: Life Cycle Events by Bus

USE			: exec his.VEHICLE_HISTORY '1107'

------------------LTD_GLOSSARY---------------
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


WITH all_meters AS (
SELECT [label_name], 1 AS mile_group
      ,[the_date]
      ,[meter_value]
      ,[eq_equip_no]
  FROM [ltd_dw].[eam].[EAM_ALL_MILE_ACTIVITY]
  WHERE eq_equip_no = @vehNbr
  AND the_date >= '7/1/2017'
  UNION ALL
  SELECT label_name, 2
		,the_date
		,miles_value
		,eq_equip_no  
	FROM tm.ALL_MILE_ACTIVITY 
  WHERE eq_equip_no = @vehNbr
  AND the_date >= '7/1/2017'
  )
,min_max AS (SELECT MIN(the_date) minDt,max(the_date) maxDt FROM all_meters)

SELECT rn = DENSE_RANK() OVER (PARTITION BY i.eq_equip_no ORDER BY the_date)
, the_date, i.last_date
,DATEDIFF(DAY,minDt,the_date) dtf
,[meter_value],i.mile_group
,REPLICATE('g',DATEDIFF(DAY,minDt,the_date)*.1)+' ' distance_from_start
,i.label_name 
FROM (
SELECT DISTINCT q.label_name, q.the_date, q.meter_value, q.eq_equip_no 
,last_date = LAG(q.the_date) OVER (ORDER BY q.the_date),m.minDt,q.mile_group
FROM all_meters  q
CROSS JOIN min_max m 
  ) i
 WHERE i.the_date IS NOT NULL 
GO
