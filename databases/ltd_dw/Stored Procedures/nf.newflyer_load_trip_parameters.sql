SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   PROCEDURE [nf].[newflyer_load_trip_parameters]
as

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

DECLARE @sdt datetime2 = SYSDATETIME()
declare @insCount INT = 0 

DECLARE @i INT = 1
DECLARE @r INT = (SELECT MAX(tp1LoadKey) FROM [nf].[newflyer_trip_parameters_stage] )

WHILE @i <= @r
BEGIN

DECLARE @json nvarchar(max)  = N''
SELECT @json = @json + (SELECT response FROM [nf].[newflyer_trip_parameters_stage] WHERE [tp1LoadKey] = @i)
INSERT [nf].[newflyer_trip parameters] (
[vehicle_id],
[unit_id],
[group_id],
[group_name],
[client_id],
[unit_serial],
[license_number],
[chassis_number],
[last_communication_time],
[last_communication_time_local],
[last_position_time],
[last_position_time_local],
[latitude],
[longitude],
[speed],
[direction],
[status],
[last_event_time],
[last_event_time_local],
[last_event_type],
[current_driver],
[current_driver_number],
[driver_name],
[worker_id],
[drive_id],
[last_mileage],
record_created_date)
SELECT CAST(vehicle_id AS INT) vehicle_id,
       unit_id,
       group_id,
       group_name,
       client_id,
       unit_serial,
       license_nmbr AS [license_number],
       [chassis_number],
       CONVERT(DATETIME2(0), CAST(REPLACE([last_communication_time], '%3A', ':') AS DATETIME2)) last_communication_time,
       CONVERT(
           DATETIME2(0),
           CAST(REPLACE([last_communication_time], '%3A', ':') AS DATETIME2)AT TIME ZONE 'UTC' AT TIME ZONE 'Pacific Standard Time') last_communication_time_local,
       CONVERT(DATETIME2(0), CAST(REPLACE([last_position_time], '%3A', ':') AS DATETIME2)) [last_position_time],
       CONVERT(
           DATETIME2(0),
           CAST(REPLACE([last_position_time], '%3A', ':') AS DATETIME2)AT TIME ZONE 'UTC' AT TIME ZONE 'Pacific Standard Time') last_position_time_local,
       [latitude],
       [longitude],
       [speed],
       [direction],
       [status],
       CONVERT(DATETIME2(0), CAST(REPLACE([last_event_time], '%3A', ':') AS DATETIME2)) [last_event_time],
       CONVERT(
           DATETIME2(0),
           CAST(REPLACE([last_event_time], '%3A', ':') AS DATETIME2)AT TIME ZONE 'UTC' AT TIME ZONE 'Pacific Standard Time') last_event_time_time_local,
       dbo.fn_ProperCase(last_event_type) last_event_type,
       [current_driver],
       [current_driver_number],
       [driver_name],
       [worker_id],
       [current_drive],
       [last_mileage],
       @sdt
  FROM OPENJSON(@json, '$.properties.data')
WITH (vehicle_id NVARCHAR(32) '$.vehicle_id'
      ,unit_id NVARCHAR(32) '$.unit_id'
      ,group_id NVARCHAR(32) '$.group_id'
      ,group_name NVARCHAR(32) '$.group_name'
      ,client_id NVARCHAR(32) '$.client_id'
      ,unit_serial NVARCHAR(32) '$.unit_serial'
      ,license_nmbr NVARCHAR(32) '$.license_nmbr'
      ,chassis_number NVARCHAR(32) '$.chassis_number'
      ,last_communication_time NVARCHAR(32) '$.last_communication_time'
      ,last_position_time NVARCHAR(32) '$.last_position_time'
      ,latitude NVARCHAR(32) '$.latitude'
      ,longitude NVARCHAR(32) '$.longitude'
      ,[speed] NVARCHAR(32) '$.speed'
      ,direction NVARCHAR(32) '$.direction'
      ,[status] NVARCHAR(32) '$.status'
      ,last_event_time NVARCHAR(32) '$.last_event_time'
      ,last_event_type NVARCHAR(32) '$.last_event_type'
      ,current_driver NVARCHAR(32) '$.current_driver'
      ,current_driver_number NVARCHAR(32) '$.current_driver_number'
      ,driver_name NVARCHAR(32) '$.driver_name'
      ,worker_id NVARCHAR(32) '$.worker_id'
      ,current_drive NVARCHAR(32) '$.current_drive'
      ,last_mileage NVARCHAR(32) '$.last_mileage'
	  ) o
WHERE NOT EXISTS (SELECT 1 FROM nf.newflyer_trip_parameters WHERE
				o.current_drive = drive_id AND o.vehicle_id = vehicle_id
)

SELECT @i = @i + 1
IF @i > @r
BREAK
	ELSE CONTINUE

END

select @insCount = @insCount + (select count(distinct drive_id) from [nf].[newflyer_trip_parameters] where record_created_date = @sdt)


insert process.mergeLogs
(		[MergeCode]
           ,[ObjectDestination]
           ,[ObjectSource]
           ,[ObjectProgram]
           ,[recInsert]
           ,[recUpdate]
           ,[recDelete]
           ,[MergeBeginDatetime]
           ,[MergeEndDatetime])
select 'NFVD',
'ltd_dw.nf.newflyer_trip_parameters',
'NFAPI',
'SSIS_ISC_PROCESS_NewFlyer_GetNewFlyerTripParameters' ,
isnull(@insCount,0) ,0,0,
@sdt,
sysdatetime()

	
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
