SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [hastus].[merge_avl_blk]
as
/*-----------LTD_GLOSSARY---------------
created by	:  B Eichberger
created dt	:  2026-03-19
purpose		:  merge hastus avl files for blk
use			:  exec hastus.merge_avl_blk

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


drop table if exists #blk_setup;
drop table if exists #LinkedRows
drop table if exists #blk_setup1;
drop table if exists #blk_setup2;
drop table if exists #blk_final;
drop table if exists #prep_merge;
  WITH CategorizedRows AS (
    SELECT 
        ID,
        RawLine,filedate,
        -- Identify if this row is a Parent
        CASE WHEN RawLine LIKE 'VSC%' then ID ELSE NULL END AS ParentGroupID
    from hastus.avl_blk_raw
    
)
    select 
        ID,
        RawLine,filedate,
        -- "Fill down" the ParentGroupID to all rows below it until the next PAT
        max(ParentGroupID) over (ORDER BY ID ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS EffectiveParentID
    into #blk_setup1
    from CategorizedRows
    order by id

    SELECT 
        ID,
        RawLine,filedate,
        EffectiveParentID VSCGroupId,
        -- Identify if this row is a Parent
        CASE WHEN RawLine LIKE 'BLK%' then ID ELSE NULL END AS ParentGroupID
        into #blk_setup2 -- select * 
    from #blk_setup1
    order by id


    select  
        ID,
        VSCGroupId,
        RawLine,filedate,
        --ParentGroupID,
        -- "Fill down" the ParentGroupID to all rows below it until the next BLK
        max(ParentGroupID) over (ORDER BY ID ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS EffectiveParentID
    into #linkedRows 
    from #blk_setup2 
    order by id

select 
    b.RawLine as vsc_raw,
    c.RawLine as blk_raw,
    l.id
  , l.VSCGroupId
  , b.filedate
  , l.RawLine
  , l.EffectiveParentID
into #blk_final
from #linkedRows l
join #blk_setup1 c on c.id = l.EffectiveParentID
join #blk_setup2 b on b.id = c.EffectiveParentID
where l.RawLine like 'TIN%'
order by id;-- select * from #blk_final order by id
--
SELECT filedate,id as file_row_id
,rtrim(ltrim(substring(vsc_raw,charindex(';',vsc_raw)+1,8))) as vsc_name
,rtrim(ltrim(substring(vsc_raw,charindex(';',vsc_raw)+10,10))) as vsc_sched_type
,rtrim(ltrim(substring(vsc_raw,charindex(';',vsc_raw)+21,2))) as vsc_sched_type2
,rtrim(ltrim(substring(vsc_raw,charindex(';',vsc_raw)+24,2))) as vsc_scenario
,rtrim(ltrim(substring(vsc_raw,charindex(';',vsc_raw)+27,10))) as vsc_booking
,rtrim(ltrim(substring(vsc_raw,charindex(';',vsc_raw)+38,8))) as vsc_sched_unit
,rtrim(ltrim(substring(vsc_raw,charindex(';',vsc_raw)+47,80))) as vsc_description
,rtrim(ltrim(substring(blk_raw,charindex(';',blk_raw)+1,8))) as blk_number
,rtrim(ltrim(substring(blk_raw,charindex(';',blk_raw)+10,10))) as blk_int_number
,rtrim(ltrim(substring(blk_raw,charindex(';',blk_raw)+21,7))) as blk_oper_days_12
,rtrim(ltrim(substring(blk_raw,charindex(';',blk_raw)+29,6))) as blk_place_start
,rtrim(ltrim(substring(blk_raw,charindex(';',blk_raw)+36,5))) as blk_strt_tim_npt
,rtrim(ltrim(substring(blk_raw,charindex(';',blk_raw)+42,6))) as blk_plc_strt_no_pull
,rtrim(ltrim(substring(blk_raw,charindex(';',blk_raw)+49,5))) as blk_strt_prd_tim
,rtrim(ltrim(substring(blk_raw,charindex(';',blk_raw)+55,6))) as blk_plc_end_no_pull
,rtrim(ltrim(substring(blk_raw,charindex(';',blk_raw)+62,5))) as blk_end_prd_tim
,rtrim(ltrim(substring(blk_raw,charindex(';',blk_raw)+68,6))) as blk_place_end
,rtrim(ltrim(substring(blk_raw,charindex(';',blk_raw)+75,5))) as blk_end_tim_npt
,rtrim(ltrim(substring(blk_raw,charindex(';',blk_raw)+81,4))) as blk_vehicle_group
,rtrim(ltrim(substring(blk_raw,charindex(';',blk_raw)+86,4))) as blk_vehicle_type
,rtrim(ltrim(substring(blk_raw,charindex(';',blk_raw)+91,5))) as blk_time_start
,rtrim(ltrim(substring(blk_raw,charindex(';',blk_raw)+97,5))) as blk_time_end
,rtrim(ltrim(substring(rawline,charindex(';',rawline)+1,10))) as trp_int_number
into #prep_merge
from #blk_final
order by id

merge -- truncate table -- select * from 
[hastus].[avl_blk] t 
using #prep_merge s on (
    t.filedate = s.filedate
and t.file_row_id = s.file_row_id
)
when matched and (
   isnull(t.vsc_name,'') <> isnull(s.vsc_name,'')
OR isnull(t.vsc_scenario,'') <> isnull(s.vsc_scenario,'')
OR isnull(t.vsc_booking,'') <> isnull(s.vsc_booking,'')
OR isnull(t.blk_number,'') <> isnull(s.blk_number,'')
OR isnull(t.vsc_sched_type,'') <> isnull(s.vsc_sched_type,'')
OR isnull(t.vsc_sched_type2,'') <> isnull(s.vsc_sched_type2,'')
OR isnull(t.vsc_sched_unit,'') <> isnull(s.vsc_sched_unit,'')
OR isnull(t.vsc_description,'') <> isnull(s.vsc_description,'')
OR isnull(t.blk_int_number,'') <> isnull(s.blk_int_number,'')
OR isnull(t.blk_oper_days_12,'') <> isnull(s.blk_oper_days_12,'')
OR isnull(t.blk_place_start,'') <> isnull(s.blk_place_start,'')
OR isnull(t.blk_strt_tim_npt,'') <> isnull(s.blk_strt_tim_npt,'')
OR isnull(t.blk_plc_strt_no_pull,'') <> isnull(s.blk_plc_strt_no_pull,'')
OR isnull(t.blk_strt_prd_tim,'') <> isnull(s.blk_strt_prd_tim,'')
OR isnull(t.blk_plc_end_no_pull,'') <> isnull(s.blk_plc_end_no_pull,'')
OR isnull(t.blk_end_prd_tim,'') <> isnull(s.blk_end_prd_tim,'')
OR isnull(t.blk_place_end,'') <> isnull(s.blk_place_end,'')
OR isnull(t.blk_end_tim_npt,'') <> isnull(s.blk_end_tim_npt,'')
OR isnull(t.blk_vehicle_group,'') <> isnull(s.blk_vehicle_group,'')
OR isnull(t.blk_vehicle_type,'') <> isnull(s.blk_vehicle_type,'')
OR isnull(t.blk_time_start,'') <> isnull(s.blk_time_start,'')
OR isnull(t.blk_time_end,'') <> isnull(s.blk_time_end,'')
OR isnull(t.trp_int_number,'') <> isnull(s.trp_int_number,'')
)
then update set
 t.vsc_name = s.vsc_name
,t.vsc_scenario = s.vsc_scenario
,t.vsc_booking = s.vsc_booking
,t.blk_number = s.blk_number
,t.vsc_sched_type = s.vsc_sched_type
,t.vsc_sched_type2 = s.vsc_sched_type2
,t.vsc_sched_unit = s.vsc_sched_unit
,t.vsc_description = s.vsc_description
,t.blk_int_number = s.blk_int_number
,t.blk_oper_days_12 = s.blk_oper_days_12
,t.blk_place_start = s.blk_place_start
,t.blk_strt_tim_npt = s.blk_strt_tim_npt
,t.blk_plc_strt_no_pull = s.blk_plc_strt_no_pull
,t.blk_strt_prd_tim = s.blk_strt_prd_tim
,t.blk_plc_end_no_pull = s.blk_plc_end_no_pull
,t.blk_end_prd_tim = s.blk_end_prd_tim
,t.blk_place_end = s.blk_place_end
,t.blk_end_tim_npt = s.blk_end_tim_npt
,t.blk_vehicle_group = s.blk_vehicle_group
,t.blk_vehicle_type = s.blk_vehicle_type
,t.blk_time_start = s.blk_time_start
,t.blk_time_end = s.blk_time_end
,t.trp_int_number = s.trp_int_number
,t.record_updated_date = sysdatetime()    
when not matched by target then insert
(
filedate
,file_row_id
,vsc_name
,vsc_sched_type
,vsc_sched_type2
,vsc_scenario
,vsc_booking
,vsc_sched_unit
,vsc_description
,blk_number
,blk_int_number
,blk_oper_days_12
,blk_place_start
,blk_strt_tim_npt
,blk_plc_strt_no_pull
,blk_strt_prd_tim
,blk_plc_end_no_pull
,blk_end_prd_tim
,blk_place_end
,blk_end_tim_npt
,blk_vehicle_group
,blk_vehicle_type
,blk_time_start
,blk_time_end
,trp_int_number

)
values (
 s.filedate
,s.file_row_id
,s.vsc_name
,s.vsc_sched_type
,s.vsc_sched_type2
,s.vsc_scenario
,s.vsc_booking
,s.vsc_sched_unit
,s.vsc_description
,s.blk_number
,s.blk_int_number
,s.blk_oper_days_12
,s.blk_place_start
,s.blk_strt_tim_npt
,s.blk_plc_strt_no_pull
,s.blk_strt_prd_tim
,s.blk_plc_end_no_pull
,s.blk_end_prd_tim
,s.blk_place_end
,s.blk_end_tim_npt
,s.blk_vehicle_group
,s.blk_vehicle_type
,s.blk_time_start
,s.blk_time_end
,s.trp_int_number
 )
output $action into @outputTbl;


DECLARE @ins INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'INSERT')
DECLARE @upd INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'UPDATE')
DECLARE @del INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'DELETE')
DECLARE @prg varchar(90) = @@SERVERNAME + '.ltd_dw.hastus.merge_avl_blk ' --+ CAST(@allCount AS VARCHAR(12))

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
SELECT 'BLK',
'ltd_dw.hastus.avl_blk',
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
