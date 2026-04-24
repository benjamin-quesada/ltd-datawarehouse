SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   PROCEDURE [nf].[get_newflyer_with_transit_master] (
	@startDateInt INT)
AS

/******************************************
exec nf.get_newflyer_with_transit_master 120211107



*/
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

 
IF (SELECT COUNT(*) FROM tempdb.sys.tables WHERE name LIKE '%OutputTbl9957%') <> 0
BEGIN
DROP TABLE #OutputTbl9957
END

create table #OutputTbl9957 (ActionName varchar(32))

declare @workstartdt datetime2 = sysdatetime()


  -- select * from #dttable

  --declare @i int 
  --declare @r int
  --declare @currdtInt INT
  declare @currdtIntFrom VARCHAR(32)
  declare @currdtIntTo VARCHAR(32)
  --select @i = 1
  --select @r = (select max(rn) from #dttable)

--while @i <= @r
--BEGIN

SELECT @currdtIntFrom = CAST(CAST(@startDateInt AS VARCHAR(32))+'000000' AS BIGINT)
SELECT @currdtIntTo   = CAST(CAST(@startDateInt AS VARCHAR(32))+'999999' AS BIGINT)
;
WITH nfdata AS (
		SELECT o.drive_id,
			   o.license_number,
			   o.cal_nf_key,
			   o.latitude,
			   o.longitude FROM (
			SELECT 'event' AS recSource,
				   [drive_id],
				   [event_id] AS recSourceId,
				   [vehicle_id],
				   [license_number],
				   cal_nf_key = CAST(100000000+CAST(CONVERT(VARCHAR(32), CAST([event_time] AS DATETIME),112) AS INT) AS VARCHAR(32)) + RIGHT('000000'+CAST([dbo].[F_DATE_TO_SEC_SINCE_MIDNITE]([event_time]) AS varchar(32)),6), 
				   latitude,
				   longitude
			  FROM [ltd_dw].[dbo].[newflyer_events]
			 WHERE latitude <> 0 
			 AND CAST(100000000+CAST(CONVERT(VARCHAR(32), CAST([event_time] AS DATETIME),112) AS INT) AS VARCHAR(32)) + RIGHT('000000'+CAST([dbo].[F_DATE_TO_SEC_SINCE_MIDNITE]([event_time]) AS varchar(32)),6) >= @currdtIntFrom
			 AND CAST(100000000+CAST(CONVERT(VARCHAR(32), CAST([event_time] AS DATETIME),112) AS INT) AS VARCHAR(32)) + RIGHT('000000'+CAST([dbo].[F_DATE_TO_SEC_SINCE_MIDNITE]([event_time]) AS varchar(32)),6) <= @currdtIntTo
			 UNION
			SELECT 'vehParam',
				   [drive_id],
				   vehparamKey,
				   [vehicle_id],
				   [license_number],
				   --start_time,
				   datetimekey = CAST(100000000+CAST(CONVERT(VARCHAR(32), CAST(start_time AS DATETIME),112) AS INT) AS VARCHAR(32)) + RIGHT('000000'+CAST([dbo].[F_DATE_TO_SEC_SINCE_MIDNITE](start_time) AS varchar(32)),6),
				   start_latitude,
				   start_longitude -- select top(100) * 
			  FROM [dbo].[newflyer_vehparams]
			 WHERE start_latitude <> 0
			 AND CAST(100000000+CAST(CONVERT(VARCHAR(32), CAST(start_time AS DATETIME),112) AS INT) AS VARCHAR(32)) + RIGHT('000000'+CAST([dbo].[F_DATE_TO_SEC_SINCE_MIDNITE](start_time) AS varchar(32)),6) >= @currdtIntFrom
			 AND CAST(100000000+CAST(CONVERT(VARCHAR(32), CAST(start_time AS DATETIME),112) AS INT) AS VARCHAR(32)) + RIGHT('000000'+CAST([dbo].[F_DATE_TO_SEC_SINCE_MIDNITE](start_time) AS varchar(32)),6) <= @currdtIntTo
			 UNION
			 SELECT 'vehVehicle',
				   [current_drive],
				   [vehicledata1Key],
				   [vehicle_id],
				   [license_nmbr],
				   --[last_communication_time],
				   datetimekey = CAST(100000000+CAST(CONVERT(VARCHAR(32), CAST([last_communication_time] AS DATETIME),112) AS INT) AS VARCHAR(32)) + RIGHT('000000'+CAST([dbo].[F_DATE_TO_SEC_SINCE_MIDNITE]([last_communication_time]) AS varchar(32)),6),
				   [latitude],
				   [longitude] -- select top(100) * 
			  FROM [dbo].[newflyer_vehicledata1]
			   WHERE [latitude] <> 0 AND [current_drive] <> 0 
			   AND CAST(100000000+CAST(CONVERT(VARCHAR(32), CAST([last_communication_time] AS DATETIME),112) AS INT) AS VARCHAR(32)) + RIGHT('000000'+CAST([dbo].[F_DATE_TO_SEC_SINCE_MIDNITE]([last_communication_time]) AS varchar(32)),6) >= @currdtIntFrom
			   AND CAST(100000000+CAST(CONVERT(VARCHAR(32), CAST([last_communication_time] AS DATETIME),112) AS INT) AS VARCHAR(32)) + RIGHT('000000'+CAST([dbo].[F_DATE_TO_SEC_SINCE_MIDNITE]([last_communication_time]) AS varchar(32)),6) <= @currdtIntTo
			) o
		)

INSERT [nf].[prepared_tm_data_for_cte]
([calendar_id]
      ,[TRIP_END_TIME]
      ,[cal_spm_key]
      ,[cal_arr_key]
      ,[cal_dep_key]
      ,[cal_nf_key]
      ,[drive_id]
      ,[the_bus]
      ,[block_id]
      ,[block]
      ,[trip_id]
      ,[actual_duration]
      ,[rte]
      ,[rte_dir]
      ,[operator]
      ,[minOdo_TransitMaster]
      ,[maxOdo_TransitMaster])
OUTPUT 'INSERTED' into #OutputTbl9957
SELECT calendar_id,
	   p.TRIP_END_TIME,
	   cal_spm_key = CAST(v.calendar_id AS varchar(32)) + RIGHT('000000'+CAST(p.TRIP_END_TIME AS varchar(32)),6),
	   cal_arr_key = CAST(v.calendar_id AS varchar(32)) + RIGHT('000000'+CAST(v.[actual_arrival_spm] AS varchar(32)),6),
	   cal_dep_key = CAST(v.calendar_id AS varchar(32)) + RIGHT('000000'+CAST(v.[actual_departure_spm] AS varchar(32)),6),
	   n.cal_nf_key,
	   n.drive_id,
       the_bus,
       block_id,
       block,
       v.trip_id,
       SUM(v.[actual_departure_spm] - v.[actual_arrival_spm]) actual_duration,
       rte,
       rte_dir,
       operator,
       MIN(odometer) minOdo_TransitMaster,
       MAX(odometer) maxOdo_TransitMaster
  FROM [LTD-TMDATA].ltd_db.dbo.adherence_v v
  JOIN [LTD-TMDATA].tmdatamart.dbo.TRIP p ON p.TRIP_ID = v.trip_id
  JOIN nfdata n ON n.cal_nf_key BETWEEN CAST(v.calendar_id AS varchar(32)) + RIGHT('000000'+CAST(v.[actual_arrival_spm] AS varchar(32)),6)
							AND CAST(v.calendar_id AS varchar(32)) + RIGHT('000000'+CAST(v.[actual_departure_spm] AS varchar(32)),6) 
							AND n.license_number = v.the_bus
 WHERE 1=1
   AND the_bus like '202[0-9][0-9]%'
   AND v.trip_id IS NOT NULL
   AND v.calendar_id = @startDateInt
   AND (v.actual_arrival_spm IS NOT NULL AND v.actual_departure_spm IS NOT NULL)
 GROUP BY calendar_id,
		  p.TRIP_END_TIME,
          the_bus,
          block_id,
          [block],
          v.trip_id,
          trip_start,
          [trip_end_sql],
          rte,
          rte_dir,
          operator,
		  CAST(v.calendar_id AS varchar(32)) + RIGHT('000000'+CAST(v.[actual_departure_spm] AS varchar(32)),6),
		  CAST(v.calendar_id AS varchar(32)) + RIGHT('000000'+CAST(v.[actual_arrival_spm] AS varchar(32)),6),
		  n.drive_id,
		  n.cal_nf_key
--ORDER BY v.trip_id


declare @n int = (select isnull(count(*),0) from #OutputTbl9957 WITH (NOLOCK) where ActionName = 'INSERTED' group by ActionName )


-- clean up merge log in case some previous processing did not complete
update ltd_dw.[process].[MergeLogs]
SET [recInsert] = 0
,recDelete = 0
,recUpdate = 0 
,MergeEndDatetime = @workstartdt
where [MergeBeginDatetime] is not null 
and MergeEndDatetime is null 
and MergeCode = 'TTMM'
and [ObjectDestination] = 'ltd_dw.nf.prepared_tm_data_for_cte'


 insert ltd_dw.[process].[MergeLogs] (
	   [MergeCode]
      ,[ObjectDestination]
      ,[ObjectSource]
      ,[ObjectProgram]
      ,[recInsert]
      ,[recUpdate]
      ,[recDelete]
      ,[MergeBeginDatetime]
	  ,[MergeEndDatetime])
	  Values(
	  'TTMM', 'ltd_dw.nf.prepared_tm_data_for_cte','TM','ltd_dw.nf.get_newflyer_with_transit_master',isnull(@n,0), 0, 0, @workstartdt, sysdatetime())




--select @i = @i + 1

--if @i > @r
--BREAK
--	ELSE CONTINUE

--END

END TRY	  

BEGIN CATCH

       DECLARE @profile VARCHAR(255) = 	(
                    SELECT NAME
                    FROM msdb.dbo.sysmail_profile
					WHERE name LIKE '%sqldata%'
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
             ,@recipients = 'barb.eichberger@ltd.org' --;servicedesk@ltd.org
             ,@subject = @sub
             ,@body = @errormsg;

       RAISERROR (
                    @errormsg
                    ,@errsev
                    ,1
                    )
END CATCH
GO
