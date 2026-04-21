SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [hastus].[merge_avl_pat]
as
/*-----------LTD_GLOSSARY---------------
created by	:  B Eichberger
created dt	:  2026-03-19
purpose		:  merge hastus avl files for pat
use			:  exec hastus.merge_avl_pat

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




drop table if exists #pat_setup;
  WITH CategorizedRows AS (
    SELECT 
        ID,
        RawLine,
        filedate,
        -- Identify if this row is a Parent
        CASE WHEN RawLine LIKE 'PAT%' THEN ID ELSE NULL END AS ParentGroupID
    from hastus.avl_pat_raw
)
,LinkedRows as (
    select 
        ID,
        filedate,
        RawLine,
        -- "Fill down" the ParentGroupID to all rows below it until the next PAT
        max(ParentGroupID) over (ORDER BY ID ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS EffectiveParentID
    FROM CategorizedRows
    
)

-- Final view: Filters out the PAT rows and shows TPS rows with their Parent ID
SELECT 
    EffectiveParentID AS ParentRowID, l.id,l.filedate
                                   , c.RawLine
                                   , c.ParentGroupID,
    l.RawLine AS pat_Data
into #pat_setup
from LinkedRows l
join CategorizedRows c on c.id = l.EffectiveParentID
WHERE l.RawLine LIKE 'TPS%'
order by c.id

drop table if exists #prep_merge
--
SELECT filedate,id as file_row_id
,rtrim(ltrim(substring(RawLine,charindex(';',rawline)+1,5))) as tpat_route 
,rtrim(ltrim(substring(RawLine,charindex(';',rawline)+7,4))) as tpat_external_id
,rtrim(ltrim(substring(RawLine,charindex(';',RawLine)+12,10))) as tpat_direction
,rtrim(ltrim(substring(RawLine,charindex(';',RawLine)+23,2))) as tpat_direction2
,rtrim(ltrim(substring(RawLine,charindex(';',RawLine)+26,8))) as tpat_veh_display
,rtrim(ltrim(substring(RawLine,charindex(';',RawLine)+35,1))) as tpat_in_serv
,rtrim(ltrim(substring(RawLine,charindex(';',RawLine)+37,8))) as tpat_via
,rtrim(ltrim(substring(RawLine,charindex(';',RawLine)+46,40))) as via_desc
,rtrim(ltrim(substring(pat_Data,charindex(';',pat_Data)+1,8))) as tpatpt_stop_id 
,rtrim(ltrim(substring(pat_Data,charindex(';',pat_Data)+10,6))) as tpatpt_load_place 
,rtrim(ltrim(substring(pat_Data,charindex(';',pat_Data)+17,8))) as tpatpt_veh_display_code 
,rtrim(ltrim(substring(pat_Data,charindex(';',pat_Data)+26,1))) as tpatpt_is_timing_point   -- select * 
into #prep_merge
from #pat_setup


merge hastus.avl_pat t
using #prep_merge s on 
(
t.[filedate] = s.filedate and
t.file_row_id = s.file_row_id and
t.tpat_route = s.tpat_route and
t.tpat_direction = s.tpat_direction and
t.tpat_in_serv = s.tpat_in_serv and
t.tpat_via = s.tpat_via and
t.tpat_external_id = s.tpat_external_id and 
t.via_desc = s.via_desc and
t.tpatpt_stop_id = s.tpatpt_stop_id

)
when matched and 
(
   isnull(t.[tpat_direction2],'') <> isnull(s.[tpat_direction2],'')
OR isnull(t.[tpat_veh_display],'') <> isnull(s.[tpat_veh_display],'')
OR isnull(t.[tpatpt_load_place],'') <> isnull(s.[tpatpt_load_place],'')
OR isnull(t.[tpatpt_veh_display_code],'') <> isnull(s.[tpatpt_veh_display_code],'')
OR isnull(t.[tpatpt_is_timing_point],'') <> isnull(s.[tpatpt_is_timing_point],'')
)
then update set
 t.[tpat_direction2] = s.[tpat_direction2]
,t.[tpat_veh_display] = s.[tpat_veh_display]
,t.[tpatpt_load_place] = s.[tpatpt_load_place]
,t.[tpatpt_veh_display_code] = s.[tpatpt_veh_display_code]
,t.[tpatpt_is_timing_point] = s.[tpatpt_is_timing_point]
,t.[record_updated_date] = sysdatetime()
when not matched then insert    
(	[filedate]
,	[file_row_id]
,	[tpat_route]
,	[tpat_external_id]
,	[tpat_direction]
,	[tpat_direction2]
,	[tpat_veh_display]
,	[tpat_in_serv]
,	[tpat_via]
,	[via_desc]
,	[tpatpt_stop_id]
,	[tpatpt_load_place]
,	[tpatpt_veh_display_code]
,	[tpatpt_is_timing_point])
values (
 s.[filedate]
,s.[file_row_id]
,s.[tpat_route]
,s.[tpat_external_id]
,s.[tpat_direction]
,s.[tpat_direction2]
,s.[tpat_veh_display]
,s.[tpat_in_serv]
,s.[tpat_via]
,s.[via_desc]
,s.[tpatpt_stop_id]
,s.[tpatpt_load_place]
,s.[tpatpt_veh_display_code]
,s.[tpatpt_is_timing_point])
output $action into @outputTbl;


drop table if exists #pat_setup
drop table if exists #prep_merge

DECLARE @ins INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'INSERT')
DECLARE @upd INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'UPDATE')
DECLARE @del INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'DELETE')
DECLARE @prg varchar(90) = @@SERVERNAME + '.ltd_dw.hastus.merge_avl_pat ' --+ CAST(@allCount AS VARCHAR(12))

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
SELECT 'PAT',
'ltd_dw.hastus.avl_pat',
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
