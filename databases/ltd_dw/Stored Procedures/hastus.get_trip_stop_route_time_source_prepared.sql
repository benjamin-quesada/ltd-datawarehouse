SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [hastus].[get_trip_stop_route_time_source_prepared]

AS

/*-----------LTD_GLOSSARY---------------
created by	:  B Eichberger
created dt	:  2026-04-03
purpose		:  load latest data into hastus.trip_stop_route_time_source_prepared
use			:  exec hastus.get_trip_stop_route_time_source_prepared

	*/
SET NOCOUNT ON;


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
DECLARE @bid VARCHAR(4) = (SELECT MAX(DateCscBooking) FROM hastus.avl_cal)


SET NOCOUNT ON;

drop table if exists #cal
drop table if exists #pat
drop table if exists #trips
drop table if exists #rankPlace
drop table if exists #xmlprep
drop table if exists #xmlsource
DROP TABLE IF EXISTS #rteLoop


CREATE TABLE #xmlsource(RankInTimetable BIGINT NOT NULL,
	[RankInTimeTablePlace] [BIGINT] NULL,
	[DateCscBooking] [NVARCHAR](MAX) NULL,
	[DateVscType] [NVARCHAR](MAX) NULL,
	[DateCscTypeTitle] [NVARCHAR](MAX) NULL,
	[DateCscScen] [NVARCHAR](MAX) NULL,
	[tpat_route] [NVARCHAR](5) NULL,
	[rte_description] [VARCHAR](60) NULL,
	[tpat_direction] [NVARCHAR](10) NULL,
	[tpatpt_load_place] [NVARCHAR](6) NULL,
    [tpatpt_is_timing_point] NVARCHAR(1) NULL,
	[tpatpt_stop_id] [NVARCHAR](8) NULL,
	[tstp_passing_time] [NVARCHAR](8) NULL,
	[tpat_via] [NVARCHAR](8) NULL,
	[via_desc] [NVARCHAR](40) NULL,
	[tpat_external_id] [NVARCHAR](4) NULL,
	[plc_description] [NVARCHAR](40) NULL,
	[trp_int_number] [INT] NULL,
	[trp_number] [NVARCHAR](8) NULL,
	[trp_operating_days] [NVARCHAR](7) NULL,
	[trp_type] [NVARCHAR](15) NULL,
	[trp_type_code] [NVARCHAR](2) NULL,
	[trp_is_special] [NVARCHAR](1) NULL,
	[trp_is_public] [NVARCHAR](1) NULL,
	[stp_description] [NVARCHAR](50) NULL,
	[stp_place] [NVARCHAR](6) NULL,
	[loca_intersect_1] [NVARCHAR](50) NULL,
	[loca_intersect_2] [NVARCHAR](50) NULL,
	[stp_district] [NVARCHAR](6) NULL,
	[stp_zone] [NVARCHAR](8) NULL,
	[stp_is_public] [NVARCHAR](1) NULL,
	[trp_note_id] [VARCHAR](8) NOT NULL,
	[trp_second_note_id] [VARCHAR](8) NOT NULL,
	[trppt_tp_note_id] [VARCHAR](8) NOT NULL,
	[trppt_tstp_note_id] [VARCHAR](8) NOT NULL,
	[trp_note_txt] [VARCHAR](3500) NULL,
	[trp_second_note_txt] [VARCHAR](3500) NULL,
	[trppt_tp_note_txt] [VARCHAR](3500) NULL,
	[trppt_tstp_note_txt] [VARCHAR](3500) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]



select distinct filedate, DateCscScen, DateCscBooking
, DateVscType,DateVscTypeCode = case DateVscType 
            WHEN 0 then '12345'
            WHEN 5 then '6'
            WHEN 6 then '7' ELSE DateVscType END 
    ,DateCscTypeTitle, DateVscScen 
    into #cal
    from hastus.avl_cal where DateCscBooking = @bid

SELECT rn=ROW_NUMBER() OVER (ORDER BY file_row_id ), * INTO #rteLoop
FROM (SELECT DISTINCT file_row_id, tpat_route, tpat_external_id, tpat_direction, tpatpt_stop_id, tpatpt_load_place FROM hastus.avl_pat 
            ) g

