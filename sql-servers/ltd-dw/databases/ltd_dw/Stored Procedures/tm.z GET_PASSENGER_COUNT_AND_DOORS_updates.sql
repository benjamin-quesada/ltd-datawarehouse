SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [tm].[z GET_PASSENGER_COUNT_AND_DOORS_updates] as

/* -- CHANGE HISTORY ------------------------------------------

NAME				DATE INT	Ticket Order or Request Info
Barb Eichberger		20200810	RID-10255 - add column HHMMSS with greater granularity, with doors
Barb Eichberger		20200923	RID-10421 - on request of planning needs to have more flexibility and data access
											use view to begin populating additional data about passenger activity
											with the detail of this view. Possible future use as a fact table.
											Convert to stored procedure.
Barb Eichberger		20201016	RID-10634	Fix index naming on table, update catch block to find only SQLData name for reporting errors.

example: exec [tm].[GET_PASSENGER_COUNT_AND_DOORS_updates]
*/----------------------------------------------------------


BEGIN TRY

SET FMTONLY OFF; 
SET NOCOUNT ON;


declare @workstartdt datetime = sysdatetime() 
-- clean up merge log in case some previous processing did not complete
	update ltd_dw.[process].[MergeLogs]
	SET MergeEndDatetime = @workstartdt
	where [MergeBeginDatetime] is not null 
	and MergeEndDatetime is null 
	and MergeCode = 'PCOD'
	AND [ObjectProgram] = 'ltd_dw.tm.GET_PASSENGER_COUNT_AND_DOORS_updates'
	and [ObjectDestination] = 'ltd_dw.rpt.PASSENGER_COUNT_V_OP_DOORS'

update statistics [rpt].[PASSENGER_COUNT_V_Op_Doors] ix_passenger_count_v_op_doors1 with sample 100 PERCENT
update statistics [rpt].[PASSENGER_COUNT_V_Op_Doors] ix_passenger_count_v_op_doors2 with sample 100 PERCENT
update statistics [rpt].[PASSENGER_COUNT_V_Op_Doors] ix_passenger_count_v_op_doors3 with sample 100 PERCENT


DECLARE @SPROC VARCHAR(100)
SET @SPROC = OBJECT_SCHEMA_NAME(@@PROCID) + '.' + OBJECT_NAME(@@PROCID)


declare @startdate DATE = (select CONVERT(datetime,convert(char(8),calid )) from 
						(select min(calid) calid from 
							(select convert(varchar(32),max([record_update_date]),112) calid from ltd_dw.[rpt].[PASSENGER_COUNT_V_Op_Doors] WITH (NOLOCK) 
							UNION 
							select min(calendar_id)-100000000  from ltd_dw.[rpt].[PASSENGER_COUNT_V_Op_Doors] WITH (NOLOCK) ) o ) j ) 
declare @enddate DATE = (select dateadd(day,-3,CONVERT(datetime,convert(char(8),calid ))) from 
							(select max(calendar_id)-100000000 calid from ltd_dw.[rpt].[PASSENGER_COUNT_V_Op_Doors] WITH (NOLOCK) ) o )


DECLARE @INTERVAL   INT = 10;
-- a method to break the work into bite sized chunks
-- set up a series of dates in needed size of days
-- to loop through
-- -->
;WITH T(N) AS (SELECT N FROM (VALUES (0),(0),(0),(0),(0),(0),(0),(0),(0),(0)) AS X(N))
,  NUMS(N) AS (SELECT TOP((DATEDIFF(DAY,@startdate,@enddate) / @INTERVAL ) +1) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 AS N
               FROM T T1,T T2,T T3,T T4)

SELECT
    NM.N rnbr
   ,DATEADD(DAY,(NM.N * @INTERVAL),@startdate) AS OUT_DATE_FM
   ,DATEADD(DAY, 9,DATEADD(DAY,(NM.N * @INTERVAL),@startdate) ) AS OUT_DATE_TO
into #dtloops
FROM NUMS   NM ;

alter table #dtloops add out_int_fm as (cast(convert(varchar(22),out_date_fm, 112) as BIGINT)+100000000)
alter table #dtloops add out_int_to as (cast(convert(varchar(22),out_date_to, 112) as BIGINT)+100000000)

