SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [hastus].[merge_avl_crw]
as
/*-----------LTD_GLOSSARY---------------
created by	:  B Eichberger
created dt	:  2026-03-19
purpose		:  merge hastus avl files for crw
use			:  exec hastus.merge_avl_crw

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


drop table if exists #crw_setup;
drop table if exists #prep_merge;
  with CategorizedRows as (
    select 
        ID,
        RawLine,filedate,
        -- Identify if this row is a Parent
        case when RawLine like 'CSC%' then ID else null end as ParentGroupID
    from hastus.avl_crw_raw
)
,
LinkedRows as (
    select 
        ID,
        RawLine,filedate,
        -- "Fill down" the ParentGroupID to all rows below it until the next PAT
        max(ParentGroupID) over (order by ID rows between unbounded preceding and current row) as EffectiveParentID
    from CategorizedRows
)

-- Final view: Filters out the PAT rows and shows TPS rows with their Parent ID
select 
    EffectiveParentID as ParentRowID, l.id, c.RawLine, l.filedate, c.ParentGroupID,l.RawLine as crw_Data
into #crw_setup
from LinkedRows l
join CategorizedRows c on c.id = l.EffectiveParentID
where l.RawLine like 'PCE%'
order by 1,2;

--select * from #crw_setup
--
select filedate,id as file_row_id
,rtrim(ltrim(substring(RawLine,charindex(';',rawline)+1,8))) as csc_name 
,rtrim(ltrim(substring(RawLine,charindex(';',rawline)+10,10))) as csc_sched_type
,rtrim(ltrim(substring(RawLine,charindex(';',RawLine)+21,2))) as csc_sched_type2
,rtrim(ltrim(substring(RawLine,charindex(';',RawLine)+24,2))) as csc_scenario
,rtrim(ltrim(substring(RawLine,charindex(';',RawLine)+27,10))) as csc_booking
,rtrim(ltrim(substring(RawLine,charindex(';',RawLine)+38,8))) as csc_sched_unit
,rtrim(ltrim(substring(RawLine,charindex(';',RawLine)+47,80))) as csc_description
,rtrim(ltrim(substring(crw_data,charindex(';',crw_data)+1,8))) as pce_duty_id
,rtrim(ltrim(substring(crw_data,charindex(';',crw_data)+10,10))) as pce_duty_id2
,rtrim(ltrim(substring(crw_data,charindex(';',crw_data)+21,7))) as dty_oper_days_12
,rtrim(ltrim(substring(crw_data,charindex(';',crw_data)+29,10))) as blk_int_number
,rtrim(ltrim(substring(crw_data,charindex(';',crw_data)+40,5))) as pce_position
,rtrim(ltrim(substring(crw_data,charindex(';',crw_data)+46,6))) as pce_report_place
,rtrim(ltrim(substring(crw_data,charindex(';',crw_data)+53,5))) as pce_time_start
,rtrim(ltrim(substring(crw_data,charindex(';',crw_data)+59,6))) as pce_place_end
,rtrim(ltrim(substring(crw_data,charindex(';',crw_data)+66,5))) as pce_time_end
,rtrim(ltrim(substring(crw_data,charindex(';',crw_data)+72,6))) as pce_clear_place
,rtrim(ltrim(substring(crw_data,charindex(';',crw_data)+79,5))) as pce_clear_time
,rtrim(ltrim(substring(crw_data,charindex(';',crw_data)+102,10))) as pce_internal_no
into #prep_merge
from #crw_setup


merge -- truncate table -- select * from 
[hastus].[avl_crw] t 
using #prep_merge s on (
    t.filedate = s.filedate
and t.file_row_id = s.file_row_id
and t.[csc_name] = s.[csc_name]
and t.[pce_duty_id] = s.[pce_duty_id]
and t.[pce_position] = s.[pce_position]
)
when matched and 
(  isnull(t.[csc_sched_type],'') <> isnull(s.[csc_sched_type],'')
or isnull(t.[csc_scenario],'') <> isnull(s.[csc_scenario],'')
or isnull(t.[csc_booking],'') <> isnull(s.[csc_booking],'')
or isnull(t.[csc_sched_unit],'') <> isnull(s.[csc_sched_unit],'')
or isnull(t.[dty_oper_days_12],'') <> isnull(s.[dty_oper_days_12],'')
or isnull(t.[blk_int_number],'') <> isnull(s.[blk_int_number],'')
or isnull(t.[csc_sched_type2],'') <> isnull(s.[csc_sched_type2],'')
or isnull(t.[csc_description],'') <> isnull(s.[csc_description],'')
or isnull(t.[pce_duty_id2],'') <> isnull(s.[pce_duty_id2],'')
or isnull(t.[pce_report_place],'') <> isnull(s.[pce_report_place],'')
or isnull(t.[pce_time_start],'') <> isnull(s.[pce_time_start],'')
or isnull(t.[pce_place_end],'') <> isnull(s.[pce_place_end],'')
or isnull(t.[pce_time_end],'') <> isnull(s.[pce_time_end],'')
or isnull(t.[pce_clear_place],'') <> isnull(s.[pce_clear_place],'')
or isnull(t.[pce_clear_time],'') <> isnull(s.[pce_clear_time],'')
or isnull(t.[pce_internal_no],'') <> isnull(s.[pce_internal_no],'')
)
then update set
 t.[csc_sched_type2] = s.[csc_sched_type2]
,t.[csc_description] = s.[csc_description]
,t.[pce_duty_id2] = s.[pce_duty_id2]
,t.[pce_report_place] = s.[pce_report_place]
,t.[pce_time_start] = s.[pce_time_start]
,t.[pce_place_end] = s.[pce_place_end]
,t.[pce_time_end] = s.[pce_time_end]
,t.[pce_clear_place] = s.[pce_clear_place]
,t.[pce_clear_time] = s.[pce_clear_time]
,t.[pce_internal_no] = s.[pce_internal_no]
,t.[record_updated_date] = sysdatetime()
when not matched
then insert (
filedate
,[file_row_id]
,[csc_name]
,[csc_sched_type]
,[csc_sched_type2]
,[csc_scenario]
,[csc_booking]
,[csc_sched_unit]
,[csc_description]
,[pce_duty_id]
,[pce_duty_id2]
,[dty_oper_days_12]
,[blk_int_number]
,[pce_position]
,[pce_report_place]
,[pce_time_start]
,[pce_place_end]
,[pce_time_end]
,[pce_clear_place]
,[pce_clear_time]
,[pce_internal_no]
)
values
( s.filedate
,s.[file_row_id]
,s.[csc_name]
,s.[csc_sched_type]
,s.[csc_sched_type2]
,s.[csc_scenario]
,s.[csc_booking]
,s.[csc_sched_unit]
,s.[csc_description]
,s.[pce_duty_id]
,s.[pce_duty_id2]
,s.[dty_oper_days_12]
,s.[blk_int_number]
,s.[pce_position]
,s.[pce_report_place]
,s.[pce_time_start]
,s.[pce_place_end]
,s.[pce_time_end]
,s.[pce_clear_place]
,s.[pce_clear_time]
,s.[pce_internal_no])
output $action into @outputTbl;

drop table if exists #crw_setup;
drop table if exists #prep_merge;


DECLARE @ins INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'INSERT')
DECLARE @upd INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'UPDATE')
DECLARE @del INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'DELETE')
DECLARE @prg varchar(90) = @@SERVERNAME + '.ltd_dw.hastus.merge_avl_crw ' --+ CAST(@allCount AS VARCHAR(12))

INSERT process.mergeLogs
([MergeCode]
           ,[ObjectDestination]
           ,[ObjectSource]
           ,[ObjectProgram]
           ,[recInsert]
           ,[recUpdate]
           ,[recDelete]
           ,[MergeBeginDatetime]
           ,[MergeEndDatetime])
SELECT 'CRW',
'ltd_dw.hastus.avl_crw',
'HASTUS',
@prg,
ISNULL(@ins,0) ,ISNULL(@upd,0),ISNULL(@del,0),
@sdt,
SYSDATETIME()


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
END CATCH;
GO
