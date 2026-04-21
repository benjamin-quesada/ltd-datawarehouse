SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   PROCEDURE [nf].[newflyer_load_trips]
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
DECLARE @r INT = (SELECT MAX([vtLoadKey]) FROM [nf].[newflyer_trips_stage] )

WHILE @i <= @r
BEGIN

DECLARE @json nvarchar(max)  = ''
SELECT @json = @json + (SELECT response FROM [nf].[newflyer_trips_stage] WHERE [vtLoadKey] = @i)

INSERT [nf].[newflyer_trips](
[vehicle_id]
      ,[license_number]
      ,[start_time]
      ,[end_time]
	  ,[start_time_local]
	  ,[end_time_local]
      ,[start_location]
      ,[end_location]
      ,[drive_id]
	  ,[distance]
      ,[start_latitude]
      ,[start_longitude]
      ,[end_latitude]
      ,[end_longitude]
	  ,record_created_date
	)
SELECT CAST(vehicle_id AS INT) vehicle_id,
       license_number,
	   convert(datetime2(0),cast(REPLACE(start_time,'%3A',':') as datetime2)) start_time,
       convert(datetime2(0),cast(REPLACE(end_time,'%3A',':') as datetime2)) end_time,
	   convert(datetime2(0),cast(REPLACE(start_time,'%3A',':') as datetime2) AT TIME ZONE 'UTC' AT TIME ZONE 'Pacific Standard Time' ) start_time,
       convert(datetime2(0),cast(REPLACE(end_time,'%3A',':') as datetime2) AT TIME ZONE 'UTC' AT TIME ZONE 'Pacific Standard Time' ) end_time,
	   dbo.fn_ProperCase(CASE WHEN LEN(REPLACE(start_location,'%20',' ')) > 0 THEN 
			REPLACE(LEFT(REPLACE(start_location,'%20',' '),PATINDEX('%2C%',REPLACE(start_location,'%20',' '))) ,'%2','')
			ELSE '' END) start_location,
	   dbo.fn_ProperCase(CASE WHEN LEN(REPLACE(end_location,'%20',' ')) > 0 THEN 
			REPLACE(LEFT(REPLACE(end_location,'%20',' '),PATINDEX('%2C%',REPLACE(end_location,'%20',' '))),'%2','')
			ELSE '' END) end_location,
	   drive_id,
	   distance,
	   start_latitude,
       start_longitude,
       end_latitude,
       end_longitude,
	   @sdt
	   FROM OPENJSON(@json, '$.properties.data')
WITH (vehicle_id NVARCHAR(32) '$.vehicle_id',
	  license_number NVARCHAR(32) '$.license_number',
	  start_time NVARCHAR(90) '$.start_time',
	  end_time NVARCHAR(90) '$.end_time',
	  start_location NVARCHAR(120) '$.start_location',
      end_location NVARCHAR(120)  '$.end_location',
      drive_id BIGINT '$.drive_id',
      distance FLOAT '$.distance',
      start_latitude FLOAT '$.start_latitude',
      start_longitude FLOAT '$.start_longitude',
      end_latitude FLOAT '$.end_latitude',
      end_longitude FLOAT '$.end_longitude'
	  ) o
WHERE NOT EXISTS (SELECT 1 FROM nf.newflyer_trips WHERE
				o.drive_id = drive_id AND o.vehicle_id = vehicle_id
)

SELECT @i = @i + 1
IF @i > @r
BREAK
	ELSE CONTINUE

END

select @insCount = @insCount + (select count(distinct drive_id) from [nf].[newflyer_trips] where record_created_date = @sdt)


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
'ltd_dw.nf.newflyer_trips',
'NFAPI',
'SSIS_ISC_PROCESS_NewFlyer_GetNewFlyerTrips' ,
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
GRANT EXECUTE ON  [nf].[newflyer_load_trips] TO [public]
GO
