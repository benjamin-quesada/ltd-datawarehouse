SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE procedure [apc].[merge_apc_survey_data]
as
/*********************************************
CREATED BY	: B Eichberger
CREATED ON	: 20250730
PURPOSE		: replace ssis troubled package dataflows with merge sproc


--truncate table apc.apc_survey_data
--truncate table apc.apc_survey_trips
*/
set nocount on

declare @SPROC VARCHAR(100)
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

BEGIN TRY

DECLARE @sdt DATETIME2 = SYSDATETIME()
DECLARE @outputTbl TABLE (actionNm VARCHAR(32));


if (select count(*) from apc.apc_survey_data_entry_raw) > 0
BEGIN
DROP TABLE IF exists #PrepData

select [survey_date]
      ,[rte_dir]
      ,[trip_end]
	  ,[stop]
	  ,case when isnumeric(stop) = 1 then replace(rtrim(left(stop,7)),' -','') else replace(rtrim(left(stop,8)),' -','') end stop_no
	  ,case when isnumeric(stop) = 1 then replace(substring(stop,8,99),' - ','') else ltrim(replace(substring(stop,9,99),'-','')) end  stop_nm
      ,[surveyor_badge_f]
      ,[surveyor_badge_m]
      ,[surveyor_badge_r]
      ,[initial_count]
      ,isnull([stop_seq],0) [stop_seq]
      ,max([time_f]) [time_f]
      ,max(case when ISNUMERIC(ons_f) = 0 then 0 else ons_f end) ons_f 
      ,max(case when ISNUMERIC([offs_f]) = 0 then 0 else [offs_f] end) [offs_f]
      ,[notes_f]
      ,max([time_m]) [time_m]
      ,max(case when ISNUMERIC([ons_m]) = 0 then 0 else [ons_m] end) [ons_m]
      ,max(case when ISNUMERIC([offs_m]) = 0 then 0 else [offs_m] end) [offs_m]
      ,[notes_m]
      ,max([time_r]) [time_r]
      ,max(case when ISNUMERIC([ons_r]) = 0 then 0 else [ons_r] end) [ons_r]
      ,max(case when ISNUMERIC([offs_r]) = 0 then 0 else [offs_r] end) [offs_r]
      ,[notes_r]
      ,[filesource] 
into -- select * from
#PrepData -- select *
  FROM [ltd_dw].[apc].[apc_survey_data_entry_raw]
 group by  [survey_date]
      ,[rte_dir]
      ,[trip_end]
	  ,[stop]
	  ,case when isnumeric(stop) = 1 then replace(rtrim(left(stop,7)),' -','') else replace(rtrim(left(stop,8)),' -','') end 
	  ,case when isnumeric(stop) = 1 then replace(substring(stop,8,99),' - ','') else ltrim(replace(substring(stop,9,99),'-','')) end  
      ,[bus]
      ,[surveyor_badge_f]
      ,[surveyor_badge_m]
      ,[surveyor_badge_r]
      ,[initial_count]
      ,isnull([stop_seq],0) 
      ,[notes_f]
      ,[notes_m]
      ,[notes_r]
      ,[filesource]

merge [apc].[apc_survey_data] t
using #PrepData s on
(s.[survey_date] = t.[survey_date]
      and s.[rte_dir] = t.[rte_dir]
      and s.[trip_end] = t.[trip_end]
	  and s.stop_no = t.stop_no
	  and s.stop_seq = t.stop_seq
	  )
