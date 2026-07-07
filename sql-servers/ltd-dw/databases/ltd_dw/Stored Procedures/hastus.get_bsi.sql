SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [hastus].[get_bsi]

AS

/*-----------LTD_GLOSSARY---------------
created by	:  B Eichberger
created dt	:  2026-04-09
purpose		:  load latest data into hastus.bsi_detail and hastus.bsi_header
			   also will handle station graphics needs
use			:  exec hastus.get_bsi

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


DROP TABLE IF EXISTS #calLoop


/* ----------------------------------
select * from #cal
select * from #pat
select * from #dst
select * from #trips
select * from #calLoop
select * from #rteLimit
select * from #postDesc
select * from #rte_loop
select * from #tp_places
select * from #linkedPlaceRows
select * from #placesWithTimePoints
*/

SELECT rn = ROW_NUMBER() OVER (ORDER BY DateCscBooking, w.filedate), DateCscBooking  , w.filedate
INTO 
--SELECT * FROM 
#calLoop 
FROM (
SELECT DISTINCT DateCscBooking, filedate
FROM hastus.avl_cal
	) w 
	WHERE w.filedate >= '2026-04-07'
ORDER BY w.DateCscBooking, w.filedate

DECLARE @i1 INT = 2
DECLARE @r1 INT = (SELECT MAX(rn) FROM #calLoop )

WHILE @i1 >= @r1

BEGIN


DROP TABLE IF EXISTS #cal
DROP TABLE IF EXISTS #pat
DROP TABLE IF EXISTS #dst
DROP TABLE IF EXISTS #trips
DROP TABLE IF EXISTS #postDesc
DROP TABLE IF EXISTS #rte_loop
DROP TABLE IF EXISTS #rteLimit
DROP TABLE IF EXISTS #tp_places
DROP TABLE IF EXISTS #linkedPlaceRows
DROP TABLE IF EXISTS #placesWithTimePoints

DECLARE @bid VARCHAR(4) = (SELECT DISTINCT DateCscBooking FROM #calLoop WHERE rn = @i1
)
DECLARE @fdt DATE = (SELECT DISTINCT filedate FROM #calLoop WHERE rn = @i1
)


DROP TABLE IF EXISTS #linkedPlaceRows
CREATE TABLE #linkedPlaceRows(
	[file_row_ID] [INT] NOT NULL,
	[tpat_route] [NVARCHAR](5) NULL,
	[tpatpt_stop_id] [NVARCHAR](8) NULL,
	[tpat_external_id] [NVARCHAR](4) NULL,
	[ParentGroupID] [INT] NULL,
	[EffectiveParentID] [INT] NULL
) 


SELECT rn=ROW_NUMBER() OVER (ORDER BY file_row_id ), * INTO #rteLimit
FROM (SELECT DISTINCT file_row_id, tpat_route, tpat_external_id, tpat_direction, tpatpt_stop_id, tpatpt_load_place -- SELECT * 
FROM hastus.avl_pat 
      WHERE ISNUMERIC(tpat_route)=1 AND filedate = @fdt ) g


SELECT DISTINCT filedate, DateCscScen, DateCscBooking
, DateVscType,DateVscTypeCode = CASE DateVscType 
            WHEN 0 THEN '12345'
            WHEN 5 then '6'
            WHEN 6 then '7' ELSE DateVscType END 
    ,DateCscTypeTitle, DateVscScen 
    into #cal
    from hastus.avl_cal where DateCscBooking = @bid AND filedate = @fdt

DROP TABLE IF EXISTS #pat            
select c.DateCscBooking, p.file_row_id
,p.tpat_route
,p.tpat_external_id
,p.tpat_direction
,p.tpat_veh_display
,p.tpat_in_serv
,p.tpat_via
,p.via_desc
,p.tpatpt_stop_id
,p.tpatpt_load_place
,p.tpatpt_veh_display_code
,p.tpatpt_is_timing_point
into #pat
from #cal c 
JOIN hastus.avl_pat p ON c.filedate = p.filedate
JOIN #rteLimit r ON r.tpat_route = p.tpat_route -- here to limit avl_pat to the rte list 
    where 1=1
 and p.tpatpt_stop_id not like '%ann%' 
 and p.tpatpt_stop_id not like '%arr%' 
 and p.tpatpt_stop_id not like '%anx%'
group by c.DateCscBooking, p.file_row_id
,p.tpat_route
,p.tpat_external_id
,p.tpat_direction
,p.tpat_veh_display
,p.tpat_in_serv
,p.tpat_via
,p.via_desc
,p.tpatpt_stop_id
,p.tpatpt_load_place
,p.tpatpt_veh_display_code
,p.tpatpt_is_timing_point
order by p.file_row_id

--SELECT * FROM #pat

