SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   PROCEDURE [apc].[apc_merge_data]

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

SELECT distinct [survey_date]
      ,[rte_dir]
      ,[trip_end]
	  ,[stop]
	  ,case when isnumeric(stop) = 1 then replace(rtrim(left(stop,7)),' -','') else replace(rtrim(left(stop,8)),' -','') end stop_no
	  ,case when isnumeric(stop) = 1 then replace(substring(stop,8,99),' - ','') else LTRIM(replace(substring(stop,9,99),'-','')) end  stop_nm
      ,[bus]
      ,[surveyor_badge_f]
      ,[surveyor_badge_m]
      ,[surveyor_badge_r]
      ,[initial_count]
      ,isnull([stop_seq],0) [stop_seq]
      ,[time_f]
      ,case when ISNUMERIC(ons_f) = 0 then 0 else ons_f end ons_f 
      ,case when ISNUMERIC([offs_f]) = 0 then 0 else [offs_f] end [offs_f]
      ,[notes_f]
      ,[time_m]
      ,case when ISNUMERIC([ons_m]) = 0 then 0 else [ons_m] end [ons_m]
      ,case when ISNUMERIC([offs_m]) = 0 then 0 else [offs_m] end [offs_m]
      ,[notes_m]
      ,[time_r]
      ,case when ISNUMERIC([ons_r]) = 0 then 0 else [ons_r] end [ons_r]
      ,case when ISNUMERIC([offs_r]) = 0 then 0 else [offs_r] end [offs_r]
      ,[notes_r]
      ,[filesource]
INTO #tempTripData
  FROM [ltd_dw].[apc].[apc_survey_data_entry_raw]

MERGE apc.apc_survey_data AS t
USING #tempTripData AS s
ON t.survey_date = s.survey_date
AND t.rte_dir = s.rte_dir
AND t.[stop_no] = s.[stop_no]
AND t.[stop_nm] = s.[stop_nm]
AND t.trip_end = s.trip_end
WHEN NOT MATCHED BY TARGET THEN
INSERT (
[survey_date]
      ,[rte_dir]
      ,[trip_end]
      ,[stop_seq]
      ,[stop_no]
      ,[stop_nm]
      ,[ons_f]
      ,[offs_f]
      ,[notes_f]
      ,[ons_m]
      ,[offs_m]
      ,[notes_m]
      ,[ons_r]
      ,[offs_r]
      ,[notes_r]
      ,[time_f]
      ,[time_m]
      ,[time_r]
      ,[fileSource]
)
VALUES
(s.[survey_date]
      ,s.[rte_dir]
      ,s.[trip_end]
      ,s.[stop_seq]
      ,s.[stop_no]
      ,s.[stop_nm]
      ,s.[ons_f]
      ,s.[offs_f]
      ,s.[notes_f]
      ,s.[ons_m]
      ,s.[offs_m]
      ,s.[notes_m]
      ,s.[ons_r]
      ,s.[offs_r]
      ,s.[notes_r]
      ,s.[time_f]
      ,s.[time_m]
      ,s.[time_r]
      ,s.[fileSource])
