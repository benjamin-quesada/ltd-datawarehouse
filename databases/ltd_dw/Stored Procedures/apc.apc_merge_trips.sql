SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   PROCEDURE [apc].[apc_merge_trips]

AS

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

SELECT [survey_date]
      ,UPPER([rte_dir]) [rte_dir]
      ,[trip_end]
      ,[bus]
,100000000 + cast(convert(varchar(32),survey_date,112) as INT) calendar_id
      ,[initial_count]
      ,[surveyor_badge_f]
      ,[surveyor_badge_m]
      ,[surveyor_badge_r]
      ,[fileSource]
INTO #tempTrips
from [ltd_dw].[apc].[apc_survey_data_entry_raw]
where rte_dir is not null and bus is not null
group by 
[survey_date]
      ,[rte_dir]
      ,[trip_end]
      ,[bus]
,100000000 + cast(convert(varchar(32),survey_date,112) as INT)
      ,[initial_count]
      ,[surveyor_badge_f]
      ,[surveyor_badge_m]
      ,[surveyor_badge_r]
      ,[fileSource]


MERGE apc.apc_survey_trips AS t
USING #tempTrips AS s
ON t.survey_date = s.survey_date
AND t.rte_dir = s.rte_dir
AND t.trip_end = s.trip_end
WHEN NOT MATCHED BY TARGET THEN
INSERT (
survey_date,
rte_dir,
trip_end,
bus,
initial_count,
surveyor_badge_f,
surveyor_badge_m,
surveyor_badge_r,
fileSource,
calendar_id
)
VALUES
(s.survey_date,
s.rte_dir,
s.trip_end,
s.bus,
s.initial_count,
s.surveyor_badge_f,
s.surveyor_badge_m,
s.surveyor_badge_r,
s.fileSource,
s.calendar_id)
WHEN MATCHED AND (
  	ISNULL(t.bus,'') <> isnull(s.bus,'')
OR	ISNULL(t.initial_count,'') <> isnull(s.initial_count,0)
OR	ISNULL(t.surveyor_badge_f,'') <> isnull(s.surveyor_badge_f,'')
OR	ISNULL(t.surveyor_badge_m,'') <> isnull(s.surveyor_badge_m,'')
OR	ISNULL(t.surveyor_badge_r,'') <> isnull(s.surveyor_badge_r,'')
OR	ISNULL(t.fileSource,'') <> isnull(s.fileSource,'')
OR	ISNULL(t.calendar_id,'') <> isnull(s.calendar_id,'')
)
THEN UPDATE 
SET t.bus = isnull(s.bus,'')
,	t.initial_count = isnull(s.initial_count,0)
,	t.surveyor_badge_f = isnull(s.surveyor_badge_f,'')
,	t.surveyor_badge_m = isnull(s.surveyor_badge_m,'')
,	t.surveyor_badge_r = isnull(s.surveyor_badge_r,'')
,	t.fileSource = isnull(s.fileSource,'')
,	t.calendar_id = isnull(s.calendar_id,'')


 ;
  
GO