--select * from #dtloops order by out_date_FM

 --set up and loop
declare @i BIGINT = 1
declare @r BIGINT = (select max(rnbr) from #dtloops)
declare @loopNbr INT

declare @loopStart INT
declare @loopEnd INT



if (select count(*) from #dtloops) > 0
BEGIN

WHILE @i <= @r

BEGIN

select @loopStart = (select out_int_fm from #dtloops where rnbr = @i) 
select @loopEnd = (select out_int_to from #dtloops where rnbr = @i) 


if (select count(*) from tempdb.sys.tables where name like '%OutPCTbl9943%') > 0
BEGIN
drop table #OutPCTbl9943
END

if (select count(*) from tempdb.sys.tables where name like '%tmpPC0003%') > 0
BEGIN
drop table #tmpPC0003
END

if (select count(*) from tempdb.sys.tables where name like '%tmpPC0005%') > 0
BEGIN
drop table #tmpPC0005
END

declare @workstartdt2 datetime = sysdatetime()
	

create table #OutPCTbl9943 (passcount datetime2)


select passenger_count_id, isnull(board,0) board, isnull(alight,0) alight, isnull(run_load,0) run_load
, isnull(passenger_miles,0) passenger_miles, isnull(departure_load,0) departure_load
into #tmpPC0005 
	from [LTD-TMDATA].[ltd_db].[dbo].[passenger_count_v_nolock_doors]
 where calendar_id >= @loopStart and calendar_id <= @loopEnd  


--CREATE UNIQUE CLUSTERED INDEX [ix_passenger_count_v_op_doors_pc_od] ON #tmpPC0005
--([passenger_count_id] ASC)
--WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]


select pc.* 
into #tmpPC0003 -- to save the data that is in tmdata but does not match passenger counts in dw
 from (select passenger_count_id, calendar_id,isnull(board,0) board, isnull(alight,0) alight, isnull(run_load,0) run_load
, isnull(passenger_miles,0) passenger_miles, isnull(departure_load,0) departure_load from ltd_dw.rpt.PASSENGER_COUNT_V_Op_Doors with (nolock)	) d		
INNER JOIN #tmpPC0005 pc WITH (NOLOCK) on d.PASSENGER_COUNT_ID = pc.passenger_count_id
WHERE d.calendar_id >= @loopStart and calendar_id <= @loopEnd	
AND (
   pc.[board]			   <> d.board
OR pc.[alight]             <> d.alight
OR pc.[run_load]           <> d.run_load
OR pc.[passenger_miles]    <> d.passenger_miles
OR pc.[departure_load]     <> d.departure_load)
 
 -- if there are records in the temp table (found not matching values)
-- go into update work
if (select count(*) from #tmpPC0003) > 0
BEGIN
      
update t 
set t.board = s.board,
	t.alight = s.alight,
	t.run_load = s.run_load,
	t.passenger_miles = s.passenger_miles,
	t.departure_load = s.departure_load,
	t.[record_update_date] = sysdatetime()
OUTPUT inserted.[record_update_date] into #OutPCTbl9943 (passcount)
FROM rpt.PASSENGER_COUNT_V_OP_DOORS t
join #tmpPC0003 s on s.passenger_count_id = t.passenger_count_id
 
declare @n2 int = (select isnull(count(*),0) from #OutPCTbl9943 WITH (NOLOCK)  )

-- save the merge log info	
insert ltd_dw.[process].[MergeLogs] (
		   [MergeCode]
		  ,[ObjectDestination]
		  ,[ObjectSource]
		  ,[ObjectProgram]
		  ,[recInsert]
		  ,[recUpdate]
		  ,[recDelete]
		  ,[MergeBeginDatetime]
		  ,MergeEndDatetime)
		  Values(
		  'PCOD', 'ltd_dw.rpt.PASSENGER_COUNT_V_OP_DOORS','TM','ltd_dw.tm.GET_PASSENGER_COUNT_AND_DOORS_updates',0, isnull( @n2, 0 ) , 0, @workstartdt2, sysdatetime())



END

	select @i = @i + 1

	If @i > @r
		BREAK
		ELSE CONTINUE
	END

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
