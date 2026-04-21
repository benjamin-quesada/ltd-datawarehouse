SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   PROCEDURE [nf].[newflyer_load_vehicledata1]

as
-- exec [nf].[newflyer_load_vehicledata1]

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

DECLARE @sdt datetime2 = SYSDATETIME();
declare @insCount INT = 0; 

DECLARE @i INT = 1;
DECLARE @r INT = (SELECT MAX([vd1LoadKey]) FROM [nf].[newflyer_vehicledata1_stage] );

WHILE @i <= @r
BEGIN

DECLARE @json nvarchar(max)  = '';
SELECT @json = @json + (SELECT response FROM [nf].[newflyer_vehicledata1_stage] WHERE [vd1LoadKey] = @i);

INSERT [nf].[newflyer_vehicledata1](
[vehicle_id]
      ,[unit_id]
      ,[group_id]
      ,[group_name]
      ,[client_id]
      ,[unit_serial]
      ,[license_number]
      ,[chassis_number]
      ,[last_communication_time]
      ,[last_communication_time_local]
      ,[last_position_time]
      ,[last_position_time_local]
      ,[latitude]
      ,[longitude]
      ,[speed]
      ,[direction]
      ,[status]
      ,[last_event_time]
      ,[last_event_time_local]
      ,[last_event_type]
      ,[current_driver]
      ,[current_driver_number]
      ,[driver_name]
      ,[worker_id]
      ,[current_drive]
      ,[last_mileage]
	  ,record_created_date
	)
SELECT CAST(vehicle_id AS INT) vehicle_id,
	   [unit_id]
      ,[group_id]
      ,[group_name]
      ,[client_id]
      ,[unit_serial]
      ,license_nmbr AS license_number
	  ,[chassis_number]
      ,CONVERT(datetime2(0),cast(REPLACE(last_communication_time,'%3A',':') as datetime2)) last_communication_time,
       CONVERT(datetime2(0),cast(REPLACE(last_communication_time,'%3A',':') as datetime2) AT TIME ZONE 'UTC' AT TIME ZONE 'Pacific Standard Time' ) last_communication_time_local,
       CONVERT(datetime2(0),cast(REPLACE(last_position_time,'%3A',':') as datetime2)) last_position_time,
       CONVERT(datetime2(0),cast(REPLACE(last_position_time,'%3A',':') as datetime2) AT TIME ZONE 'UTC' AT TIME ZONE 'Pacific Standard Time' ) last_position_time_local,
	   latitude,
       longitude,
       speed,
       direction,
	   [status],
	   CONVERT(datetime2(0),cast(REPLACE(last_event_time,'%3A',':') as datetime2)) last_event_time,
       convert(datetime2(0),cast(REPLACE(last_event_time,'%3A',':') as datetime2) AT TIME ZONE 'UTC' AT TIME ZONE 'Pacific Standard Time' ) last_event_time_local,
       [last_event_type]
      ,[current_driver]
      ,[current_driver_number]
      ,[driver_name]
      ,[worker_id]
      ,[current_drive]
      ,[last_mileage]
	  ,@sdt
	   FROM OPENJSON(@json, '$.properties.data')
WITH (vehicle_id NVARCHAR(32) '$.vehicle_id',
	  unit_id NVARCHAR(32) '$.unit_id',
	  group_id NVARCHAR(32) '$.group_id',
	  group_name NVARCHAR(6) '$.group_name',
	  client_id NVARCHAR(32) '$.client_id',
	  unit_serial NVARCHAR(32) '$.unit_serial',
	  license_nmbr NVARCHAR(32) '$.license_nmbr',
	  chassis_number NVARCHAR(90) '$.chassis_number',
	  last_communication_time NVARCHAR(32) '$.last_communication_time',
	  last_position_time NVARCHAR(32) '$.last_position_time',
      latitude FLOAT '$.latitude',
      longitude FLOAT'$.longitude',
      speed FLOAT '$.speed',
      direction INT '$.direction',
      [status] INT '$.status',
      last_event_time NVARCHAR(32) '$.last_event_time',
      last_event_type NVARCHAR(255) '$.end_longitude',
	  [current_driver] [NVARCHAR](30) '$.current_driver',
      [current_driver_number] NVARCHAR(30) '$.current_driver_number',
      [driver_name] NVARCHAR(30) '$.driver_name',
      [worker_id] NVARCHAR(32) '$.worker_id',
      [current_drive] BIGINT '$.current_drive',
      [last_mileage] FLOAT '$.last_mileage'
	  ) o
--WHERE NOT EXISTS (SELECT 1 FROM nf.newflyer_vehicledata1 
--					WHERE o.vehicle_id = vehicle_id 
--						AND CONVERT(datetime2(0),cast(REPLACE(o.last_communication_time,'%3A',':') as datetime2))
--							= last_communication_time
--						AND CONVERT(datetime2(0),cast(REPLACE(o.last_position_time,'%3A',':') as datetime2))
--							= last_position_time
--)
;

SELECT @i = @i + 1;
IF @i > @r
BREAK;
	ELSE CONTINUE;

END;

select @insCount = @insCount + (select count(distinct drive_id) from [nf].[newflyer_trips] where record_created_date = @sdt);


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
'ltd_dw.nf.newflyer_vehicledata1',
'NFAPI',
'SSIS_ISC_PROCESS_NewFlyer_GetNewFlyerVehicleData1' ,
isnull(@insCount,0) ,0,0,
@sdt,
sysdatetime();

	
END TRY	  


BEGIN CATCH

       DECLARE @profile VARCHAR(255) = (
                    SELECT NAME
                    FROM msdb.dbo.sysmail_profile
                    );
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

       SELECT @errormsg = 'Error in ' + isnull(@SPROC, '') + ': ' + cast(isnull(@error, '') AS NVARCHAR(32)) + '|' + coalesce(@message, '') + '|' + cast(isnull(@xstate, '') AS NVARCHAR(32)) + '|' +cast(isnull(@errsev, '') AS NVARCHAR(32));

       SELECT @sub = 'ERROR: ' + @SPROC;

       EXEC msdb.dbo.sp_send_dbmail @profile_name = @profile
             ,@recipients = 'barb.eichberger@ltd.org'--;servicedesk@ltd.org' 
             ,@subject = @sub
             ,@body = @errormsg;

       RAISERROR (
                    @errormsg
                    ,@errsev
                    ,1
                    );
END CATCH;
GO
