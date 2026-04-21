SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [hastus].[merge_avl_nde]
as
/*-----------LTD_GLOSSARY---------------
created by	:  B Eichberger
created dt	:  2026-03-19
purpose		:  merge hastus avl files for nde
use			:  exec hastus.merge_avl_nde

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


drop table if exists #nde_setup;
select filedate,id as file_row_id
,rtrim(ltrim(substring(RawLine,charindex(';',rawline)+1,8))) as stp_identifier 
,rtrim(ltrim(substring(RawLine,charindex(';',rawline)+10,50))) as stp_description
,rtrim(ltrim(substring(RawLine,charindex(';',RawLine)+61,6))) as stp_place
,rtrim(ltrim(substring(RawLine,charindex(';',RawLine)+68,10))) as loca_x_coord
,rtrim(ltrim(substring(RawLine,charindex(';',RawLine)+79,10))) as loca_y_coord
,rtrim(ltrim(substring(RawLine,charindex(';',RawLine)+90,50))) as loca_intersect_1
,rtrim(ltrim(substring(RawLine,charindex(';',RawLine)+141,50))) as loca_intersect_2
,rtrim(ltrim(substring(RawLine,charindex(';',RawLine)+192,5))) as loca_inter_distance
,rtrim(ltrim(substring(RawLine,charindex(';',RawLine)+198,4))) as loca_offset
,rtrim(ltrim(substring(RawLine,charindex(';',RawLine)+203,6))) as stp_district
,rtrim(ltrim(substring(RawLine,charindex(';',RawLine)+210,8))) as stp_zone
,rtrim(ltrim(substring(RawLine,charindex(';',RawLine)+219,1))) as stp_is_public
,rtrim(ltrim(substring(RawLine,charindex(';',RawLine)+221,5))) as loca_dist_inter1
,rtrim(ltrim(substring(RawLine,charindex(';',RawLine)+227,5))) as loca_dist_inter2
,rtrim(ltrim(substring(RawLine,charindex(';',RawLine)+233,1))) as stp_street_segment_id
,rtrim(ltrim(substring(RawLine,charindex(';',RawLine)+235,12))) as stp_loca_latitude
,rtrim(ltrim(substring(RawLine,charindex(';',RawLine)+248,12))) as stp_loca_longitude
into --SELECT * FROM 
#nde_setup--SELECT *  
from hastus.avl_nde_raw


merge -- truncate table -- select * from 
[hastus].[avl_nde] t
using #nde_setup s on (
t.[filedate] = s.filedate and
t.file_row_id = s.file_row_id and
t.[stp_identifier] = s.[stp_identifier]
 
)
when matched and (
   isnull(t.[stp_description],'') <> isnull(s.[stp_description],'')
OR isnull(t.[stp_place],'') <> isnull(s.[stp_place],'')
OR isnull(t.[loca_x_coord],'') <> isnull(s.[loca_x_coord],'')
OR isnull(t.[loca_y_coord],'') <> isnull(s.[loca_y_coord],'')
OR isnull(t.[loca_intersect_1],'') <> isnull(s.[loca_intersect_1],'')
OR isnull(t.[loca_intersect_2],'') <> isnull(s.[loca_intersect_2],'')
OR isnull(t.[loca_inter_distance],'') <> isnull(s.[loca_inter_distance],'')
OR isnull(t.[loca_offset],'') <> isnull(s.[loca_offset],'')
OR isnull(t.[stp_district],'') <> isnull(s.[stp_district],'')
OR isnull(t.[stp_zone],'') <> isnull(s.[stp_zone],'')
OR isnull(t.[stp_is_public],'') <> isnull(s.[stp_is_public],'')
OR isnull(t.[loca_dist_inter1],'') <> isnull(s.[loca_dist_inter1],'')
OR isnull(t.[loca_dist_inter2],'') <> isnull(s.[loca_dist_inter2],'')
OR isnull(t.[stp_street_segment_id],'') <> isnull(s.[stp_street_segment_id],'')
OR isnull(t.[stp_loca_latitude],'') <> isnull(s.[stp_loca_latitude],'')
OR isnull(t.[stp_loca_longitude],'') <> isnull(s.[stp_loca_longitude],'')
) then update set
 t.	[stp_description] = s.[stp_description]
,t.	[stp_place] = s.[stp_place]
,t.	[loca_x_coord] = s.[loca_x_coord]
,t.	[loca_y_coord] = s.[loca_y_coord]
,t.	[loca_intersect_1] = s.[loca_intersect_1]
,t.	[loca_intersect_2] = s.[loca_intersect_2]
,t.	[loca_inter_distance] = s.[loca_inter_distance]
,t.	[loca_offset] = s.[loca_offset]
,t.	[stp_district] = s.[stp_district]
,t.	[stp_zone] = s.[stp_zone]
,t.	[stp_is_public] = s.[stp_is_public]
,t.	[loca_dist_inter1] = s.[loca_dist_inter1]
,t.	[loca_dist_inter2] = s.[loca_dist_inter2]
,t.	[stp_street_segment_id] = s.[stp_street_segment_id]
,t.	[stp_loca_latitude] = s.[stp_loca_latitude]
,t.	[stp_loca_longitude] = s.[stp_loca_longitude]
,t.record_updated_date = sysdatetime()
when not matched by target
then insert
( [filedate]
,[file_row_id]
,[stp_identifier]
,[stp_description]
,[stp_place]
,[loca_x_coord]
,[loca_y_coord]
,[loca_intersect_1]
,[loca_intersect_2]
,[loca_inter_distance]
,[loca_offset]
,[stp_district]
,[stp_zone]
,[stp_is_public]
,[loca_dist_inter1]
,[loca_dist_inter2]
,[stp_street_segment_id]
,[stp_loca_latitude]
,[stp_loca_longitude]

)
values
(s.[filedate]
,s.[file_row_id]
,s.[stp_identifier]
,s.[stp_description]
,s.[stp_place]
,s.[loca_x_coord]
,s.[loca_y_coord]
,s.[loca_intersect_1]
,s.[loca_intersect_2]
,s.[loca_inter_distance]
,s.[loca_offset]
,s.[stp_district]
,s.[stp_zone]
,s.[stp_is_public]
,s.[loca_dist_inter1]
,s.[loca_dist_inter2]
,s.[stp_street_segment_id]
,s.[stp_loca_latitude]
,s.[stp_loca_longitude]
)
output $action into @outputTbl;


drop table if exists #plc_setup


DECLARE @ins INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'INSERT')
DECLARE @upd INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'UPDATE')
DECLARE @del INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'DELETE')
DECLARE @prg varchar(90) = @@SERVERNAME + '.ltd_dw.hastus.merge_avl_nde ' --+ CAST(@allCount AS VARCHAR(12))

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
SELECT 'NDE',
'ltd_dw.hastus.avl_nde',
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
