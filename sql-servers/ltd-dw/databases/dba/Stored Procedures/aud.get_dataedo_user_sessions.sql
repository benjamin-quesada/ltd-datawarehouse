SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [aud].[get_dataedo_user_sessions]
as

/*-----------LTD_GLOSSARY---------------
 created by	:  B. Eichberger
 created dt	:  2026-02-25
 purpose	:  insert dataedo user sessions into DW for long term analysis and reporting
               run sql agent job 3x daily to ensure all daily sessions are recorded
 use		:  exec aud.get_dataedo_user_sessions

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

BEGIN TRY

DECLARE @sdt DATETIME2 = SYSDATETIME()
DECLARE @outputTbl TABLE (actionNm VARCHAR(32) NOT null);
DECLARE @lasti int = (select isnull(max(session_id),0) from dba.[aud].[dataedo_user_sessions])

insert -- truncate table
dba.[aud].[dataedo_user_sessions](
[session_id]
,[user_login]
,[authentication]
,[license_type]
,[login_date]
,[login_datetime]
,[login_date_id]
,[web_sessions]
,[desktop_sessions]
,[all_sessions]
,[role_actions] 
)
output 'INSERT' into @outputTbl(actionNm)
select
    s.[session_id],replace(replace(replace(replace(replace(
        case when replace(replace(replace(s.[login],'@ltd.org',''),'.',' '),'Ltd\','') like '% %' then 
                [dbo].[fn_ProperCase](replace(replace(replace(s.[login],'@ltd.org',''),'.',' '),'Ltd\',''))
                else
                replace(replace(replace(s.[login],'@ltd.org',''),'.',' '),'Ltd\','') end
                ,'Ad Ltd Org',''),'Ltd/',''),'@',''),'Croweq','Crowe'),'ltd org\','') as user_login     
         --,s.login               
    ,[authentication],s.[license_type],
    cast(s.[datetime] as date) as [login_date],
    s.[datetime] as [login_datetime],
    100000000 + convert(int, replace(convert(varchar, [datetime], 112), '-', ''))  as [login_date_id],
    case 
        when s.[product] = 'WEB' then 1 
        else 0 
    end as [web_sessions],
    case 
        when s.[product] = 'DESKTOP' then 1
        else 0 
    end as [desktop_sessions],
    case 
        when s.[product] = 'WEB' then 1 
        else 0 
    end +
    case 
        when s.[product] = 'DESKTOP' then 1
        else 0 
    end as [all_sessions],
    case when isnull(s.[role_actions],'') = '' then '{}' else s.role_actions end as role_actions
from
    dataedo.[dbo].[sessions] s
where not exists (select 1 from dba.[aud].[dataedo_user_sessions] n where s.session_id = n.session_id)
and s.[login] not in ( 'Your Login','sa')
and s.[login] not like '%iis%'
and s.[login] not like '%dataedo%'
and s.[login] not like '%login%' 
and s.session_id > @lasti



DECLARE @ins INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'INSERT')
DECLARE @upd INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'UPDATE')
DECLARE @del INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'DELETE')
DECLARE @prg varchar(90) = @@SERVERNAME + '.dba.aud.get_dataedo_user_sessions'

insert ltd_dw.process.mergeLogs
(		[MergeCode]
           ,[ObjectDestination]
           ,[ObjectSource]
           ,[ObjectProgram]
           ,[recInsert]
           ,[recUpdate]
           ,[recDelete]
           ,[MergeBeginDatetime]
           ,[MergeEndDatetime])
select 'DEDOU',
'dba.aud.dataedo_user_sessions',
'DEDO',
@prg,
isnull(@ins,0) ,ISNULL(@upd,0),ISNULL(@del,0),
@sdt,
sysdatetime()



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
             ,@recipients = 'barb.eichberger@ltd.org' 
             ,@subject = @sub
             ,@body = @errormsg;

       RAISERROR (
                    @errormsg
                    ,@errsev
                    ,1
                    )
END CATCH
GO
