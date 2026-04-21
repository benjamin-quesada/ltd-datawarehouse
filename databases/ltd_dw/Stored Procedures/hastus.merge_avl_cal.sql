SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [hastus].[merge_avl_cal]
as
/*-----------LTD_GLOSSARY---------------
created by	:  B Eichberger
created dt	:  2026-03-20
purpose		:  merge hastus avl files for cal
use			:  exec hastus.merge_avl_cal

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


drop table if exists #cal_setup;
drop table if exists #prep_merge;

  WITH CategorizedRows AS (
    SELECT 
        ID,
        RawLine,filedate,
        -- Identify if this row is a Parent
        CASE WHEN RawLine LIKE 'CAL%' THEN ID ELSE NULL END AS ParentGroupID
    from hastus.avl_cal_raw
)
,
LinkedRows as (
    select 
        ID,
        RawLine,filedate,
        -- "Fill down" the ParentGroupID to all rows below it until the next PAT
        max(ParentGroupID) over (ORDER BY ID ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS EffectiveParentID
    FROM CategorizedRows
)

-- Final view: Filters out the PAT rows and shows TPS rows with their Parent ID
SELECT 
    EffectiveParentID AS ParentRowID, l.id
                                   , c.RawLine
                                   , c.filedate
                                   , c.ParentGroupID,
    l.RawLine AS cal_Data
into #cal_setup
from LinkedRows l
join CategorizedRows c on c.id = l.EffectiveParentID
WHERE l.RawLine LIKE 'DAT%'
order by 1,2;

--
SELECT filedate,id as file_row_id
,cast(rtrim(ltrim(substring(RawLine,charindex(';',rawline)+1,8))) as varchar(12)) as p_DateStart 
,cast(rtrim(ltrim(substring(RawLine,charindex(';',rawline)+10,8))) as varchar(12)) as p_DateEnd
,rtrim(ltrim(substring(RawLine,charindex(';',rawline)+19,8))) as p_SchedUnit
,rtrim(ltrim(substring(RawLine,charindex(';',rawline)+28,8))) as p_SchedSet
,cast(rtrim(ltrim(substring(cal_data,charindex(';',cal_data)+1,8))) as varchar(12)) as scud_date
,rtrim(ltrim(substring(cal_data,charindex(';',cal_data)+10,8))) as DateCscSchedUnit
,rtrim(ltrim(substring(cal_data,charindex(';',cal_data)+19,8))) as DateCscName
,rtrim(ltrim(substring(cal_data,charindex(';',cal_data)+28,10))) as DateCscTypeTitle
,rtrim(ltrim(substring(cal_data,charindex(';',cal_data)+39,2))) as DateCscType
,rtrim(ltrim(substring(cal_data,charindex(';',cal_data)+42,2))) as DateCscScen
,rtrim(ltrim(substring(cal_data,charindex(';',cal_data)+45,10))) as DateCscBooking
,rtrim(ltrim(substring(cal_data,charindex(';',cal_data)+56,8))) as DateVscSchedUnit
,rtrim(ltrim(substring(cal_data,charindex(';',cal_data)+65,8))) as DateVscName
,rtrim(ltrim(substring(cal_data,charindex(';',cal_data)+74,8))) as DateVscNameTxt
,rtrim(ltrim(substring(cal_data,charindex(';',cal_data)+85,2))) as DateVscType
,rtrim(ltrim(substring(cal_data,charindex(';',cal_data)+88,2))) as DateVscScen
,rtrim(ltrim(substring(cal_data,charindex(';',cal_data)+91,10))) as DateVscBooking
into -- SELECT * FROM 
#prep_merge
from #cal_setup

update #prep_merge
set p_DateStart = substring(p_DateStart,3,2)+'/'+left(p_DateStart,2) +'/'+right(p_DateStart,4)
, p_DateEnd = substring(p_DateEnd,3,2)+'/'+left(p_DateEnd,2) +'/'+right(p_DateEnd,4)
, scud_date = substring(scud_date,3,2)+'/'+left(scud_date,2) +'/'+right(scud_date,4)


merge -- truncate table -- select * from 
[hastus].[avl_cal] t 
using #prep_merge s on (
    t.filedate = s.filedate
and t.file_row_id = s.file_row_id
and t.scud_date = s.scud_date
)
when matched and (
   isnull(t.[p_DateStart],'') <> isnull(s.[p_DateStart],'')
or isnull(t.[p_DateEnd],'') <> isnull(s.[p_DateEnd],'')
OR isnull(t.[p_SchedUnit],'') <> isnull(s.[p_SchedUnit],'')
OR isnull(t.[p_SchedSet],'') <> isnull(s.[p_SchedSet],'')
OR isnull(t.[DateCscSchedUnit],'') <> isnull(s.[DateCscSchedUnit],'')
OR isnull(t.[DateCscName],'') <> isnull(s.[DateCscName],'')
OR isnull(t.[DateCscTypeTitle],'') <> isnull(s.[DateCscTypeTitle],'')
OR isnull(t.[DateCscType],'') <> isnull(s.[DateCscType],'')
OR isnull(t.[DateCscScen],'') <> isnull(s.[DateCscScen],'')
OR isnull(t.[DateCscBooking],'') <> isnull(s.[DateCscBooking],'')
OR isnull(t.[DateVscSchedUnit],'') <> isnull(s.[DateVscSchedUnit],'')
OR isnull(t.[DateVscName],'') <> isnull(s.[DateVscName],'')
OR isnull(t.[DateVscNameTxt],'') <> isnull(s.[DateVscNameTxt],'')
OR isnull(t.[DateVscType],'') <> isnull(s.[DateVscType],'')
OR isnull(t.[DateVscScen],'') <> isnull(s.[DateVscScen],'')
OR isnull(t.[DateVscBooking],'') <> isnull(s.[DateVscBooking],'')
)
then update set
 t.[p_DateStart] = s.[p_DateStart]
,t.[p_DateEnd] = s.[p_DateEnd]
,t.[p_SchedUnit] = s.[p_SchedUnit]
,t.[p_SchedSet] = s.[p_SchedSet]
,t.[DateCscSchedUnit] = s.[DateCscSchedUnit]
,t.[DateCscName] = s.[DateCscName]
,t.[DateCscTypeTitle] = s.[DateCscTypeTitle]
,t.[DateCscType] = s.[DateCscType]
,t.[DateCscScen] = s.[DateCscScen]
,t.[DateCscBooking] = s.[DateCscBooking]
,t.[DateVscSchedUnit] = s.[DateVscSchedUnit]
,t.[DateVscName] = s.[DateVscName]
,t.[DateVscNameTxt] = s.[DateVscNameTxt]
,t.[DateVscType] = s.[DateVscType]
,t.[DateVscScen] = s.[DateVscScen]
,t.[DateVscBooking] = s.[DateVscBooking]
,t.[record_updated_date] = sysdatetime()
when not matched then insert
([filedate]
,[file_row_id]
,[p_DateStart]
,[p_DateEnd]
,[p_SchedUnit]
,[p_SchedSet]
,[scud_date]
,[DateCscSchedUnit]
,[DateCscName]
,[DateCscTypeTitle]
,[DateCscType]
,[DateCscScen]
,[DateCscBooking]
,[DateVscSchedUnit]
,[DateVscName]
,[DateVscNameTxt]
,[DateVscType]
,[DateVscScen]
,[DateVscBooking]
)
values
(s.[filedate]
,s.[file_row_id]
,s.[p_DateStart]
,s.[p_DateEnd]
,s.[p_SchedUnit]
,s.[p_SchedSet]
,s.[scud_date]
,s.[DateCscSchedUnit]
,s.[DateCscName]
,s.[DateCscTypeTitle]
,s.[DateCscType]
,s.[DateCscScen]
,s.[DateCscBooking]
,s.[DateVscSchedUnit]
,s.[DateVscName]
,s.[DateVscNameTxt]
,s.[DateVscType]
,s.[DateVscScen]
,s.[DateVscBooking]
)
output $action into @outputTbl;

drop table if exists #cal_setup;
drop table if exists #prep_merge;


DECLARE @ins INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'INSERT')
DECLARE @upd INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'UPDATE')
DECLARE @del INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'DELETE')
DECLARE @prg varchar(90) = @@SERVERNAME + '.ltd_dw.hastus.merge_avl_cal ' --+ CAST(@allCount AS VARCHAR(12))

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
SELECT 'CAL',
'ltd_dw.hastus.avl_cal',
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
