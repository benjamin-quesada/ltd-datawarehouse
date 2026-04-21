SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   PROCEDURE [nf].[newflyer_load_trip_events]
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
DECLARE @r INT = (SELECT MAX(evStgKey) FROM [nf].[newflyer_trip_events_stage] )

WHILE @i <= @r
BEGIN

declare @dId nvarchar(32) = (select replace(replace(fileloadname,'E:\filedrop\newflyer\NewFlyer_v2_Events_',''),'.txt','') drive_id
								FROM [nf].[newflyer_trip_events_stage] WHERE evStgKey = @i
								)
DECLARE @json nvarchar(max)  = N''
SELECT @json = @json + (SELECT response FROM [nf].[newflyer_trip_events_stage] WHERE evStgKey = @i AND response not like '%error%')
INSERT [nf].[newflyer_trip_events] (
[drive_id]
,[trip_id]
,[event_id]
,[vehicle_id]
,[license_number]
,[event_time]
,[event_time_local]
,[event_type_id]
,[event_type_description]
,[event_category]
,[event_category_description]
,[latitude]
,[longitude]
,[end_time]
,[end_time_local]
,[end_latitude]
,[end_longitude]
,[speed]
,[direction]
,[driver_id]
,[driver_name]
,[driver_code]
,[worker_id]
,[record_created_date])
SELECT [drive_id]
,[trip_id]
,[event_id]
,[vehicle_id]
,[license_number]
,[event_time]
,[event_time_local]
,[event_type_id]
,[event_type_description]
,[event_category]
,[event_category_description]
,[latitude]
,[longitude]
,[end_time]
,[end_time_local]
,[end_latitude]
,[end_longitude]
,[speed]
,[direction]
,[driver_id]
,[driver_name]
,[driver_code]
,[worker_id]
,record_created_date -- select * 
 FROM (
	SELECT @dId drive_id
		  ,[trip_id]
		  ,[event_id]
		  ,[vehicle_id]
		  ,[license_number]
		  --,cast([event_time] as varchar(32))
		  ,case when isnull([event_time],'1900-01-01 00:00:01') = '1900-01-01 00:00:01' THEN NULL
				when isnull([event_time],'1900-01-01 00:00:01') <> '1900-01-01 00:00:01' and
					 isdate(REPLACE(REPLACE([event_time],'T',' '), '%3A', ':')) = 1
				THEN 
					 CONVERT(DATETIME2(0),REPLACE(REPLACE([event_time],'T',' '), '%3A', ':'))
					 else null end [event_time]
		  ,CONVERT(DATETIME2(0),
			CONVERT(DATETIME2(0),REPLACE(REPLACE([event_time],'T',' '), '%3A', ':')) AT TIME ZONE 'UTC' AT TIME ZONE 'Pacific Standard Time') event_time_local
		  ,[event_type_id]
		  ,dbo.[fn_ProperCase](replace(replace(replace([event_type_description],'%20',' '),'%3A',':'),'%2F','-') ) [event_type_description]
		  ,dbo.[fn_ProperCase](replace(replace(replace([event_category],'%20',' '),'%3A',':'),'%2F','-') ) [event_category]
		  ,dbo.[fn_ProperCase](replace(replace(replace([event_category_description],'%20',' '),'%3A',':'),'%2F','-') )[event_category_description]
		  ,[latitude]
		  ,[longitude]
		  ,case when isnull([end_time],'1900-01-01 00:00:01') = '1900-01-01 00:00:01' THEN NULL
				when isnull([end_time],'1900-01-01 00:00:01') <> '1900-01-01 00:00:01' and
					 isdate(REPLACE(REPLACE([end_time],'T',' '), '%3A', ':')) = 1
				THEN 
					 CONVERT(DATETIME2(0),REPLACE(REPLACE([end_time],'T',' '), '%3A', ':'))
					 else null end [end_time]
		   ,case when isnull([end_time],'1900-01-01 00:00:01') = '1900-01-01 00:00:01' THEN NULL
				when isnull([end_time],'1900-01-01 00:00:01') <> '1900-01-01 00:00:01' and
					 isdate(REPLACE(REPLACE([end_time],'T',' '), '%3A', ':')) = 1
				THEN 
				CONVERT(DATETIME2(0),
					CONVERT(DATETIME2(0),REPLACE(REPLACE([end_time],'T',' '), '%3A', ':')) AT TIME ZONE 'UTC' AT TIME ZONE 'Pacific Standard Time') 
				ELSE null end [end_time_local]
		  ,[end_latitude]
		  ,[end_longitude]
		  ,[speed]
		  ,[direction]
		  ,[driver_id]
		  ,[driver_name]
		  ,[driver_code]
		  ,[worker_id]
		  ,@sdt record_created_date
	  FROM OPENJSON(@json, '$.properties.data')
	WITH (
		trip_id VARCHAR(42) '$.trip_id',
		event_id VARCHAR(42) '$.event_id',
		vehicle_id VARCHAR(42) '$.vehicle_id',
		license_number VARCHAR(42) '$.license_number',
		event_time VARCHAR(42) '$.time',
		event_type_id VARCHAR(42) '$.event_type_id',
		event_type_description VARCHAR(254) '$.event_type_description',
		event_category VARCHAR(42) '$.event_category',
		event_category_description VARCHAR(90) '$.event_category_description',
		latitude VARCHAR(42) '$.latitude',
		longitude VARCHAR(42) '$.longitude',
		end_time VARCHAR(42) '$.end_time',
		end_latitude VARCHAR(42) '$.end_latitude',
		end_longitude VARCHAR(42) '$.end_longitude',
		speed VARCHAR(42) '$.speed',
		direction VARCHAR(12) '$.direction',
		driver_id VARCHAR(42) '$.driver_id',
		driver_name VARCHAR(42) '$.driver_name',
		driver_code VARCHAR(42) '$.driver_code',
		worker_id VARCHAR(42) '$.worker_id'
		  ) o
	WHERE [event_time] is not NULL
	) e
WHERE e.event_type_id NOT IN (4388183,4397390)
AND NOT EXISTS (SELECT 1 FROM nf.newflyer_trip_events 
				WHERE e.[trip_id] = [trip_id] 
				and e.event_time = event_time 
						and e.event_type_id = event_type_id )

SELECT @i = @i + 1
IF @i > @r
BREAK
	ELSE CONTINUE

END

select @insCount = @insCount + (select count(distinct drive_id) from [nf].[newflyer_trip_events] where record_created_date = @sdt)


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
select 'NFTE',
'ltd_dw.nf.newflyer_trip_events',
'NFAPI',
'SSIS_ISC_PROCESS_NewFlyer_GetNewFlyerTripEvents' ,
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