DECLARE @i INT = 1
DECLARE @r INT = (SELECT MAX(rn) FROM #rteLoop)
DECLARE @currRte VARCHAR(5)
DECLARE @currExId VARCHAR(4)
DECLARE @currDir VARCHAR(10)
DECLARE @currStop VARCHAR(8)

WHILE @i <= @r
BEGIN


drop table if exists #pat
drop table if exists #trips
drop table if exists #xmlprep
drop table if exists #rankPlace

select @currRte = (SELECT DISTINCT tpat_route FROM #rteLoop WHERE rn = @i)
select @currExId = (SELECT DISTINCT tpat_external_id FROM #rteLoop WHERE rn = @i)
select @currDir = (SELECT DISTINCT tpat_direction FROM #rteLoop WHERE rn = @i)
select @currStop = (SELECT DISTINCT tpatpt_stop_id FROM #rteLoop WHERE rn = @i)


select c.DateCscBooking, p.file_row_id
      ,p.tpat_route
      ,p.tpat_direction
      ,p.tpatpt_load_place
      ,p.tpatpt_stop_id
      ,p.tpat_via
      ,p.via_desc
      ,p.tpat_external_id
      ,d.plc_description
      ,p.tpatpt_is_timing_point
into  #pat
from #cal c 
JOIN hastus.avl_pat p  on c.filedate = p.filedate
left join hastus.avl_plc d on d.plc_identifier = p.tpatpt_load_place and d.filedate = p.filedate
 where 1=1
 and p.tpatpt_stop_id not like '%ann%' 
 and p.tpatpt_stop_id not like '%arr%' 
 and p.tpatpt_stop_id not like '%anx%'  
 and p.tpat_route = @currRte
 and p.tpatpt_stop_id = @currStop
 AND p.tpat_external_id = @currExId
group by c.DateCscBooking, p.file_row_id
      ,p.tpat_route
      ,p.tpat_direction
      ,p.tpatpt_load_place
      ,p.tpat_via
      ,p.via_desc
      ,p.tpatpt_stop_id
      ,p.tpat_external_id
      ,d.plc_description
      ,p.tpatpt_is_timing_point
order by p.file_row_id



select distinct c.DateCscBooking, c.DateVscType
, c.DateCscTypeTitle, c.DateCscScen, c.filedate
, tr.trp_int_number
, tr.trp_number
, tr.trp_operating_days
, tst.rte_version
, tst.rte_identifier
, tr.tpat_external_id
, tr.trp_type
, tr.trp_type_code
, tr.trp_is_special
, tr.trp_is_public
, tr.tstp_passing_time
, tst.[trppt_stop_id]
, tst.[trp_note_id]
, tst.[trp_second_note_id]
, tst.[trppt_tp_note_id]
, tst.[trppt_tstp_note_id]
into #trips 
from #cal c
join hastus.avl_trp tr on tr.filedate = c.filedate and tr.trp_operating_days = c.DateVscTypeCode
join (
        select t.[trp_number]
        ,t.[trp_int_number]
        ,[trp_oper_days_12]
        ,t.rte_version
        ,t.rte_identifier
        ,p.tpat_external_id
        ,[trppt_stop_id]
        ,[trppt_arrival_time]
        ,[trp_note_id]
        ,[trp_second_note_id]
        ,[trppt_tp_note_id]
        ,[trppt_tstp_note_id] 
        ,t.trppt_is_timing_point
          FROM [ltd_dw].[hastus].[avl_tst] t
           JOIN (SELECT DISTINCT trp_int_number, trp_number, tpat_external_id, trp_operating_days, tstp_passing_time from hastus.avl_trp
                    ) p 
                ON p.trp_int_number = t.trp_int_number 
                    AND p.trp_operating_days = t.trp_oper_days_12 
                    AND p.tstp_passing_time = t.trppt_arrival_time

          where 1=1
        and t.[trppt_stop_id] not like '%ann%' 
        and t.[trppt_stop_id] not like '%arr%' 
        and t.[trppt_stop_id] not like '%anx%' 
        and t.trppt_stop_id = @currStop
        AND p.tpat_external_id = @currExId
        group by 
        t.[trp_number]
        ,t.[trp_int_number]
        ,[trp_oper_days_12]
        ,t.rte_version
        ,t.rte_identifier
        ,p.tpat_external_id
        ,[trppt_stop_id]
        ,[trppt_arrival_time]
        ,[trp_note_id]
        ,[trp_second_note_id]
        ,[trppt_tp_note_id]
        ,[trppt_tstp_note_id]
        ,t.trppt_is_timing_point
         ) tst on tst.[trp_int_number] = tr.trp_int_number
                    and tst.[trppt_arrival_time] = tr.tstp_passing_time
                    and tst.[trp_oper_days_12] = tr.trp_operating_days
                    and tst.rte_version = c.DateCscBooking
                    and tst.trp_oper_days_12 = c.DateVscTypeCode
                    AND tst.tpat_external_id = tr.tpat_external_id
join #pat a on a.DateCscBooking = tst.rte_version 
    AND a.tpat_route = tst.rte_identifier 
    AND a.tpatpt_stop_id = tst.trppt_stop_id 
    AND a.tpat_external_id = tst.tpat_external_id
    AND a.tpat_direction = @currDir
where 1=1


SELECT RankInTimeTablePlace=RANK() OVER (PARTITION BY i.tpat_route, i.trp_operating_days, i.tpatpt_load_place, i.tpat_direction
                                         ORDER BY i.tstp_passing_time), i.DateCscBooking, i.DateVscType, i.DateCscTypeTitle, i.DateCscScen
                                         , i.tpat_route, i.rte_description, i.tpat_direction, i.tpatpt_load_place,i.tpatpt_is_timing_point, i.tpatpt_stop_id
                                         , i.tstp_passing_time, i.tpat_via, i.via_desc, i.tpat_external_id, i.plc_description, i.trp_int_number
                                         , i.trp_number, i.trp_operating_days, i.trp_type, i.trp_type_code, i.trp_is_special, i.trp_is_public
                                         , i.stp_description, i.stp_place, i.loca_intersect_1, i.loca_intersect_2, i.stp_district, i.stp_zone
                                         , i.stp_is_public, i.trp_note_id, i.trp_second_note_id, i.trppt_tp_note_id, i.trppt_tstp_note_id
                                         , i.trp_note_txt, i.trp_second_note_txt, i.trppt_tp_note_txt, i.trppt_tstp_note_txt
INTO #xmlprep
FROM (SELECT p.DateCscBooking, t.DateVscType, t.DateCscTypeTitle, t.DateCscScen, p.tpat_route, r.rte_description, p.tpat_direction
, p.tpatpt_load_place,p.tpatpt_is_timing_point, p.tpatpt_stop_id, t.tstp_passing_time, p.tpat_via, p.via_desc, p.tpat_external_id, p.plc_description, t.trp_int_number
, t.trp_number, t.trp_operating_days, t.trp_type, t.trp_type_code, t.trp_is_special, t.trp_is_public, n.stp_description, n.stp_place, n.loca_intersect_1
, n.loca_intersect_2, n.stp_district, n.stp_zone, n.stp_is_public, t.trp_note_id, t.trp_second_note_id, t.trppt_tp_note_id, t.trppt_tstp_note_id
, o1.note_text trp_note_txt, o2.note_text trp_second_note_txt, o3.note_text trppt_tp_note_txt, o4.note_text trppt_tstp_note_txt
     FROM #pat p
          JOIN #trips t ON t.tpat_external_id=p.tpat_external_id AND t.rte_identifier=p.tpat_route AND t.trppt_stop_id=p.tpatpt_stop_id
          LEFT JOIN hastus.avl_nde n ON n.stp_identifier=t.trppt_stop_id AND n.filedate=t.filedate
          LEFT JOIN hastus.avl_rte r ON r.rte_identifier=t.rte_identifier AND r.filedate=t.filedate
          LEFT JOIN(SELECT note_id, note_text FROM hastus.note WHERE note_usage LIKE '%pub%') o1 ON o1.note_id=t.trp_note_id
          LEFT JOIN(SELECT note_id, note_text FROM hastus.note WHERE note_usage LIKE '%pub%') o2 ON o2.note_id=t.trp_second_note_id
          LEFT JOIN(SELECT note_id, note_text FROM hastus.note WHERE note_usage LIKE '%pub%') o3 ON o3.note_id=t.trppt_tp_note_id
          LEFT JOIN(SELECT note_id, note_text FROM hastus.note WHERE note_usage LIKE '%pub%') o4 ON o4.note_id=t.trppt_tstp_note_id   
     WHERE n.stp_is_public='X' ) i;



SELECT RankInTimetable = rank() over (order by passing)
    , x.tpatpt_load_place
    , x.passing  
    into #rankPlace
    from (select distinct tpatpt_load_place,min(tstp_passing_time) passing from #xmlprep group by tpatpt_load_place) x 


 INSERT #xmlsource(RankInTimetable,RankInTimeTablePlace, DateCscBooking, DateVscType, DateCscTypeTitle, DateCscScen, tpat_route, rte_description, tpat_direction, tpatpt_load_place
 ,tpatpt_is_timing_point, tpatpt_stop_id, tstp_passing_time, tpat_via, via_desc, tpat_external_id, plc_description, trp_int_number, trp_number, trp_operating_days, trp_type, trp_type_code
 , trp_is_special, trp_is_public, stp_description, stp_place, loca_intersect_1, loca_intersect_2, stp_district, stp_zone, stp_is_public, trp_note_id, trp_second_note_id
 , trppt_tp_note_id, trppt_tstp_note_id, trp_note_txt, trp_second_note_txt, trppt_tp_note_txt, trppt_tstp_note_txt)
 SELECT r.RankInTimetable,y.RankInTimeTablePlace, y.DateCscBooking, y.DateVscType, y.DateCscTypeTitle, y.DateCscScen, y.tpat_route, y.rte_description, y.tpat_direction, y.tpatpt_load_place
 , tpatpt_is_timing_point, y.tpatpt_stop_id, y.tstp_passing_time, y.tpat_via, y.via_desc, y.tpat_external_id, y.plc_description, y.trp_int_number, y.trp_number, y.trp_operating_days, y.trp_type
 , y.trp_type_code, y.trp_is_special, y.trp_is_public, y.stp_description, y.stp_place, y.loca_intersect_1, y.loca_intersect_2, y.stp_district, y.stp_zone, y.stp_is_public
 , y.trp_note_id, y.trp_second_note_id, y.trppt_tp_note_id, y.trppt_tstp_note_id, y.trp_note_txt, y.trp_second_note_txt, y.trppt_tp_note_txt, y.trppt_tstp_note_txt
FROM #xmlprep y
     LEFT JOIN #rankPlace r ON r.tpatpt_load_place=y.tpatpt_load_place AND y.tstp_passing_time>=r.passing;


drop table if exists #pat
drop table if exists #trips
drop table if exists #xmlprep
drop table if exists #rankPlace

SELECT @i = @i + 1
IF @i > @r
BREAK
    ELSE CONTINUE
    
    END


DELETE FROM 
hastus.trip_stop_route_time_source_prepared  
output 'DELETE' INTO @outputTbl
WHERE DateCscBooking = @bid

INSERT hastus.trip_stop_route_time_source_prepared(
       [RankInTimetable]
      ,[RankInTimeTablePlace]
      ,[DateCscBooking]
      ,[DateVscType]
      ,[DateCscTypeTitle]
      ,[DateCscScen]
      ,[tpat_route]
      ,[rte_description]
      ,[tpat_direction]
      ,[tpatpt_load_place]
      ,tpatpt_is_timing_point
      ,[tpatpt_stop_id]
      ,[tstp_passing_time]
      ,[trip_stop_arrival_time_result]
      ,[trip_stop_arrival_time_ampm]
      ,[tpat_via]
      ,[via_desc]
      ,[tpat_external_id]
      ,[plc_description]
      ,[trp_int_number]
      ,[trp_number]
      ,[trp_operating_days]
      ,[trp_type]
      ,[trp_type_code]
      ,[trp_is_special]
      ,[trp_is_public]
      ,[stp_description]
      ,[stp_place]
      ,[loca_intersect_1]
      ,[loca_intersect_2]
      ,[stp_district]
      ,[stp_zone]
      ,[stp_is_public]
      ,[trp_note_id]
      ,[trp_second_note_id]
      ,[trppt_tp_note_id]
      ,[trppt_tstp_note_id]
      ,[trp_note_txt]
      ,[trp_second_note_txt]
      ,[trppt_tp_note_txt]
      ,[trppt_tstp_note_txt])
OUTPUT 'INSERT' INTO @outputTbl
SELECT RankInTimetable, RankInTimeTablePlace, DateCscBooking, DateVscType, DateCscTypeTitle, DateCscScen, tpat_route, rte_description, tpat_direction, tpatpt_load_place
, tpatpt_is_timing_point, tpatpt_stop_id, tstp_passing_time, trip_stop_arrival_time_result = SUBSTRING(tstp_passing_time, patindex('%[^0]%', tstp_passing_time+'.'), len(tstp_passing_time))
, trip_stop_arrival_time_ampm = CASE when left(tstp_passing_time, 2)<12 then 'AM' else 'PM' END
, tpat_via, via_desc, tpat_external_id, plc_description, trp_int_number, trp_number, trp_operating_days, trp_type, trp_type_code
, trp_is_special, trp_is_public, stp_description, stp_place, loca_intersect_1, loca_intersect_2, stp_district, stp_zone, stp_is_public, trp_note_id, trp_second_note_id
, trppt_tp_note_id, trppt_tstp_note_id, trp_note_txt, trp_second_note_txt, trppt_tp_note_txt, trppt_tstp_note_txt
FROM #xmlsource
ORDER BY rte_description, tpat_direction,trp_operating_days, tpatpt_stop_id, tstp_passing_time

;


DECLARE @ins INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'INSERT')
DECLARE @upd INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'UPDATE')
DECLARE @del INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'DELETE')
DECLARE @prg varchar(90) = @@SERVERNAME + '.ltd_dw.hastus.trip_stop_route_time_source_prepared' 

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

DROP TABLE IF EXISTS #cal
DROP TABLE IF EXISTS #pat
DROP TABLE IF EXISTS #rankPlace
DROP TABLE IF EXISTS #rteLoop
DROP TABLE IF EXISTS #trips
DROP TABLE IF EXISTS #xmlprep
DROP TABLE IF EXISTS #xmlsource



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
