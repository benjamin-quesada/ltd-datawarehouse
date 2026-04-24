SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [tm].[GET_PASSENGER_COUNTS_UPDATE]
as 
/* 
PURPOSE: used to update the DW Copy of PassengerCount for expediency, toward Tabular Model
		 and keep passenger_count_dw up to date.

   AUTHOR: beichberger
     DATE: 20200924
CHANGEDON: 
 CHANGEBY: beichberger
   CHANGE: added as update process for DW summary values

   exec [tm].[GET_PASSENGER_COUNTS_UPDATE]
--*/



SET FMTONLY OFF; 


if (select count(*) from tempdb.sys.tables where name like '%tmpPC0001') > 0
BEGIN
drop table ##tmpPC0001
END


/*------------------LTD_GLOSSARY---------------
UPDATED BY:	Sopheap Suy
UPDATED DT:  10/31/2024
purpose	 :  Add object activities on who, what, when call this object
			write this data to aud.object_activity table everytime it's called */

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
 

 declare @workstartdt datetime = sysdatetime()

 
	
create table #OutPCTbl9999 (passcount BIGINT)
declare @workstartdt2 datetime = sysdatetime()

	 --clean up merge log in case some previous processing did not complete
	update ltd_dw.[process].[MergeLogs]
	SET [recInsert] = 0
	,recDelete = 0
	,recUpdate = 0 
	,MergeEndDatetime = @workstartdt2
	where [MergeBeginDatetime] is not null 
	and MergeEndDatetime is null 
	and MergeCode = 'PC'
	and [ObjectDestination] = 'ltd_dw.tm.PASSENGER_COUNT_DW'

	insert ltd_dw.[process].[MergeLogs] (
		   [MergeCode]
		  ,[ObjectDestination]
		  ,[ObjectSource]
		  ,[ObjectProgram]
		  ,[recInsert]
		  ,[recUpdate]
		  ,[recDelete]
		  ,[MergeBeginDatetime])
		  Values(
		  'PC', 'ltd_dw.tm.PASSENGER_COUNT_DW','TM','ltd_dw.tm.GET_PASSENGER_COUNTS',0, 0, 0, @workstartdt)

 
declare @update_bdt BIGINT = (select min(calendar_id) from ltd_dw.tm.PASSENGER_COUNT_DW)
declare @update_edt BIGINT = (select max(calendar_id) from ltd_dw.tm.PASSENGER_COUNT_DW)

select passenger_count_id, isnull(board,0) board, isnull(alight,0) alight
into #tmpPC0001 
	from [LTD-TMDATA].[ltd_db].[dbo].[passenger_count_v_nolock_doors]
 where calendar_id >= @update_bdt and calendar_id <= @update_edt  

CREATE UNIQUE CLUSTERED INDEX [ix_passenger_count_v_op_doors_pc_ID] ON #tmpPC0001
([passenger_count_id] ASC)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]


select pc.* 
into #tmpPC0003 -- to save the data that is in tmdata but does not match passenger counts
from (select passenger_count_id, isnull(board,0) board, isnull(alight,0) alight from ltd_dw.tm.PASSENGER_COUNT_DW with (nolock)) d 
INNER JOIN #tmpPC0001 pc WITH (NOLOCK) on d.PASSENGER_COUNT_ID = pc.passenger_count_id
WHERE (
   pc.[board]			   <> d.board
OR pc.[alight]             <> d.alight)
 

if (select count(*) from #tmpPC0003) > 0
BEGIN
      
update t 
set t.board = s.board,
	t.alight = s.alight
OUTPUT deleted.board into #OutPCTbl9999 (passcount)
FROM ltd_dw.tm.PASSENGER_COUNT_DW  t
join #tmpPC0003 s on s.passenger_count_id = t.passenger_count_id
 
declare @n2 int = (select isnull(count(*),0) from #OutPCTbl9999 WITH (NOLOCK)  )

	update ltd_dw.[process].[MergeLogs] 
	set recUpdate = isnull( @n2, 0 )
	,[MergeEndDatetime] = sysdatetime()
	   where mergecode = 'PC'
		 and [ObjectDestination] = 'ltd_dw.tm.PASSENGER_COUNT_DW'
		 AND [ObjectSource] = 'TM'
		 AND [ObjectProgram] = 'ltd_dw.tm.GET_PASSENGER_COUNTS'
		 AND [MergeBeginDatetime] = @workstartdt2
		 AND [MergeEndDatetime] is null
		 AND (recInsert = 0 or recUpdate = 0 or recDelete = 0)

	
	 END
  
END TRY	  

BEGIN CATCH

       DECLARE @profile VARCHAR(255) = (
                    SELECT NAME
                    FROM msdb.dbo.sysmail_profile where name = 'SQLData'
                    )
       DECLARE @errormsg VARCHAR(max)
             ,@error INT
             ,@message VARCHAR(max)
             ,@xstate INT
             ,@errsev INT
             ,@sub VARCHAR(255);

       SELECT @error = ERROR_NUMBER()
             ,@errsev = ERROR_SEVERITY()
             ,@message = ERROR_MESSAGE()
             ,@xstate = XACT_STATE();

       SELECT @errormsg = 'Error in ' + isnull(@SPROC, '') + ': ' + cast(isnull(@error, '') AS NVARCHAR(32)) + '|' + coalesce(@message, '') + '|' + cast(isnull(@xstate, '') AS NVARCHAR(32)) + '|' +cast(isnull(@errsev, '') AS NVARCHAR(32))

       SELECT @sub = 'ERROR: ' + @SPROC

       EXEC msdb.dbo.sp_send_dbmail @profile_name = @profile
             ,@recipients = 'barb.eichberger@ltd.org'--;servicedesk@ltd.org' 
             ,@subject = @sub
             ,@body = @errormsg;

       RAISERROR (
                    @errormsg
                    ,@errsev
                    ,1
                    )
END CATCH
GO
