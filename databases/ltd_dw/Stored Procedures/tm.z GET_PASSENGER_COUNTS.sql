SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE procedure [tm].[z GET_PASSENGER_COUNTS]
as 
/* 
PURPOSE: used to populate the DW Copy of PassengerCount for expediency, toward Tabular Model
		 and keep passenger_count_dw up to date.

		 A partitioned table.
		 each year, dynamically managed: SPROC tm.PASSENGER_COUNT_PARTITION_MANAGER

			DROP PARTITION SCHEME schPASSENGER_COUNT_DW_YRMO;
			DROP PARTITION FUNCTION pfPASSENGER_COUNT_DW_YRMO;

			CREATE PARTITION FUNCTION pfPASSENGER_COUNT_DW_YRMO (NUMERIC(11,0))
			AS RANGE LEFT FOR VALUES (
'20070101',
'20070201',
...
'20200401');

			CREATE PARTITION SCHEME schPASSENGER_COUNT_DW_YRMO
			AS PARTITION [pfPASSENGER_COUNT_DW_YRMO] ALL TO ([PRIMARY]);

			CREATE NONCLUSTERED INDEX IX_PASSENGER_COUNT_DW_YRMO ON [tm].[PASSENGER_COUNT_DW] (CalendarPartitionKey) 
			ON schPASSENGER_COUNT_DW_YRMO(CalendarPartitionKey)



   AUTHOR: beichberger
     DATE: 20200210
CHANGEDON: 20200211
 CHANGEBY: beichberger
   CHANGE: add merge log tracking

   exec [tm].[GET_PASSENGER_COUNTS]
*/

BEGIN TRY

SET FMTONLY OFF; 
SET NOCOUNT ON;

if (select count(*) from tempdb.sys.tables where name like '%tmpPC0001') > 0
BEGIN
drop table ##tmpPC0001
END

  DECLARE @SPROC VARCHAR(100)
  SET @SPROC = OBJECT_SCHEMA_NAME(@@PROCID) + '.' + OBJECT_NAME(@@PROCID)
 

 
create table #OutPCTbl9940 (passcount BIGINT)
declare @workstartdt datetime = sysdatetime()


declare @startPCID BIGINT


set @startPCID = (select max([PASSENGER_COUNT_ID]) from ltd_dw.tm.PASSENGER_COUNT_DW) -- 362883521 -- 362883521

declare @sqlcmd nvarchar(max) = ''
select @sqlcmd = @sqlcmd + '
select * into ##tmpPC0001 from [LTD-TMDATA].[tmdatamart].[dbo].[PASSENGER_COUNT] c where c.passenger_count_id > '+ cast(@startPCID as varchar(38))
--print @sqlcmd
exec sp_executesql @sqlcmd

--select count(*) from ##tmpPC0001

if (select count(*) from ##tmpPC0001) > 0
BEGIN

	-- clean up merge log in case some previous processing did not complete
	update ltd_dw.[process].[MergeLogs]
	SET [recInsert] = 0
	,recDelete = 0
	,recUpdate = 0 
	,MergeEndDatetime = @workstartdt
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

	--select * from [LTD-TMDATA].[tmdatamart].[dbo].[PASSENGER_COUNT] c where passenger_count_id > 362560115 

	INSERT [tm].[PASSENGER_COUNT_DW](
				[PASSENGER_COUNT_ID]
			   ,[ROUTE_DIRECTION_ID]
			   ,[ROUTE_ID]
			   ,[CALENDAR_ID]
			   ,[calendar_date]
			   ,[BOARD]
			   ,[ALIGHT]
			   ,[VEHICLE_ID]
			   ,[OPERATOR_ID]
			   ,[BLOCK_ID]
			   ,[PATTERN_ID]
			   ,[TRIP_ID]
			   ,[GEO_NODE_ID]
			   ,[RUN_ID]
			   ,[SERVICE_TYPE_ID]
			   ,[TIME_TABLE_VERSION_ID]
			   ,[WORK_PIECE_ID])
	OUTPUT INSERTED.passenger_count_id into #OutPCTbl9940 (passcount)
	SELECT 
		  c.PASSENGER_COUNT_ID
		 ,c.[ROUTE_DIRECTION_ID]
		 ,c.[ROUTE_ID]
		 ,c.CALENDAR_ID
		 ,convert(datetime,convert(char(8),c.calendar_id - 100000000)) as calendar_date
		 ,c.[BOARD]
		 ,c.ALIGHT
		 ,c.VEHICLE_ID
		 ,c.OPERATOR_ID
		 ,c.BLOCK_ID
		 ,c.PATTERN_ID
		 ,c.TRIP_ID
		 ,c.GEO_NODE_ID
		 ,c.RUN_ID
		 ,c.SERVICE_TYPE_ID
		 ,c.TIME_TABLE_VERSION_ID
		 ,c.WORK_PIECE_ID
	  FROM ##tmpPC0001 c --[LTD-TMDATA].[tmdatamart].[dbo].[PASSENGER_COUNT] c WITH (NOLOCK)
	  LEFT JOIN ltd_dw.tm.PASSENGER_COUNT_DW d on d.PASSENGER_COUNT_ID = c.passenger_count_id
	  WHERE d.PASSENGER_COUNT_ID is null

  
	declare @n int = (select isnull(count(*),0) from #OutPCTbl9940 WITH (NOLOCK)  )
	--select @n

	update ltd_dw.[process].[MergeLogs] 
	set recInsert = isnull( @n, 0 )
	,[MergeEndDatetime] = sysdatetime()
	   where mergecode = 'PC'
		 and [ObjectDestination] = 'ltd_dw.tm.PASSENGER_COUNT_DW'
		 AND [ObjectSource] = 'TM'
		 AND [ObjectProgram] = 'ltd_dw.tm.GET_PASSENGER_COUNTS'
		 AND [MergeBeginDatetime] = @workstartdt
		 AND [MergeEndDatetime] is null
		 AND (recInsert = 0 or recUpdate = 0 or recDelete = 0)

if (select count(*) from tempdb.sys.tables where name like '%tmpPC0001%') > 0
BEGIN
drop table ##tmpPC0001
END
	
	 END
  
END TRY	  

BEGIN CATCH

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