WHEN MATCHED AND (
  	ISNULL(t.[stop_seq],'') <> isnull(s.[stop_seq],'')
OR ISNULL(t.[ons_f],0) <> isnull(s.[ons_f],0)
OR ISNULL(t.[offs_f],0) <> isnull(s.[offs_f],0)
OR ISNULL(t.[notes_f],0) <> isnull(s.[notes_f],0)
OR ISNULL(t.[ons_m],0) <> isnull(s.[ons_m],0)
OR ISNULL(t.[offs_m],0) <> isnull(s.[offs_m],0)
OR ISNULL(t.[notes_m],0) <> isnull(s.[notes_m],0)
OR ISNULL(t.[ons_r],0) <> isnull(s.[ons_r],0)
OR ISNULL(t.[offs_r],0) <> isnull(s.[offs_r],0)
OR ISNULL(t.[notes_r],'') <> isnull(s.[notes_r],'')
OR ISNULL(t.[time_f],'') <> isnull(s.[time_f],'')
OR ISNULL(t.[time_m],'') <> isnull(s.[time_m],'')
OR ISNULL(t.[time_r],'') <> isnull(s.[time_r],'')
OR ISNULL(t.[fileSource],'') <> isnull(s.[fileSource],'')

)
THEN UPDATE 
SET	t.[stop_seq] = isnull(s.[stop_seq],'')
,t.[ons_f] = isnull(s.[ons_f],0)
,t.[offs_f] = isnull(s.[offs_f],0)
,t.[notes_f] = isnull(s.[notes_f],0)
,t.[ons_m] = isnull(s.[ons_m],0)
,t.[offs_m] = isnull(s.[offs_m],0)
,t.[notes_m] = isnull(s.[notes_m],0)
,t.[ons_r] = isnull(s.[ons_r],0)
,t.[offs_r] = isnull(s.[offs_r],0)
,t.[notes_r] = isnull(s.[notes_r],'')
,t.[time_f] = isnull(s.[time_f],'')
,t.[time_m] = isnull(s.[time_m],'')
,t.[time_r] = isnull(s.[time_r],'')
,t.[fileSource] = isnull(s.[fileSource],'')
;

SELECT	MAX(inserted_datetime) inserted_datetime
	   ,[survey_date]
	   ,[rte_dir]
	   ,[trip_end]
	   ,[stop_seq]
	   ,[stop_no]
	   ,[stop_nm]
	   ,[ons_f]
	   ,[offs_f]
	   ,[notes_f]
	   ,[ons_m]
	   ,[offs_m]
	   ,[notes_m]
	   ,[ons_r]
	   ,[offs_r]
	   ,[notes_r]
	   ,[time_f]
	   ,[time_m]
	   ,[time_r]
	   ,[fileSource]
INTO	#tempDedupe
FROM	[ltd_dw].[apc].[apc_survey_data]
GROUP BY [survey_date]
		,[rte_dir]
		,[trip_end]
		,[stop_seq]
		,[stop_no]
		,[stop_nm]
		,[ons_f]
		,[offs_f]
		,[notes_f]
		,[ons_m]
		,[offs_m]
		,[notes_m]
		,[ons_r]
		,[offs_r]
		,[notes_r]
		,[time_f]
		,[time_m]
		,[time_r]
		,[fileSource] ;

TRUNCATE TABLE [apc].[apc_survey_data] ;

INSERT	apc.apc_survey_data
(inserted_datetime, survey_date, rte_dir, trip_end, stop_seq, stop_no, stop_nm, ons_f, offs_f, notes_f, ons_m, offs_m, notes_m, ons_r, offs_r, notes_r, time_f, time_m, time_r, fileSource)
SELECT	inserted_datetime
	   ,survey_date
	   ,rte_dir
	   ,trip_end
	   ,stop_seq
	   ,stop_no
	   ,stop_nm
	   ,ons_f
	   ,offs_f
	   ,notes_f
	   ,ons_m
	   ,offs_m
	   ,notes_m
	   ,ons_r
	   ,offs_r
	   ,notes_r
	   ,time_f
	   ,time_m
	   ,time_r
	   ,fileSource
FROM	#tempDedupe 
 ;
  
  
UPDATE apc.apc_survey_data SET fileSource = REPLACE(REPLACE(filesource,
'\\ltd-glnfas2\Workgroup\SP&M\APC_Survey\2023\SurveyData2023\',''),'.xlsx','')


UPDATE apc.apc_survey_trips SET fileSource = REPLACE(REPLACE(filesource,
'\\ltd-glnfas2\Workgroup\SP&M\APC_Survey\2023\SurveyData2023\',''),'.xlsx','')

END
GO
