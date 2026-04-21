SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [hastus].[merge_avl_plc]
as
/*-----------LTD_GLOSSARY---------------
created by	:  B Eichberger
created dt	:  2026-03-19
purpose		:  merge hastus avl files for plc
use			:  exec hastus.merge_avl_plc

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

drop table if exists #plc_setup

select filedate,id as file_row_id
,rtrim(ltrim(substring(RawLine,charindex(';',rawline)+1,6))) as plc_identifier 
,rtrim(ltrim(substring(RawLine,charindex(';',rawline)+8,40))) as plc_description
,rtrim(ltrim(substring(RawLine,charindex(';',RawLine)+49,6))) as plc_reference_place
,rtrim(ltrim(substring(RawLine,charindex(';',RawLine)+56,6))) as plc_district
,rtrim(ltrim(substring(RawLine,charindex(';',RawLine)+63,8))) as plc_number
,rtrim(ltrim(substring(RawLine,charindex(';',RawLine)+72,20))) as plc_alter_name
,rtrim(ltrim(substring(RawLine,charindex(';',RawLine)+93,10))) as loca_x_coord
,rtrim(ltrim(substring(RawLine,charindex(';',RawLine)+104,10))) as loca_y_coord
,rtrim(ltrim(substring(RawLine,charindex(';',RawLine)+115,12))) as loca_longitude
,rtrim(ltrim(substring(RawLine,charindex(';',RawLine)+128,12))) as loca_latitude
into -- SELECT * FROM 
#plc_setup
from hastus.avl_plc_raw


merge -- truncate table -- select * from 
[hastus].[avl_plc] t
using #plc_setup s on (
t.[filedate] = s.filedate and
t.file_row_id = s.file_row_id and
t.plc_identifier = s.plc_identifier 
)
when matched and (
   isnull(t.[plc_description],'') <>	isnull(s.[plc_description],'')
or isnull(t.[plc_reference_place],'') <>	isnull(s.[plc_reference_place],'')
or isnull(t.[plc_district],'') <>	isnull(s.[plc_district],'')
or isnull(t.[plc_number],'') <>	isnull(s.[plc_number],'')
or isnull(t.[plc_alter_name],'') <>	isnull(s.[plc_alter_name],'')
or isnull(t.[loca_x_coord],'') <>	isnull(s.[loca_x_coord],'')
or isnull(t.[loca_y_coord],'') <>	isnull(s.[loca_y_coord],'')
or isnull(t.[loca_longitude],'') <>	isnull(s.[loca_longitude],'')
)
then update set
t.[plc_description] = s.[plc_description]
,t.[plc_reference_place] = s.[plc_reference_place]
,t.[plc_district] = s.[plc_district]
,t.[plc_number] = s.[plc_number]
,t.[plc_alter_name] = s.[plc_alter_name]
,t.[loca_x_coord] = s.[loca_x_coord]
,t.[loca_y_coord] = s.[loca_y_coord]
,t.[loca_longitude] = s.[loca_longitude]
,t.record_updated_date = sysdatetime()
when not matched by target
then insert
( [filedate]
,[file_row_id]
,[plc_identifier]
,[plc_description]
,[plc_reference_place]
,[plc_district]
,[plc_number]
,[plc_alter_name]
,[loca_x_coord]
,[loca_y_coord]
,[loca_longitude]
)
values
(s.[filedate]
,s.[file_row_id]
,s.[plc_identifier]
,s.[plc_description]
,s.[plc_reference_place]
,s.[plc_district]
,s.[plc_number]
,s.[plc_alter_name]
,s.[loca_x_coord]
,s.[loca_y_coord]
,s.[loca_longitude]
)
output $action into @outputTbl;


drop table if exists #plc_setup


DECLARE @ins INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'INSERT')
DECLARE @upd INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'UPDATE')
DECLARE @del INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'DELETE')
DECLARE @prg varchar(90) = @@SERVERNAME + '.ltd_dw.hastus.merge_avl_plc ' --+ CAST(@allCount AS VARCHAR(12))

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
SELECT 'PLC',
'ltd_dw.hastus.avl_plc',
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
