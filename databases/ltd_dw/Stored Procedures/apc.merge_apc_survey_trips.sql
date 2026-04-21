SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE procedure [apc].[merge_apc_survey_trips]
as
/*********************************************
CREATED BY	: B Eichberger
CREATED ON	: 20250730
PURPOSE		: replace ssis troubled package dataflows with merge sproc
			  


*/
set nocount on

declare @SPROC varchar(100)
set @SPROC = object_schema_name(@@procid) + '.' + object_name(@@procid)

insert into DBA.[aud].[Object_Activity]
	([server_name], [database_name] ,[host_name], [System_User], [object_name]
	,[client_net_address], [local_net_address], [auth_Scheme], [last_read], [last_write]
	,[most_recent_sql_handle], [Timestamp], object_type)
select distinct @@servername, db_name(),host_name(),system_user, @SPROC,
	client_net_address, local_net_address , auth_Scheme, last_read, last_write 
	,most_recent_sql_handle, current_timestamp as [Timestamp], 'PROC'
from sys.dm_exec_connections 
where session_id = @@spid ;

begin try

declare @sdt datetime2 = sysdatetime()
declare @outputTbl table (actionNm varchar(32));


if (select count(*) from apc.apc_survey_data_entry_raw) > 0
BEGIN
drop table if exists #PrepTRIP

select distinct [survey_date]
      ,UPPER([rte_dir]) [rte_dir]
      ,[trip_end]
      ,[bus]
	  ,100000000 + cast(convert(varchar(32),survey_date,112) as INT) calendar_id
      ,[initial_count]
      ,[surveyor_badge_f]
      ,[surveyor_badge_m]
      ,[surveyor_badge_r]
      ,[fileSource]
into #PrepTRIP -- select * 
from [ltd_dw].[apc].[apc_survey_data_entry_raw]
where rte_dir is not null and bus is not null
group by 
[survey_date]
      ,[rte_dir]
      ,[trip_end]
      ,[bus]
	  ,100000000 + cast(convert(varchar(32),survey_date,112) as int)
      ,[initial_count]
      ,[surveyor_badge_f]
      ,[surveyor_badge_m]
      ,[surveyor_badge_r]
      ,[fileSource]

merge [apc].[apc_survey_trips] t
using #PrepTRIP s on
(s.[survey_date] = t.[survey_date]
      and s.[rte_dir] = t.[rte_dir]
      and s.[trip_end] = t.[trip_end])
when matched and 
(	     t.[bus] <> ISNULL(s.bus,'0')
	  or t.calendar_id <> ISNULL(s.calendar_id,'0')
      OR t.[initial_count] <> ISNULL(s.[initial_count],0)
      OR t.[surveyor_badge_f] <> ISNULL(s.[surveyor_badge_f],'0')
      OR t.[surveyor_badge_m] <> ISNULL(s.[surveyor_badge_m],'0')
      OR t.[surveyor_badge_r] <> ISNULL(s.[surveyor_badge_r],'0')
      OR t.[fileSource] <> s.[fileSource])
then UPDATE 
   SET t.[bus] = s.[bus]
      ,t.[initial_count] = s.[initial_count]
      ,t.[surveyor_badge_f] = s.[surveyor_badge_f]
      ,t.[surveyor_badge_m] = s.[surveyor_badge_m]
      ,t.[surveyor_badge_r] = s.[surveyor_badge_r]
      ,t.[fileSource] = s.[fileSource]
      ,t.[calendar_id] = s.[calendar_id]
when not matched by target then insert 
(
[survey_date]
,[rte_dir]
,[trip_end]
,[bus]
,[initial_count]
,[surveyor_badge_f]
,[surveyor_badge_m]
,[surveyor_badge_r]
,[fileSource]
,[calendar_id])
values (
s.[survey_date]
      ,s.[rte_dir]
      ,s.[trip_end]
      ,s.[bus]
      ,s.[initial_count]
      ,s.[surveyor_badge_f]
      ,s.[surveyor_badge_m]
      ,s.[surveyor_badge_r]
      ,s.[fileSource]
      ,s.[calendar_id])
	  OUTPUT $action INTO @outputTbl;



DECLARE @ins INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'INSERT')
DECLARE @upd INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'UPDATE')
DECLARE @del INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'DELETE')
DECLARE @prg varchar(90) = @@SERVERNAME + '.ltd_dw.apc.merge_apc_survey_trips'

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
SELECT 'APCT',
'ltd_dw.apc.apc_survey_trips',
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
