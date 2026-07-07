SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE procedure [pds].[get_Integration_EmpPhone]
as
/*-----------LTD_GLOSSARY---------------
created by	:  B. Eichberger
created dt	:  2025-12-24
purpose		:  maintain Integration_EmpPhone from PDS file source that has been staged
use			:  exec [pds].[get_Integration_EmpPhone]
 

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
drop table if exists #tempPhoneStage;
drop table if exists #delTbl
drop table if exists #outputTbl
create table #delTbl (id varchar(32));
create table #outputTbl (actionNm varchar(32));


-- get clean data 
select distinct person_id
,	employee_id
,	phone_code
,	phone
,	area_code
,	phone_no
,	extension
,	phone_number
,	country_code
,	country
,	is_unlisted
,	is_primary
into #tempPhoneStage
from pds.Integration_EmpPhone_Stage
where phone_no is not null 
and rtrim(ltrim(phone_no)) <> ''
and len(phone_no) = 7
    
-- the phone number no longer exists in the dataset, prepare to delete it
-- updates occur only when the same number exists but the flags or code changes
INSERT INTO #delTbl(id)
select d.emp_phone_id
FROM [pds].[Integration_EmpPhone] d
where not exists (select 1 from #tempPhoneStage s 
        where  (s.[person_id] = d.[person_id]
               and s.[employee_id] = d.[employee_id]
               and s.phone_code = d.phone_code
               and s.phone_no = d.phone_no))
               or d.phone_no is null 
               or rtrim(ltrim(d.phone_no)) = ''
               or len(d.phone_no) <> 7

-- delete records that are not in stage
delete b
output 'DELETE' into #outputTbl 
from [pds].[Integration_EmpPhone] b
   inner join #delTbl d on d.id = b.emp_phone_id


-- expire rows that have changes in stage or that have incomplete phone numbers
-- change current rows to expired so insert
-- below can put fresh data back in
update t 
set t.[emp_phone_status] = 'Expired', t.record_updated_date = @sudt
output 'UPDATE' into #outputTbl 
     from #tempPhoneStage s
join [pds].[Integration_EmpPhone] t on 
         t.[person_id] = s.[person_id]
     and t.[employee_id] = s.[employee_id]
     and t.phone_code = s.phone_code
     and t.phone_no = s.phone_no
WHERE (isnull(t.[phone],'') <> isnull(s.[phone],'')
            OR isnull(t.[area_code],'') <> isnull(s.[area_code],'')
            OR isnull(t.[phone_number],'') <> isnull(s.[phone_number],'')
            OR isnull(t.[extension],'') <> isnull(s.[extension],'')
            OR isnull(t.[country_code],'') <> isnull(s.[country_code],'')
            OR isnull(t.[country],'') <> isnull(s.[country],'')
            OR isnull(t.[is_unlisted],'') <> isnull(s.[is_unlisted],'')
            OR isnull(t.[is_primary],'') <> isnull(s.[is_primary],'')
            )
and t.[emp_phone_status] = 'Current' 
-- ^ do not change already expired rows

-- add new and updated rows
insert into [pds].[Integration_EmpPhone]
([emp_phone_status]
,[person_id]
,[employee_id]
,[phone_code]
,[phone]
,[area_code]
,[phone_no]
,[phone_number]
,[extension]
,[country_code]
,[country]
,[is_unlisted]
,[is_primary]
    )
output 'INSERT' into #outputTbl
select 'Current' as [emp_phone_status]
,[person_id]
,[employee_id]
,[phone_code]
,[phone]
,[area_code]
,[phone_no]
,[phone_number]
,[extension]
,[country_code]
,[country]
,[is_unlisted]
,[is_primary]
    from #tempPhoneStage as s
        where 
        not exists (select 1 from [pds].[Integration_EmpPhone] t
                        where  t.[person_id] = s.[person_id]
                         and t.[employee_id] = s.[employee_id]
                         and t.phone_code = s.phone_code
                         and t.phone_no = s.phone_no
           )


declare @allcount int = (select count(*) FROM #outputTbl )
DECLARE @ins INT = (SELECT COUNT(*) FROM #outputTbl WHERE actionNm = 'INSERT')
DECLARE @upd INT = (SELECT COUNT(*) FROM #outputTbl WHERE actionNm = 'UPDATE')
DECLARE @del INT = (SELECT COUNT(*) FROM #outputTbl WHERE actionNm = 'DELETE')
DECLARE @prg varchar(90) = @@SERVERNAME + '.ltd_dw.pds.get_Integration_EmpPhone: ' + CAST(@allCount AS VARCHAR(12))

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
select 'PDSPH',
'ltd_dw.pds.Integration_EmpPhone',
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
