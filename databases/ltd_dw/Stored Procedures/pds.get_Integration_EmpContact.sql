SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


create procedure [pds].[get_Integration_EmpContact]
as
/*-----------LTD_GLOSSARY---------------
created by	:  B. Eichberger
created dt	:  2025-12-24
purpose		:  maintain Integration_EmpContact from PDS file source that has been staged
use			:  exec [pds].[get_Integration_EmpContact]
 

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
drop table if exists #tempContactStage;
drop table if exists #delTbl
drop table if exists #outputTbl
create table #delTbl (actionNm varchar(32));
create table #outputTbl (actionNm varchar(32));


    --get the data 
    select [person_id]
         , [employee_id]
         , [contact_name]
         , [relationship_code]
         , [relationship]
         , [area_code1]
         , [phone_no1]
         , [extension1]
         , [phone_number1]
         , [area_code2]
         , [phone_no2]
         , [extension2]
         , [phone_number2]
         , [area_code3]
         , [phone_no3]
         , [extension3]
         , [phone_number3]
         , [address_line1]
         , [address_line2]
         , [address_line3]
         , [address_line4]
         , [city]
         , [county]
         , [state]
         , [state_name]
         , [zip]
         , [zip_code]
         , [city_state_zip]
         , [country_code]
         , [country]
         , [effective_date]
         , [mail_address]
         , [priority]
    into #tempContactStage
    from pds.Integration_EmpContact_Stage
    

INSERT INTO #delTbl(actionNm)
select d.emp_econtact_id
FROM [pds].[Integration_EmpContact] d 
where not exists (select 1 from #tempContactStage s 
        where  s.[person_id] = d.[person_id]
               and s.[employee_id] = d.[employee_id]
               and s.[contact_name] = d.[contact_name]
               and s.[relationship_code] = d.[relationship_code])

delete d
output 'DELETE' into #outputTbl
from [pds].[Integration_EmpContact] b
   left join #delTbl d on d.actionNm = b.emp_econtact_id
   where actionNm is not null 

        
update t 
set t.[emp_econtact_status] = 'Expired', t.record_updated_date = @sudt
output 'UPDATE' into #outputTbl
     from #tempContactStage s
 left join [pds].[Integration_EmpContact] t on 
         t.[person_id] = s.[person_id]
     and t.[employee_id] = s.[employee_id]
     and t.[contact_name] = s.[contact_name]
     and t.relationship_code = s.relationship_code
     and (
            isnull(t.[area_code1], '') <> isnull(s.[area_code1], '')
            or isnull(t.[phone_no1], '') <> isnull(s.[phone_no1], '')
            or isnull(t.[extension1], '') <> isnull(s.[extension1], '')
            or isnull(t.[phone_number1], '') <> isnull(s.[phone_number1], '')
            or isnull(t.[area_code2], '') <> isnull(s.[area_code2], '')
            or isnull(t.[phone_no2], '') <> isnull(s.[phone_no2], '')
            or isnull(t.[extension2], '') <> isnull(s.[extension2], '')
            or isnull(t.[phone_number2], '') <> isnull(s.[phone_number2], '')
            or isnull(t.[area_code3], '') <> isnull(s.[area_code3], '')
            or isnull(t.[phone_no3], '') <> isnull(s.[phone_no3], '')
            or isnull(t.[extension3], '') <> isnull(s.[extension3], '')
            or isnull(t.[phone_number3], '') <> isnull(s.[phone_number3], '')
            or isnull(t.[address_line1], '') <> isnull(s.[address_line1], '')
            or isnull(t.[address_line2], '') <> isnull(s.[address_line2], '')
            or isnull(t.[address_line3], '') <> isnull(s.[address_line3], '')
            or isnull(t.[address_line4], '') <> isnull(s.[address_line4], '')
            or isnull(t.[city], '') <> isnull(s.[city], '')
            or isnull(t.[county], '') <> isnull(s.[county], '')
            or isnull(t.[state], '') <> isnull(s.[state], '')
            or isnull(t.[state_name], '') <> isnull(s.[state_name], '')
            or isnull(t.[zip], '') <> isnull(s.[zip], '')
            or isnull(t.[zip_code], '') <> isnull(s.[zip_code], '')
            or isnull(t.[city_state_zip], '') <> isnull(s.[city_state_zip], '')
            or isnull(t.[country_code], '') <> isnull(s.[country_code], '')
            or isnull(t.[country], '') <> isnull(s.[country], '')
            or isnull(t.[mail_address], '') <> isnull(s.[mail_address], '')
            or isnull(t.[priority], 0) <> isnull(s.[priority], 0)
            or isnull(t.[effective_date], '1/1/1900') <> isnull(s.[effective_date], '1/1/1900')
                )
where t.[emp_econtact_status] = 'Current' --and t.person_id is not null and t.employee_id is not null and t.contact_name is not null 


insert into [pds].[Integration_EmpContact]
    (
        [emp_econtact_status]
      , [person_id]
      , [employee_id]
      , [contact_name]
      , [relationship_code]
      , [relationship]
      , [area_code1]
      , [phone_no1]
      , [extension1]
      , [phone_number1]
      , [area_code2]
      , [phone_no2]
      , [extension2]
      , [phone_number2]
      , [area_code3]
      , [phone_no3]
      , [extension3]
      , [phone_number3]
      , [address_line1]
      , [address_line2]
      , [address_line3]
      , [address_line4]
      , [city]
      , [county]
      , [state]
      , [state_name]
      , [zip]
      , [zip_code]
      , [city_state_zip]
      , [country_code]
      , [country]
      , [effective_date]
      , [mail_address]
      , [priority]
      , record_created_date
    )
    output 'INSERT' into #outputTbl
    select 'Current'
         , [person_id]
         , [employee_id]
         , [contact_name]
         , [relationship_code]
         , [relationship]
         , [area_code1]
         , [phone_no1]
         , [extension1]
         , [phone_number1]
         , [area_code2]
         , [phone_no2]
         , [extension2]
         , [phone_number2]
         , [area_code3]
         , [phone_no3]
         , [extension3]
         , [phone_number3]
         , [address_line1]
         , [address_line2]
         , [address_line3]
         , [address_line4]
         , [city]
         , [county]
         , [state]
         , [state_name]
         , [zip]
         , [zip_code]
         , [city_state_zip]
         , [country_code]
         , [country]
         , [effective_date]
         , [mail_address]
         , [priority]
         , @sdt
    from #tempContactStage as s
        where 
        not exists (select 1 from [pds].[Integration_EmpContact] t
                where t.[person_id] = s.[person_id]
               and t.[employee_id] = s.[employee_id]
               and t.[contact_name] = s.[contact_name]
               and t.[relationship_code] = s.[relationship_code]
               and t.[emp_econtact_status] = 'Current'
           )


declare @allcount int = (select count(*) FROM #outputTbl )
DECLARE @ins INT = (SELECT COUNT(*) FROM #outputTbl WHERE actionNm = 'INSERT')
DECLARE @upd INT = (SELECT COUNT(*) FROM #outputTbl WHERE actionNm = 'UPDATE')
DECLARE @del INT = (SELECT COUNT(*) FROM #outputTbl WHERE actionNm = 'DELETE')
DECLARE @prg varchar(90) = @@SERVERNAME + '.ltd_dw.pds.get_Integration_EmpContact: ' + CAST(@allCount AS VARCHAR(12))

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
'ltd_dw.pds.Integration_EmpContact',
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
