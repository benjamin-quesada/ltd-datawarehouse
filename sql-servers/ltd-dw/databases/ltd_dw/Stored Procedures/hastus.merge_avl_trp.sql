SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [hastus].[merge_avl_trp]
AS
/*-----------LTD_GLOSSARY---------------
created by	:  B Eichberger
created dt	:  2026-03-19
purpose		:  merge hastus avl files for trp
use			:  exec hastus.merge_avl_trp

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
DECLARE @outputTbl TABLE (actionNm VARCHAR(32));


drop table if exists #trp_setup;
DROP TABLE IF EXISTS #filteredMerge;
DROP TABLE IF EXISTS #prepMerge;


  WITH CategorizedRows AS (
    SELECT 
        ID,filedate,
        RawLine,
        -- Identify if this row is a Parent
        CASE WHEN RawLine LIKE 'TRP%' THEN ID ELSE NULL END AS ParentGroupID -- select * 
    from hastus.avl_trp_raw 
)
,LinkedRows as (
    select 
        ID,filedate,
        RawLine,
        -- "Fill down" the ParentGroupID to all rows below it until the next TRP
        max(ISNULL(ParentGroupID,0)) over (ORDER BY ID ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS EffectiveParentID
    FROM CategorizedRows
)

-- Final view: Filters out the PAT rows and shows PTS rows with their Parent ID
SELECT 
    EffectiveParentID AS ParentRowID, l.id, c.filedate, c.RawLine ,l.RawLine AS TRP_Data
into #trp_setup
from LinkedRows l
join CategorizedRows c on c.id = l.EffectiveParentID
WHERE l.RawLine LIKE 'PTS%'
order by 1,2;

CREATE TABLE #prepMerge (
	[filedate] date NOT NULL,
	[file_row_id] [int] NOT NULL,
	[trp_int_number] int null,
	[trp_number] varchar(8) NULL,
	[trp_operating_days] varchar(7) null,
	[trp_route_statistic] [nvarchar](5) NULL,
	[tpat_external_id] [nvarchar](4) NULL,
	[trp_type] [nvarchar](15) NULL,
	[trp_type_code] [nvarchar](2) NULL,
	[trp_is_special] [nvarchar](1) NULL,
	[trp_is_public] [nvarchar](1) NULL,
	[tstp_passing_time] [nvarchar](8) NULL
)
insert into #prepMerge
           ([filedate]
           ,file_row_id
           ,[trp_int_number]
           ,[trp_number]
           ,[trp_operating_days]
           ,[trp_route_statistic]
           ,[tpat_external_id]
           ,[trp_type]
           ,[trp_type_code]
           ,[trp_is_special]
           ,[trp_is_public]
           ,[tstp_passing_time])
SELECT filedate, id
,rtrim(ltrim(substring(RawLine,charindex(';',rawline)+1,10))) as trp_int_number 
,rtrim(ltrim(substring(RawLine,charindex(';',rawline)+12,8))) as trp_number
,rtrim(ltrim(substring(RawLine,charindex(';',rawline)+21,7))) as trp_operating_days
,rtrim(ltrim(substring(RawLine,charindex(';',rawline)+29,5))) as trp_route_statistic
,rtrim(ltrim(substring(RawLine,charindex(';',rawline)+35,4))) as tpat_external_id
,rtrim(ltrim(substring(RawLine,charindex(';',rawline)+40,15))) as trp_type
,rtrim(ltrim(substring(RawLine,charindex(';',rawline)+56,2))) as trp_type_code
,rtrim(ltrim(substring(RawLine,charindex(';',rawline)+59,1))) as trp_is_special
,rtrim(ltrim(substring(RawLine,charindex(';',rawline)+61,1))) as trp_is_public
,rtrim(ltrim(substring(trp_data,charindex(';',trp_data)+1,8))) as tstp_passing_time -- select *
from #trp_setup
order by  id


declare @file_dt date = (SELECT distinct filedate FROM #prepMerge)
delete from [hastus].[avl_trp] where filedate = @file_dt -- replacing the entire filedate each time - if the file date is in the prep then delete if from the trp table and reload all of that filedate

SELECT filedate
	  ,file_row_id
	  ,trp_int_number
	  ,trp_number
	  ,trp_operating_days
	  ,trp_route_statistic
	  ,tpat_external_id
	  ,trp_type
	  ,trp_type_code
	  ,trp_is_special
	  ,trp_is_public
	  ,tstp_passing_time 
INTO #filteredMerge
FROM #prepMerge
WHERE (ISNUMERIC(trp_route_statistic)=1 OR trp_route_statistic = '79x')
AND trp_route_statistic <> '25'
-- filter out all FLT and Training runs

merge [hastus].[avl_trp] t 
using #filteredMerge s on (
t.filedate = s.filedate 
  )
when not matched then insert
(   filedate
,   file_row_id
,   trp_int_number
,   [trp_number]
,	[trp_operating_days]
,	[trp_route_statistic]
,	[tpat_external_id]
,	[trp_type]
,	[trp_type_code]
,	[trp_is_special]
,	[trp_is_public]
,	[tstp_passing_time]
,   [tstp_passing_time_hr]
,   [tstp_passing_time_min])
values(
 s.filedate
,s.file_row_id
,s.trp_int_number
,s.[trp_number]
,s.[trp_operating_days]
,s.[trp_route_statistic]
,s.[tpat_external_id]
,s.[trp_type]
,s.[trp_type_code]
,s.[trp_is_special]
,s.[trp_is_public]
,s.[tstp_passing_time]
,LEFT(s.[tstp_passing_time],2)
,RIGHT(s.[tstp_passing_time],2)
)
OUTPUT $action INTO @outputTbl;



DECLARE @ins INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'INSERT')
DECLARE @upd INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'UPDATE')
DECLARE @del INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'DELETE')
DECLARE @prg varchar(90) = @@SERVERNAME + '.ltd_dw.hastus.merge_avl_trp: ' --+ CAST(@allCount AS VARCHAR(12))

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
SELECT 'TRP',
'ltd_dw.hastus.avl_trp',
'HASTUS',
@prg,
ISNULL(@ins,0) ,ISNULL(@upd,0),ISNULL(@del,0),
@sdt,
SYSDATETIME()


drop table if exists #trp_setup;
DROP TABLE IF EXISTS #filteredMerge
DROP TABLE IF EXISTS #prepMerge


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
