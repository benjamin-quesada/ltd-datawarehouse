SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [itk].[get_subject_groups]
as
--/***********************

--created by	: B Eichberger
--created on	: 20250728
--purpose		: support security reporting - ticket 30087
--use			: exec itk.get_subject_groups

--*/
set nocount on

DECLARE @SPROC VARCHAR(100)
SET @SPROC = OBJECT_SCHEMA_NAME(@@PROCID) + '.' + OBJECT_NAME(@@PROCID)

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

truncate table ltd_dw.[itk].[subject_groups]
 drop table if exists #grps
select rn = row_number() over (order by SubjectGUID), subjectGuid,cast(Groups as xml) groups into #grps from [LTD-ITRAK].ixData.dbo.subjectProfile  where len(cast(Groups as varchar(max))) > 10

declare @i int = 1
declare @r int = (select max(rn) from #grps)
while @i <= @r
begin

declare @grptbl table (sg nvarchar(90),grp nvarchar(90))
declare @xml xml = (SELECT groups from #grps where rn = @i)
--select @xml
declare @sg  nvarchar(90) = (select subjectGuid from #grps where rn = @i)
insert @grptbl (sg, grp)
select @sg, x.value('@value', 'nvarchar(100)') AS item_value
	from @xml.nodes('/ItemRoot/ItemGroup/elements/element') AS t(x);

insert ltd_dw.[itk].[subject_groups] (subjectGUID,groups)
select sg,grp from @grptbl g
where not exists (select 1 from ltd_dw.[itk].[subject_groups] where subjectGuid = g.sg and groups = g.grp)

select @i = @i + 1

if @i > @r

break
else continue

end



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
