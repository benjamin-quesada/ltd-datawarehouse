SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [hastus].[merge_avl_rte]
AS
/*-----------LTD_GLOSSARY---------------
created by	:  B Eichberger
created dt	:  2026-03-19
purpose		:  merge hastus avl files for rte
use			:  exec hastus.merge_avl_rte

			*/
SET NOCOUNT ON

DECLARE @SPROC VARCHAR(100)
SET @SPROC = OBJECT_SCHEMA_NAME(@@PROCID) + '.' + OBJECT_NAME(@@PROCID)

INSERT INTO DBA.[aud].[Object_Activity]
	([server_name], [database_name] ,[host_name], [System_User], [object_name]
	,[client_net_address], [local_net_address], [auth_Scheme], [last_read], [last_write]
	,[most_recent_sql_handle], [Timestamp], object_type)
SELECT DISTINCT @@SERVERNAME, DB_NAME(),HOST_NAME(),SYSTEM_USER, @SPROC,
	client_net_address, local_net_address , auth_Scheme, last_read, last_write 
	,most_recent_sql_handle, CURRENT_TIMESTAMP AS [Timestamp], 'PROC'
FROM sys.dm_exec_connections 
WHERE session_id = @@SPID ;

BEGIN TRY


DECLARE @sdt DATETIME2 = SYSDATETIME()
DECLARE @outputTbl TABLE (actionNm VARCHAR(32));


drop table if exists #rte_setup
create table #rte_setup (
[filedate] date,
 id int,
[rte_identifier] varchar( 12 ),
   [rte_description] varchar(60),
   [rte_service_type] varchar( 60 ),
   [rte_service_type2]  varchar( 15 ) ,        
   [rte_service_mode] varchar(20)  ,       
   [rte_service_mode2]varchar(20)  
  )                            
declare @i int = 1
declare @r int = (select max(id) from hastus.avl_rte_raw)

while @i <= @r
begin

declare @rawline nvarchar(max) = (select isnull(rawline,'') from hastus.avl_rte_raw where id = @i) --  'RTE;11;Thurston;Urban;60;Bus2;2';
declare @fdate date = (select filedate from hastus.avl_rte_raw where id = @i) --  'RTE;11;Thurston;Urban;60;Bus2;2';

insert #rte_setup(	filedate
,	id
,	rte_identifier
,	rte_description
,	rte_service_type
,	rte_service_type2
,	rte_service_mode
,	rte_service_mode2
)
select @fdate as filedate,@i,
    max(case when [key] = '1' then trim(value) else '' end) as rte_identifier,
    max(case when [key] = '2' then trim(value) else '' end) as rte_description,
    max(case when [key] = '3' then trim(value) else '' end) as rte_service_type,
    max(case when [key] = '4' then trim(value) else '' end) as rte_service_type2,
    max(case when [key] = '5' then trim(value) else '' end) as rte_service_mode,
    max(case when [key] = '6' then trim(value) else '' end) as rte_service_mode2
from openjson('["' + replace(@rawline, ';', '","') + '"]');

select @i = @i + 1

if @i > @r
break
else continue

END


merge -- truncate table
[hastus].[avl_rte] t
using #rte_setup s on (
t.[filedate] = s.filedate and
t.file_row_id = s.id and
t.rte_identifier = s.rte_identifier)

when matched and (
 isnull(t.[rte_description],'') <> isnull(s.[rte_description],'')
 OR isnull(t.[rte_service_type],'') <> isnull(s.[rte_service_type],'')
 OR isnull(t.[rte_service_type2],'') <> isnull(s.[rte_service_type2],'')
 OR isnull(t.[rte_service_mode],'') <> isnull(s.[rte_service_mode],'')
 OR isnull(t.[rte_service_mode2],'') <> isnull(s.[rte_service_mode2],'')
 )
then update
set 
 t.[rte_description] = s.[rte_description]
,t.[rte_service_type] = s.[rte_service_type]
,t.[rte_service_type2] = s.[rte_service_type2]
,t.[rte_service_mode] = s.[rte_service_mode]
,t.[rte_service_mode2] = s.[rte_service_mode2]
,record_updated_date = sysdatetime()
when not matched by target then
INSERT 
([filedate]
,[file_row_id]
,[rte_identifier]
,[rte_description]
,[rte_service_type]
,[rte_service_type2]
,[rte_service_mode]
,[rte_service_mode2])
values( s.filedate
     , s.id
     , s.rte_identifier
     , s.rte_description
     , s.rte_service_type
     , s.rte_service_type2
     , s.rte_service_mode
     , s.rte_service_mode2
     )
OUTPUT $action INTO @outputTbl;



drop table if exists #rte_setup


DECLARE @ins INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'INSERT')
DECLARE @upd INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'UPDATE')
DECLARE @del INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'DELETE')
DECLARE @prg varchar(90) = @@SERVERNAME + '.ltd_dw.hastus.merge_avl_rte: ' --+ CAST(@allCount AS VARCHAR(12))

INSERT process.mergeLogs
(		[MergeCode]
           ,[ObjectDestination]
           ,[ObjectSource]
           ,[ObjectProgram]
           ,[recInsert]
           ,[recUpdate]
           ,[recDelete]
           ,[MergeBeginDatetime]
           ,[MergeEndDatetime])
SELECT 'RTE',
'ltd_dw.hastus.avl_rte',
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
