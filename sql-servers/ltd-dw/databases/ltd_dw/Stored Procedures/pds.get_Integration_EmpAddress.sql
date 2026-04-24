SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE procedure [pds].[get_Integration_EmpAddress]
as
/*-----------LTD_GLOSSARY---------------
created by:  B. Eichberger
created dt:  2025-12-26
purpose:  maintain Integration_EmpAddress from PDS file source that has been staged
use:  exec [pds].[get_Integration_EmpAddress]
 

*/

set nocount on;

 
declare @SPROC varchar(100)
set @SPROC = object_schema_name(@@procid) + '.' + object_name(@@procid)
 
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

declare @sdt datetime2 = sysdatetime();
declare @sudt datetime2 = dateadd(second,-1,@sdt)
drop table if exists #tEmpAddressStage;
drop table if exists #delTbl
drop table if exists #outputTbl
create table #delTbl (actionNm varchar(32));
create table #outputTbl (actionNm varchar(32));


    --get the data 
    select [person_id]
      ,[employee_id]
      ,[address_code]
      ,[address]
      ,[address_line1]
      ,[address_line2]
      ,[address_line3]
      ,[address_line4]
      ,[address_lines]
      ,[city]
      ,[county]
      ,[state]
      ,[state_name]
      ,[zip]
      ,[zip_code]
    into #tEmpAddressStage
    from pds.Integration_EmpAddress_Stage
    --where address_code <> 'PREVIOUS'
    

insert INTO #delTbl(actionNm)
select d.emp_address_id 
FROM -- truncate table 
    [pds].[Integration_EmpAddress] d 
where not exists (select 1 from #tEmpAddressStage s 
        where  s.[employee_id] = d.[employee_id]
               and s.person_id = d.person_id
               and s.[address_code] = d.[address_code])

delete d
output 'DELETE' into #outputTbl
from [pds].[Integration_EmpAddress] b
   left join #delTbl d on d.actionNm = b.emp_address_id
   where actionNm is not null 

update t 
     set t.record_updated_date = @sudt 
,   t.[emp_address_status] = 'Expired'
output 'UPDATE' into #outputTbl -- select * 
    from #tEmpAddressStage s
    left join [pds].[Integration_EmpAddress] t on 
         t.[address_code] = s.[address_code]
     and t.person_id = s.person_id
     and t.[employee_id] = s.[employee_id]
     and (isnull(t.[address],'') <> isnull(s.[address],'')
            or isnull(t.[address_line1],'') <> isnull(s.[address_line1],'')
            or isnull(t.[address_line2],'') <> isnull(s.[address_line2],'')
            or isnull(t.[address_line3],'') <> isnull(s.[address_line3],'')
            or isnull(t.[address_line4],'') <> isnull(s.[address_line4],'')
            or isnull(t.[address_lines],'') <> isnull(s.[address_lines],'')
            or isnull(t.[city],'') <> isnull(s.[city],'')
            or isnull(t.[county],'') <> isnull(s.[county],'')
            or isnull(t.[state],'') <> isnull(s.[state],'')
            or isnull(t.[state_name],'') <> isnull(s.[state_name],'')
            or isnull(t.[zip],'') <> isnull(s.[zip],'')
            or isnull(t.[zip_code],'') <> isnull(s.[zip_code],'')
            )
where t.emp_address_status = 'Current'


insert into [pds].[Integration_EmpAddress]
    (
        [emp_address_status]
      ,[person_id]
      ,[employee_id]
      ,[address_code]
      ,[address]
      ,[address_line1]
      ,[address_line2]
      ,[address_line3]
      ,[address_line4]
      ,[address_lines]
      ,[city]
      ,[county]
      ,[state]
      ,[state_name]
      ,[zip]
      ,[zip_code]
      ,record_created_date
    )
    output 'INSERT' into #outputTbl
    select 'Current'
      ,[person_id]
      ,[employee_id]
      ,[address_code]
      ,[address]
      ,[address_line1]
      ,[address_line2]
      ,[address_line3]
      ,[address_line4]
      ,[address_lines]
      ,[city]
      ,[county]
      ,[state]
      ,[state_name]
      ,[zip]
      ,[zip_code]
      ,@sdt
    from #tEmpAddressStage as s
        where not exists (select 1 from [pds].[Integration_EmpAddress] t
                where s.[employee_id] = t.[employee_id]
               and s.[address_code] = t.[address_code]
               and s.person_id = t.person_id
               and t.emp_address_status = 'Current'
           )


declare @allcount int = (select count(*) FROM #outputTbl )
DECLARE @ins INT = (SELECT COUNT(*) FROM #outputTbl WHERE actionNm = 'INSERT')
DECLARE @upd INT = (SELECT COUNT(*) FROM #outputTbl WHERE actionNm = 'UPDATE')
DECLARE @del INT = (SELECT COUNT(*) FROM #outputTbl WHERE actionNm = 'DELETE')
DECLARE @prg varchar(90) = @@SERVERNAME + '.ltd_dw.pds.get_Integration_EmpAddress: ' + CAST(@allCount AS VARCHAR(12))

insert process.mergeLogs
( [MergeCode]
           ,[ObjectDestination]
           ,[ObjectSource]
           ,[ObjectProgram]
           ,[recInsert]
           ,[recUpdate]
           ,[recDelete]
           ,[MergeBeginDatetime]
           ,[MergeEndDatetime])
select 'PDSCH',
'ltd_dw.pds.Integration_EmpAddress',
'PDS',
@prg,
isnull(@ins,0) ,isnull(@upd,0),isnull(@del,0),
@sdt,
sysdatetime();



end try
begin catch

    declare @profile varchar(255) =
            (
                select [name] from msdb.dbo.sysmail_profile
            );
    declare @errormsg varchar(max)
          , @error    int
          , @message  varchar(max)
          , @xstate   int
          , @errsev   int
          , @sub      varchar(255);

    select @error = error_number()
         , @errsev = error_severity()
         , @message = error_message()
         , @xstate = xact_state();

    select @errormsg
        = 'Error in ' + isnull(@SPROC, '') + ': ' + cast(isnull(@error, '') as nvarchar(32)) + '|'
          + coalesce(@message, '') + '|' + cast(isnull(@xstate, '') as nvarchar(32)) + '|'
          + cast(isnull(@errsev, '') as nvarchar(32));

    select @sub = 'ERROR: ' + @SPROC;

    exec msdb.dbo.sp_send_dbmail @profile_name = @profile
                               , @recipients = 'barb.eichberger@ltd.org'
                               , @subject = @sub
                               , @body = @errormsg;

    raiserror(@errormsg, @errsev, 1);
end catch;
GO