when matched and 
(	     t.[stop_seq] <> isnull(s.[stop_seq],0)
      or t.[stop_no] <> isnull(s.[stop_no],'0')
      or t.[stop_nm] <> isnull(s.[stop_nm],'0')
      or t.[ons_f] <> isnull(s.[ons_f],0)
      or t.[offs_f] <> isnull(s.[offs_f],0)
      or t.[notes_f] <> isnull(s.[notes_f],'0')
      or t.[ons_m] <> isnull(s.[ons_m],0)
      or t.[offs_m] <> isnull(s.[offs_m],0)
      or t.[notes_m] <> isnull(s.[notes_m],'0')
      or t.[ons_r] <> isnull(s.[ons_r],0)
      or t.[offs_r] <> isnull(s.[offs_r],0)
      or t.[notes_r] <> isnull(s.[notes_r],'0')
      or t.[time_f] <> isnull(s.[time_f],'0')
      or t.[time_m] <> isnull(s.[time_m],'0')
      or t.[time_r] <> isnull(s.[time_r],'0')
      or t.[fileSource] <> isnull(s.[fileSource],'0'))
then update 
   set   t.[stop_seq] = s.[stop_seq]
      , t.[stop_no] = s.[stop_no]
      , t.[stop_nm] = s.[stop_nm]
      , t.[ons_f] = isnull(s.[ons_f],0)
      , t.[offs_f] = isnull(s.[offs_f],0)
      , t.[notes_f] = s.[notes_f]
      , t.[ons_m] = isnull(s.[ons_m],0)
      , t.[offs_m] = isnull(s.[offs_m],0)
      , t.[notes_m] = s.[notes_m]
      , t.[ons_r] = isnull(s.[ons_r],0)
      , t.[offs_r] = isnull(s.[offs_r],0)
      , t.[notes_r] = s.[notes_r]
      , t.[time_f] = s.[time_f]
      , t.[time_m] = s.[time_m]
      , t.[time_r] = s.[time_r]
      , t.[fileSource] = s.[fileSource]
when not matched by target then insert 
(
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
      ,[fileSource])
values (
s.[survey_date]
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
	  OUTPUT $action INTO @outputTbl;



DECLARE @ins INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'INSERT')
DECLARE @upd INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'UPDATE')
DECLARE @del INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'DELETE')
DECLARE @prg varchar(90) = @@SERVERNAME + '.ltd_dw.apc.merge_apc_survey_data'

INSERT PROCESS.mergeLogs
(		[MergeCode]
           ,[ObjectDestination]
           ,[ObjectSource]
           ,[ObjectProgram]
           ,[recInsert]
           ,[recUpdate]
           ,[recDelete]
           ,[MergeBeginDatetime]
           ,[MergeEndDatetime])
SELECT 'APCD',
'ltd_dw.apc.apc_survey_data',
'APC',
@prg,
ISNULL(@ins,0) ,ISNULL(@upd,0),ISNULL(@del,0),
@sdt,
SYSDATETIME()

END

END TRY	  

BEGIN CATCH

       DECLARE @profile VARCHAR(255) = (
                    SELECT [NAME]
                    FROM msdb.dbo.sysmail_profile
                    )
       DECLARE @errormsg VARCHAR(MAX)
             ,@error INT
             ,@message VARCHAR(MAX)
             ,@xstate INT
             ,@errsev INT
             ,@sub VARCHAR(255);

       SELECT @error = ERROR_NUMBER()
             ,@errsev = ERROR_SEVERITY()
             ,@message = ERROR_MESSAGE()
             ,@xstate = XACT_STATE();

       SELECT @errormsg = 'Error in ' + ISNULL(@SPROC, '') + ': ' + CAST(ISNULL(@error, '') AS NVARCHAR(32)) + '|' + COALESCE(@message, '') + '|' + CAST(ISNULL(@xstate, '') AS NVARCHAR(32)) + '|' +CAST(ISNULL(@errsev, '') AS NVARCHAR(32))

       SELECT @sub = 'ERROR: ' + @SPROC

       EXEC msdb.dbo.sp_send_dbmail @profile_name = @profile
             ,@recipients = 'data@ltd.org' 
             ,@subject = @sub
             ,@body = @errormsg;

       RAISERROR (
                    @errormsg
                    ,@errsev
                    ,1
                    )
END CATCH

GO