SELECT rn = ROW_NUMBER() OVER (ORDER BY u.tpat_route),tpat_route 
INTO #rte_loop 
FROM (SELECT DISTINCT  tpat_route FROM #pat) u

--SELECT * FROM #rte_loop


DECLARE @currRte VARCHAR(8)
DECLARE @i INT = 1
DECLARE @r INT = (SELECT MAX(rn) FROM #rte_loop)

WHILE @i <= @r
BEGIN

SELECT @currRte = (SELECT DISTINCT tpat_route FROM #rte_loop WHERE rn = @i )


DROP TABLE IF EXISTS #tp_places
SELECT DISTINCT
    file_row_ID,tpat_route,tpatpt_stop_id,tpat_external_id,
    CASE WHEN ISNULL(tpatpt_is_timing_point,'') = 'X' THEN file_row_id ELSE NULL END AS ParentGroupID
INTO -- SELECT * FROM 
#tp_places
FROM #pat t
WHERE t.tpat_route = @currRte

INSERT #linkedPlaceRows(
[file_row_ID]
,[tpat_route]
,[tpatpt_stop_id]
,[tpat_external_id]
,[ParentGroupID]
,[EffectiveParentID]
)
SELECT 
    file_row_ID, l.tpat_route, l.tpatpt_stop_id, l.tpat_external_id, l.ParentGroupID,
    -- "Fill down" the ParentGroupID to all rows below it until the next PAT
    MAX(ISNULL(ParentGroupID,0)) OVER (ORDER BY file_row_ID ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS EffectiveParentID
FROM #tp_places l 
ORDER BY l.file_row_id


DROP TABLE IF EXISTS #tp_places;

SELECT @i = @i + 1

IF @i > @r
BREAK
    ELSE CONTINUE
    END

SELECT DISTINCT i.*,c.plc_description 
	  INTO -- SELECT * FROM 
	  #placesWithTimePoints 
FROM (
SELECT t.DateCscBooking
	  ,t.file_row_id
	  ,t.tpat_route
	  ,t.tpat_external_id
	  ,t.tpat_direction
	  ,t.tpat_veh_display
	  ,t.tpat_in_serv
	  ,t.tpat_via
	  ,t.via_desc
	  ,t.tpatpt_stop_id
	  ,t.tpatpt_load_place
	  ,t.tpatpt_veh_display_code
	  ,t.tpatpt_is_timing_point
	  ,p.EffectiveParentID AS time_from_file_row_id
	  ,o.tpatpt_load_place time_from_point
FROM #linkedPlaceRows p
JOIN #pat t ON t.tpat_route = p.tpat_route
		   AND t.tpatpt_stop_id = p.tpatpt_stop_id
JOIN (SELECT DISTINCT file_row_id,tpatpt_load_place FROM #pat 
		WHERE LEN(RTRIM(LTRIM(tpatpt_load_place)))>0
		AND tpatpt_is_timing_point = 'X') o ON o.file_row_id = p.EffectiveParentID
		) i
LEFT JOIN -- SELECT * FROM 
	hastus.avl_plc c ON c.plc_identifier = i.time_from_point AND c.filedate = @fdt
ORDER BY i.file_row_ID

------------------------------

SELECT
    p.poster_stop_id,p.poster_description,
    trim(x.value('.', 'varchar(50)')) AS poster_route
INTO #postDesc -- select * 
FROM hastus.avl_pbs p
CROSS APPLY (
    SELECT CAST(
        '<x>' + REPLACE(p.poster_route, ',', '</x><x>') + '</x>' 
        AS XML
    ) xml_data 
) t
CROSS APPLY t.xml_data.nodes('/x') s(x);



-------------------------------


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
INTO -- SELECT * FROM 
	#trips
FROM [ltd_dw].[hastus].[avl_tst] t
JOIN (SELECT DISTINCT trp_int_number, trp_number, tpat_external_id, trp_operating_days, tstp_passing_time -- select * 
			FROM hastus.avl_trp WHERE filedate = @fdt
        ) p 
    ON p.trp_int_number = t.trp_int_number 
        AND p.trp_operating_days = t.trp_oper_days_12 
        AND p.tstp_passing_time = t.trppt_arrival_time
where 1=1
AND t.filedate = @fdt
and t.[trppt_stop_id] not like '%ann%' 
and t.[trppt_stop_id] not like '%arr%' 
and t.[trppt_stop_id] not like '%anx%' 
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

---------- 
DELETE FROM hastus.bsi_detail WHERE rte_version = @bid

INSERT hastus.bsi_detail(
[trp_number]
,[trp_int_number]
,[trp_oper_days_12]
,[rte_version]
,[rte_identifier]
,[rte_description]
,[tpat_external_id]
,[trppt_stop_id]
,[trppt_arrival_time]
,[trp_note_id]
,[trp_second_note_id]
,[trppt_tp_note_id]
,[trppt_tstp_note_id]
,[DateCscBooking]
,[file_row_id]
,[tpat_route]
,[tpat_direction]
,[tpat_veh_display]
,[tpat_in_serv]
,[tpat_via]
,[via_desc]
,[tpatpt_stop_id]
,[tpatpt_load_place]
,[tpatpt_veh_display_code]
,[tpatpt_is_timing_point]
,[time_from_point]
,[plc_description]
,poster_description)
OUTPUT 'INSERT' INTO @outputTbl
SELECT distinct t.trp_number
	  ,t.trp_int_number
	  ,t.trp_oper_days_12
	  ,t.rte_version
	  ,t.rte_identifier
	  ,r.rte_description
	  ,t.tpat_external_id
	  ,t.trppt_stop_id
	  ,t.trppt_arrival_time
	  ,t.trp_note_id
	  ,t.trp_second_note_id
	  ,t.trppt_tp_note_id
	  ,t.trppt_tstp_note_id
	  ,p.DateCscBooking
	  ,p.file_row_id
	  ,p.tpat_route
	  ,p.tpat_direction
	  ,p.tpat_veh_display
	  ,p.tpat_in_serv
	  ,p.tpat_via
	  ,p.via_desc
	  ,p.tpatpt_stop_id
	  ,p.tpatpt_load_place
	  ,p.tpatpt_veh_display_code
	  ,p.tpatpt_is_timing_point
	  ,p.time_from_point
	  ,p.plc_description 
	  ,s.poster_description
FROM #trips t
JOIN #placesWithTimePoints p ON p.tpat_route = t.rte_identifier AND p.tpatpt_stop_id = t.trppt_stop_id AND p.tpat_external_id = t.tpat_external_id
JOIN hastus.avl_rte r ON r.rte_identifier = t.rte_identifier AND r.filedate = @fdt
JOIN #postDesc s ON s.poster_stop_id = t.trppt_stop_id 
ORDER BY trp_oper_days_12, trppt_arrival_time



DECLARE @ins INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'INSERT')
DECLARE @upd INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'UPDATE')
DECLARE @del INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'DELETE')
DECLARE @prg varchar(90) = @@SERVERNAME + '.ltd_dw.hastus.get_bsi' 

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
SELECT 'BSID',
'ltd_dw.hastus.bsi_detail',
'HASTUS',
@prg,
ISNULL(@ins,0) ,ISNULL(@upd,0),ISNULL(@del,0),
@sdt,
SYSDATETIME()

