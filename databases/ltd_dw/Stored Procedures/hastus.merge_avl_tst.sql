SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [hastus].[merge_avl_tst]
AS
/*-----------LTD_GLOSSARY---------------
created by	:  B Eichberger
created dt	:  2026-03-26
purpose		:  merge hastus avl files for tst
use			:  exec hastus.merge_avl_tst

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

declare @sdt DATETIME2 = SYSDATETIME()
declare @outputTbl TABLE (actionNm VARCHAR(32));

declare @fdate date = (select distinct filedate from hastus.avl_tst_raw ) --  'RTE;11;Thurston;Urban;60;Bus2;2';

drop table if exists #prepInsert
CREATE TABLE #prepInsert (
	[filedate] [date] not null,
	[rte_version] [varchar](5) not null,
	[rte_identifier] [varchar](5) not null,
	[rte_description] [varchar](50) null,
	[trp_number] [varchar](8) not null,
	[trp_int_number] [int] not null,
	[trp_note_id] [varchar](8) not null,
	[trp_second_note_id] [varchar](8) not null,
	[trppt_place] [varchar](8) not null,
	[trppt_stop_id] [varchar](8) not null,
	[trppt_arrival_time] [varchar](8) not null,
	[trppt_tp_note_id] [varchar](8) not null,
	[trppt_tstp_note_id] [varchar](8) not null,
	[trppt_is_timing_point] [varchar](2) not null,
	[trppt_place_description] [varchar](50) not null,
	[trp_oper_days_12] [varchar](8) not null
)
insert into #prepInsert
(	[filedate]
,	[rte_version]
,	[rte_identifier]
,	[rte_description]
,	[trp_number]
,	[trp_int_number]
,	[trp_note_id]
,	[trp_second_note_id]
,	[trppt_place]
,	[trppt_stop_id]
,	[trppt_arrival_time]
,	[trppt_tp_note_id]
,	[trppt_tstp_note_id]
,	[trppt_is_timing_point]
,	[trppt_place_description]
,	[trp_oper_days_12]
)
select @fdate
,	rtrim(ltrim([rte_version]))  as [rte_version]
,	rtrim(ltrim([rte_identifier])) as [rte_identifier]
,	[rte_description]
,	rtrim(ltrim([trp_number])) as [trp_number]
,	cast(rtrim(ltrim([trp_int_number])) as int) as [trp_int_number]
,	[trp_note_id]
,	[trp_second_note_id]
,	[trppt_place]
,	[trppt_stop] as [trppt_stop_id]
,	[trppt_arrival_time]
,	[trppt_tp_note_id]
,	[trppt_tstp_note_id]
,	[trppt_is_timing_point]
,	[trppt_place_description]
,	[trp_oper_days_12] -- select * 
FROM [hastus].[avl_tst_raw]

DELETE FROM 
[hastus].[avl_tst]
OUTPUT 'DELETE' INTO @outputTbl
WHERE filedate = @fdate
INSERT [hastus].[avl_tst]
(	[filedate]
,	[rte_version]
,	[rte_identifier]
,	[rte_description]
,	[trp_number]
,	[trp_int_number]
,	[trp_note_id]
,	[trp_second_note_id]
,	[trppt_place]
,	[trppt_stop_id]
,	[trppt_arrival_time]
,	[trppt_tp_note_id]
,	[trppt_tstp_note_id]
,	[trppt_is_timing_point]
,	[trppt_place_description]
,	[trp_oper_days_12]
)OUTPUT 'INSERT' INTO @outputTbl
SELECT 
 @fdate
,s.[rte_version]
,s.[rte_identifier]
,s.[rte_description]
,s.[trp_number]
,s.[trp_int_number]
,s.[trp_note_id]
,s.[trp_second_note_id]
,s.[trppt_place]
,s.[trppt_stop_id]
,s.[trppt_arrival_time]
,s.[trppt_tp_note_id]
,s.[trppt_tstp_note_id]
,s.[trppt_is_timing_point]
,s.[trppt_place_description]
,s.[trp_oper_days_12]
FROM #prepInsert s
 
drop table if exists #prepInsert


DECLARE @ins INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'INSERT')
DECLARE @upd INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'UPDATE')
DECLARE @del INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'DELETE')
DECLARE @prg varchar(90) = @@SERVERNAME + '.ltd_dw.hastus.merge_avl_tst: ' --+ CAST(@allCount AS VARCHAR(12))

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
SELECT 'TST',
'ltd_dw.hastus.avl_tst',
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
