SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [tm].[z GET_ROUTE_DIRECTION]
as
/*======================================================================
Purpose					: maintain dw copy of route direction data

Formula					:

Dependencies			: route data may depend on this for naming

Dependent on			: SQL Agent Job: Maintain Source Data - TM

Create/Change History	
20200212 - beichberger

			  		    : Notes and Line Numbers

-- exec [tm].[GET_ROUTE_DIRECTION]
=========================================================================*/


SET NOCOUNT ON

BEGIN TRY
       DECLARE @SPROC VARCHAR(100)
       SET @SPROC = OBJECT_SCHEMA_NAME(@@PROCID) + '.' + OBJECT_NAME(@@PROCID)


create table #OutputTbl994d (ActionName nvarchar(20))
declare @workstartdt datetime = sysdatetime()


-- clean up merge log in case some previous processing did not complete
update ltd_dw.[process].[MergeLogs]
SET [recInsert] = 0
,recDelete = 0
,recUpdate = 0 
,MergeEndDatetime = @workstartdt
where [MergeBeginDatetime] is not null 
and MergeEndDatetime is null 
and MergeCode = 'ROUTD'
and [ObjectDestination] = 'ltd_dw.tm.ROUTE_DIRECTION'

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
	  'ROUTD', 'ltd_dw.tm.ROUTE_DIRECTION','TM','ltd_dw.tm.GET_ROUTE_DIRECTION',0, 0, 0, @workstartdt)

MERGE [tm].[ROUTE_DIRECTION] t
using [LTD-TMDATA].[tmdatamart].[dbo].[ROUTE_DIRECTION] s
ON t.route_direction_id = s.route_direction_id
WHEN NOT MATCHED THEN 
INSERT
([ROUTE_DIRECTION_ID]
,[ROUTE_DIRECTION_ABBR]
,[ROUTE_DIRECTION_NAME]
		   )
VALUES
(s.[ROUTE_DIRECTION_ID]
,s.[ROUTE_DIRECTION_ABBR]
,s.[ROUTE_DIRECTION_NAME]
		  )
WHEN MATCHED  
AND (
   isnull(s.[ROUTE_DIRECTION_ABBR],'') <> ISNULL(t.[ROUTE_DIRECTION_ABBR] ,'')
OR isnull(s.[ROUTE_DIRECTION_NAME],'') <> ISNULL(t.[ROUTE_DIRECTION_NAME] ,'')
) 
THEN UPDATE 
SET t.[ROUTE_DIRECTION_ABBR] = t.[ROUTE_DIRECTION_ABBR] 
, t.[ROUTE_DIRECTION_NAME] = t.[ROUTE_DIRECTION_NAME]  
, t.record_update_date = sysdatetime()
OUTPUT $action into #OutputTbl994d;

declare @n int = (select isnull(count(*),0) from #OutputTbl994d WITH (NOLOCK) where ActionName = 'Insert' group by ActionName )
declare @u int = (select isnull(count(*),0) from #OutputTbl994d WITH (NOLOCK) where ActionName = 'Update' group by ActionName )
declare @d int = (select isnull(count(*),0) from #OutputTbl994d WITH (NOLOCK) where ActionName = 'Delete' group by ActionName )


update ltd_dw.[process].[MergeLogs] 
set recInsert = isnull( @n, 0 )
,recUpdate = isnull(@u, 0)
,recDelete = isnull(@d, 0)
,[MergeEndDatetime] = sysdatetime()
   where mergecode = 'ROUTD'
     and [ObjectDestination] = 'ltd_dw.tm.ROUTE_DIRECTION'
	 AND [ObjectSource] = 'TM'
	 AND [ObjectProgram] = 'ltd_dw.tm.GET_ROUTE_DIRECTION'
	 AND [MergeBeginDatetime] = @workstartdt
	 AND [MergeEndDatetime] is null
	 AND (recInsert = 0 or recUpdate = 0 or recDelete = 0)

END TRY

BEGIN CATCH
       DECLARE @profile VARCHAR(255) = (
                    SELECT NAME
                    FROM msdb.dbo.sysmail_profile
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
             ,@recipients = 'barb.eichberger@ltd.org' -- or you can set this up in a few tables that can be maintained, by sproc
                                                                                -- i have an example of how i've added sprocs automatically to a table, set
                                                                                 -- up a default notification person in data and accessed that person send
                                                                                 -- at the next failure, kind of overkill, but it can easily be done.
             ,@subject = @sub
             ,@body = @errormsg;

       RAISERROR (
                    @errormsg
                    ,@errsev
                    ,1
                    )
END CATCH

GO
