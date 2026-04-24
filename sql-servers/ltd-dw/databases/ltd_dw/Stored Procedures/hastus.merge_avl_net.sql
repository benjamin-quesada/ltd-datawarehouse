SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [hastus].[merge_avl_net]
as
/*-----------LTD_GLOSSARY---------------
created by	:  B Eichberger
created dt	:  2026-03-19
purpose		:  merge hastus avl files for net
use			:  exec hastus.merge_avl_net

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

drop table if exists #prep_merge
drop table if exists #net_setup;
  WITH CategorizedRows AS (
    SELECT 
        ID,
        RawLine,filedate,
        -- Identify if this row is a Parent
        CASE WHEN RawLine LIKE 'DIS%' THEN ID ELSE NULL END AS ParentGroupID
    from hastus.avl_net_raw
)
,
LinkedRows as (
    select 
        ID,
        RawLine,filedate,
        -- "Fill down" the ParentGroupID to all rows below it until the next PAT
        max(ParentGroupID) over (ORDER BY ID ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS EffectiveParentID
    FROM CategorizedRows
    
)

-- Final view: Filters out the NET rows and shows SHA rows with their Parent ID from NET
SELECT 
    EffectiveParentID AS ParentRowID, l.id
                                   , c.RawLine
                                   , c.filedate
                                   , c.ParentGroupID,
    l.RawLine AS net_Data
into #net_setup
from LinkedRows l
join CategorizedRows c on c.id = l.EffectiveParentID
WHERE l.RawLine LIKE 'SHA%'
order by c.id

--select * from #net_setup order by id
--
SELECT filedate,id as file_row_id 
,rtrim(ltrim(substring(RawLine,charindex(';',rawline)+1,8))) as itn_stop_start 
,rtrim(ltrim(substring(RawLine,charindex(';',rawline)+10,8))) as itn_stop_end
,rtrim(ltrim(substring(RawLine,charindex(';',RawLine)+19,8))) as itn_distance
,rtrim(ltrim(substring(net_data,charindex(';',net_data)+1,10))) as itn_coord_x
,rtrim(ltrim(substring(net_data,charindex(';',net_data)+12,10))) as itn_coord_y
,rtrim(ltrim(substring(net_data,charindex(';',net_data)+23,12))) as itn_coord_long
,rtrim(ltrim(substring(net_data,charindex(';',net_data)+36,12))) as itn_coord_lat -- select * from
into
#prep_merge -- select * 
from #net_setup

declare @filedt date = (select distinct filedate from #prep_merge)


merge -- truncate table
hastus.avl_net t
using #prep_merge s on 
(
t.[filedate] = s.filedate and
t.file_row_id = s.file_row_id and
t.itn_stop_start = s.itn_stop_start and
t.itn_stop_end = s.itn_stop_end and
t.itn_coord_x = s.itn_coord_x and
t.itn_coord_y = s.itn_coord_y and 
t.[itn_coord_long] = s.[itn_coord_long] and
t.[itn_coord_lat] = s.[itn_coord_lat]
)
when not matched by source and t.filedate = @filedt then delete
when not matched by target  
then insert 
(
	[filedate]
,	[file_row_id]
,	[itn_stop_start]
,	[itn_stop_end]
,	[itn_distance]
,	[itn_coord_x]
,	[itn_coord_y]
,	[itn_coord_long]
,	[itn_coord_lat]
)
values 
(s.[filedate]
,s.[file_row_id]
,s.[itn_stop_start]
,s.[itn_stop_end]
,s.[itn_distance]
,s.[itn_coord_x]
,s.[itn_coord_y]
,s.[itn_coord_long]
,s.[itn_coord_lat]
)
output $action into @outputTbl;


drop table if exists #net_setup
drop table if exists #prep_merge

DECLARE @ins INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'INSERT')
DECLARE @upd INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'UPDATE')
DECLARE @del INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'DELETE')
DECLARE @prg varchar(90) = @@SERVERNAME + '.ltd_dw.hastus.merge_avl_net ' --+ CAST(@allCount AS VARCHAR(12))

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
SELECT 'NET',
'ltd_dw.hastus.avl_net',
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
