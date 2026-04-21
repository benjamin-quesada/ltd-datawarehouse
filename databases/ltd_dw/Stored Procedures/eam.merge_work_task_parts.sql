SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [eam].[merge_work_task_parts]
AS
/*------------LTD_GLOSSARY-----------------

CREATED		20260303
AUTHOR		B Eichberger
PURPOSE		Prepares data and merges into [eam].[work_order_parts_detail]
			Provide source data for eam_model and other reporting; 
USE         exec eam.merge_work_task_parts
			
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

BEGIN TRY

												
DECLARE @sdt DATETIME2 = SYSDATETIME()
DECLARE @outputTbl TABLE (actionNm VARCHAR(32));


drop table if exists #yrFrom
select YEAR(GETDATE()) - 12 as yrFrom into #yrFrom

truncate table wrk.work_order_part_prep

insert -- select * from 
wrk.work_order_part_prep (
[work_order_yr]
      ,[work_order_no]
      ,[wo_yr_no_tsk]
      ,[work_order_yr_no]
      ,[row_id]
      ,[vehicle_number]
      ,[WorkorderVehicleKey]
      ,[PART_part_no]
      ,[part_suffix]
      ,[part_keyword]
      ,[part_description]
      ,[part_description_short]
      ,[task_account_id]
      ,[qty_issued]
      ,[request_qty]
      ,[TASK_task_code]
      ,[issued_cal_id]
      ,[part_account_id]
      ,[unit_issue_price]
      ,[unit_price_calculated]
      ,[issued_value]
      ,[posting_complete]
      ,[parts_cost]
      ,[meter_1_reading]
      ,[lastPartMileage]
      ,[milesSinceLastPart]
)
select CAST(ISNULL(pd.work_order_yr, YEAR(pd.X_datetime_insert)) AS VARCHAR(12)) work_order_yr
,ISNULL(pd.work_order_no, -1) work_order_no
,CAST(ISNULL(pd.work_order_yr, YEAR(pm.X_datetime_insert)) AS VARCHAR(12)) + '-' + CAST(ISNULL(pd.work_order_no, -1) AS VARCHAR(12))+'-'+pd.TASK_task_code as wo_yr_no_tsk
,CAST(ISNULL(pd.work_order_yr, YEAR(pm.X_datetime_insert)) AS VARCHAR(12)) + '-' + CAST(ISNULL(pd.work_order_no, -1) AS VARCHAR(12)) work_order_yr_no
,pd.row_id
,pd.EQ_equip_no vehicle_number
,CAST(ISNULL(pd.work_order_yr, YEAR(pm.X_datetime_insert)) AS VARCHAR(12)) + '-' + CAST(ISNULL(pd.work_order_no, -1) AS VARCHAR(12)) + '-' + pd.EQ_equip_no AS WorkorderVehicleKey
,pd.PART_part_no
,pd.part_suffix
,pm.description_keyword AS part_keyword
,REPLACE(pm.[description], 'ý', '') [part_description]
,REPLACE(pm.description_short, 'ý', '') [part_description_short]
,tm.ACCT_acct_code task_account_id
,pd.qty_issued
,pd.qty_issued as request_qty
,isnull(pd.TASK_task_code,'-1') [TASK_task_code]
,issued_cal_id = cast(convert(varchar(32), pd.issue_date, 112) as int) + 100000000
,pd.ACCT_acct_code part_account_id
,pd.unit_issue_price
,unit_price_calculated = case when pd.work_order_yr <= 2018 then pd.total_cost/pd.qty_issued else pd.unit_issue_price end
,pd.unit_issue_price as issued_value
,pd.posting_complete
,parts_cost = pd.total_cost
,pd.meter_1_reading
,lag(pd.meter_1_reading) over (partition by pd.EQ_equip_no
							  ,pd.[PART_part_no]
							   order by pd.issue_date
							  ) lastPartMileage
,pd.meter_1_reading - lag(pd.meter_1_reading) over (partition by pd.EQ_equip_no
												   ,pd.[PART_part_no]
													ORDER BY pd.issue_date
												   ) milesSinceLastPart -- select * 
from [ltd-eam].proto.emsdba.PTD_MAIN pd
	 JOIN #yrFrom y ON pd.work_order_yr >= y.yrFrom
					  and pd.work_order_yr <= year(getdate())
	 join [ltd-eam].proto.emsdba.JOB_MAIN j on j.work_order_yr = pd.work_order_yr and j.work_order_no = pd.work_order_no
	 join [ltd-eam].proto.[emsdba].[PTS_MAIN] pm with (nolock) on pd.[PART_part_no] = pm.PART_part_no
														AND pd.part_suffix = pm.part_suffix
	 LEFT JOIN [ltd-eam].proto.emsdba.[TSK_MAIN] tm WITH (NOLOCK) ON pd.work_order_yr = tm.work_order_yr
														   AND pd.[work_order_no] = tm.[work_order_no]
														   AND pd.[TASK_task_code] = tm.[TASK_task_code]
WHERE pd.fully_reversed = 'N'
	  AND pd.return_flag <> 'Y'
	  AND j.work_order_status = 'CLOSED'
      AND NOT (pd.work_order_yr = 2013 AND pd.work_order_no = 2)

---------------------------------
---------------------------------

merge eam.work_order_parts_detail t
using wrk.work_order_part_prep s
on (t.[wo_yr_no_tsk] = s.[wo_yr_no_tsk]
and t.WorkorderVehicleKey=s.WorkorderVehicleKey
and t.PART_part_no = s.PART_part_no
and t.part_suffix = s.part_suffix
and t.[issued_cal_id] = s.[issued_cal_id]
and t.row_id = s.row_id
)
when matched and 
(
    ISNULL(t.vehicle_number,'') <> ISNULL(s.vehicle_number,'') 
 OR ISNULL(t.WorkorderVehicleKey,'') <> ISNULL(s.WorkorderVehicleKey,'') 
 OR ISNULL(t.part_keyword,'') <> ISNULL(s.part_keyword,'') 
 OR ISNULL(t.part_description,'') <> ISNULL(s.part_description,'') 
 or isnull(t.vehicle_number,'') <> isnull(s.vehicle_number,'')
 OR ISNULL(t.part_description_short,'') <> ISNULL(s.part_description_short,'') 
 OR ISNULL(t.task_account_id,'') <> ISNULL(s.task_account_id,'') 
 OR ISNULL(t.qty_issued,'') <> ISNULL(s.qty_issued,'') 
 OR ISNULL(t.request_qty,'') <> ISNULL(s.request_qty,'') 
 OR ISNULL(t.part_account_id,'') <> ISNULL(s.part_account_id,'') 
 OR ISNULL(t.unit_issue_price,'') <> ISNULL(s.unit_issue_price,'') 
 OR ISNULL(t.unit_price_calculated,'') <> ISNULL(s.unit_price_calculated,'') 
 OR ISNULL(t.issued_value,'') <> ISNULL(s.issued_value,'') 
 OR ISNULL(t.posting_complete,'') <> ISNULL(s.posting_complete,'') 
 OR ISNULL(t.parts_cost,'') <> ISNULL(s.parts_cost,'') 
 OR ISNULL(t.meter_1_reading,'') <> ISNULL(s.meter_1_reading,'') 
 OR ISNULL(t.lastPartMileage,'') <> ISNULL(s.lastPartMileage,'') 
 OR ISNULL(t.milesSinceLastPart,'') <> ISNULL(s.milesSinceLastPart,'') 
)
then update
set t.part_keyword=s.part_keyword
 ,t.part_description=s.part_description
 ,t.part_description_short=s.part_description_short
 ,t.task_account_id=s.task_account_id
 ,t.qty_issued=s.qty_issued
 ,t.request_qty=s.request_qty
 ,t.part_account_id=s.part_account_id
 ,t.unit_issue_price=s.unit_issue_price
 ,t.unit_price_calculated=s.unit_price_calculated
 ,t.issued_value=s.issued_value
 ,t.posting_complete=s.posting_complete
 ,t.parts_cost=s.parts_cost
 ,t.meter_1_reading=s.meter_1_reading
 ,t.lastPartMileage=s.lastPartMileage
 ,t.milesSinceLastPart=s.milesSinceLastPart
 ,t.record_updated_date=sysdatetime()
when not matched by target then insert
(work_order_yr
 ,work_order_no
 ,wo_yr_no_tsk
 ,work_order_yr_no
 ,row_id
 ,vehicle_number
 ,WorkorderVehicleKey
 ,PART_part_no
 ,part_suffix
 ,part_keyword
 ,part_description
 ,part_description_short
 ,task_account_id
 ,qty_issued
 ,request_qty
 ,TASK_task_code
 ,issued_cal_id
 ,part_account_id
 ,unit_issue_price
 ,unit_price_calculated
 ,issued_value
 ,posting_complete
 ,parts_cost
 ,meter_1_reading
 ,lastPartMileage
 ,milesSinceLastPart)
 values
 (
 s.work_order_yr
 ,s.work_order_no
 ,s.wo_yr_no_tsk
 ,s.work_order_yr_no
 ,s.row_id
 ,s.vehicle_number
 ,s.WorkorderVehicleKey
 ,s.PART_part_no
 ,s.part_suffix
 ,s.part_keyword
 ,s.part_description
 ,s.part_description_short
 ,s.task_account_id
 ,s.qty_issued
 ,s.request_qty
 ,s.TASK_task_code
 ,s.issued_cal_id
 ,s.part_account_id
 ,s.unit_issue_price
 ,s.unit_price_calculated
 ,s.issued_value
 ,s.posting_complete
 ,s.parts_cost
 ,s.meter_1_reading
 ,s.lastPartMileage
 ,s.milesSinceLastPart)
 when not matched by source then update set action_name = 'DELETE'
OUTPUT $action INTO @outputTbl;


DECLARE @ins INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'INSERT')
DECLARE @upd INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'UPDATE')
DECLARE @del INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'DELETE')
DECLARE @prg varchar(90) = @@SERVERNAME + '.ltd_dw.eam.merge_work_task_parts'

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
SELECT 'WOPARTS',
'ltd_dw.eam.work_order_parts_detail',
'EAM',
@prg,
ISNULL(@ins,0) ,ISNULL(@upd,0),ISNULL(@del,0),
@sdt,
SYSDATETIME()

drop table if exists #yrFrom
truncate table wrk.work_order_part_prep




END TRY	  


BEGIN CATCH

       DECLARE @profile VARCHAR(255) = (
                    SELECT NAME
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