DELETE FROM @outputTbl

---------- get the pattern names and fill up the header table with current bid (processing latest)
DELETE FROM hastus.bsi_headers WHERE [rte_version] = @bid

SELECT DISTINCT ppat_id
,ppat_direction
,LTRIM(RTRIM(LEFT(ppat_description,3))) rte
,ppat_description
INTO #dst
FROM ltd_dw.hastus.avl_pnm 
WHERE filedate = @fdt
--(SELECT MAX(filedate) FROM ltd_dw.hastus.avl_pnm)
AND ppat_public_access = 'X'

INSERT -- SELECT * FROM 
hastus.bsi_headers(
	   [rte_version]
      ,[trppt_stop_id]
      ,[tpat_route]
      ,[rte_description]
      ,[time_from_point]
	  ,[ppat_description])
OUTPUT 'INSERT' INTO @outputTbl
SELECT DISTINCT rte_version,trppt_stop_id,tpat_route,rte_description,time_from_point
,t.ppat_description
FROM hastus.bsi_detail d
LEFT JOIN #dst t ON t.rte = d.rte_identifier AND t.ppat_direction = d.tpat_direction
WHERE rte_version = @bid




select @ins = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'INSERT')
select @upd = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'UPDATE')
select @del = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'DELETE')
select @prg = @@SERVERNAME + '.ltd_dw.hastus.get_bsi' 

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
SELECT 'BSIH',
'ltd_dw.hastus.bsi_headers',
'HASTUS',
@prg,
ISNULL(@ins,0) ,ISNULL(@upd,0),ISNULL(@del,0),
@sdt,
SYSDATETIME()


drop table if exists #cal
drop table if exists #pat
DROP TABLE IF EXISTS #dst
DROP TABLE IF EXISTS #trips
DROP TABLE IF EXISTS #postDesc
drop table if exists #rte_loop
DROP TABLE IF EXISTS #tp_places
DROP TABLE IF EXISTS #linkedPlaceRows
DROP TABLE IF EXISTS #placesWithTimePoints

SELECT @i1 =@i1 + 1
IF @i1 > @r1
BREAK
	ELSE CONTINUE
END


DROP TABLE IF EXISTS #rteLimit
DROP TABLE IF EXISTS #calLoop

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
