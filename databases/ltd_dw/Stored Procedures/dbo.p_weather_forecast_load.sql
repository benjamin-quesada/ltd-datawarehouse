SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE   PROCEDURE [dbo].[p_weather_forecast_load]

as


/*
AUTHOR   : BEichberger
DATE     : 04-26-2021
PURPOSE  : Read and stage Data Extract from https://openweathermap.org/api/one-call-api

-- exec [dbo].[p_weather_forecast_load]
-- truncate table dbo.weather_forecast

------------------LTD_GLOSSARY---------------
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


if (select count(*) from tempdb.sys.tables where [name] like '%OutputTblf42%')<> 0
BEGIN
drop table ##OutputTblf42
END

if (select count(*) from tempdb.sys.tables where [name] like '%OutputTblf42%') = 0
BEGIN
create table ##OutputTblf42(
	[dt] datetime NULL,
	[file_loaded] [nvarchar](255) NULL
)
END


if (select count(*) from tempdb.sys.tables where [name] like '%temp_weather_forecast%') <> 0
BEGIN
drop table  ##temp_weather_forecast
END

if (select count(*) from tempdb.sys.tables where [name] like '%temp_weather_forecast%') = 0
BEGIN
CREATE TABLE ##temp_weather_forecast(
	[lat] [nvarchar](25) NULL,
	[lon] [nvarchar](25) NULL,
	[wthrLoadKey] [int] NULL,
	[dt] datetime2  NULL,
	[temp] [float] NULL,
	[humidity] [float] NULL,
	[clouds] [float] NULL,
	[visibility] [float] NULL,
	[wind_speed] [float] NULL,
	[wind_gust] [float] NULL,
	[weatherMain] [varchar](32) NULL,
	[weatherDesc] [varchar](32) NULL,
	[file_loaded] [varchar](255) NULL
) 
END


declare @i int = 0
declare @r int = (select max([wthrLoadKey]) from [dbo].[weather_forecast_stage])
WHILE @i <= @r
BEGIN


declare @json nvarchar(max) = (select forecast from [dbo].[weather_forecast_stage] where [wthrLoadKey] = @i )

insert  ##temp_weather_forecast (
lat
,lon
,dt
,temp
,humidity
,clouds
,visibility
,wind_speed
,wind_gust
,weatherMain
,weatherDesc
,file_loaded
)
select s.lat, s.lon
,dt = convert( datetime, switchoffset( 
	cast(dateadd(s, cast(o.dt as bigint), '1970-01-01') as datetime), 
		datepart(TZOFFSET,
			cast(dateadd(s, cast(o.dt as bigint), '1970-01-01') as datetime)
			at TIME ZONE 'Pacific Standard Time')))
,temp
,humidity
,clouds
,visibility
,wind_speed
,wind_gust
,weatherMain
,weatherDesc
,s.fileloading
from 
(select @i wthrLoadKey, 
	dt
	,temp
	,humidity
	,clouds
	,visibility
	,wind_speed
	,wind_gust
	,weatherMain
	,weatherDesc
	from openjson(@json)
	WITH 
	(
	dt varchar(32) '$.dt',
	temp float '$.temp',
	humidity float '$.humidity',
	clouds float '$.clouds',
	visibility float '$.visibility',
	wind_speed float '$.wind_speed',
	wind_gust float '$.wind_gust',
	weathertype nvarchar(max) '$.weather' as JSON
	)
	CROSS APPLY OPENJSON(weatherType) WITH (weatherMain VARCHAR(32) '$.main' )
	CROSS APPLY OPENJSON(weatherType) WITH (weatherDesc VARCHAR(32) '$.description' )
	) o
join [dbo].[weather_forecast_stage] s
on s.wthrLoadKey = @i
--where not exists (select 1 from -- truncate table
--	[dbo].[weather_forecast] where dt = o.dt and lat = s.lat and lon = s.lon)
--and o.dt is not null
	
	select @i = @i + 1

if @i > @r
BREAK
ELSE CONTINUE
END

truncate table dbo.weather_forecast -- clear out old forecasts
insert dbo.weather_forecast (
lat
,lon
,[dt]
,temp
,humidity
,clouds
,visibility
,wind_speed
,wind_gust
,weatherMain
,weatherDesc
,file_loaded)
OUTPUT inserted.dt, inserted.file_loaded into ##OutputTblf42
select lat
,lon
,[dt]
,temp
,humidity
,clouds
,visibility
,wind_speed
,wind_gust
,weatherMain
,weatherDesc
,file_loaded from ##temp_weather_forecast f
where not exists (select 1 from dbo.weather_forecast where dt = f.dt and lat = f.lat and lon = f.lon)


insert [process].[Fileload] (
	  [FileSourceName]
      ,[FileSourceGroup]
      ,[FileRowCount])
select file_loaded,'WTHF',count(*) from ##OutputTblf42 group by file_loaded

 
if (select count(*) from tempdb.sys.tables where [name] like '%OutputTblf42%') <> 0
BEGIN
drop table ##OutputTblf42
END


if (select count(*) from tempdb.sys.tables where [name] like '%tmp_weather_forecast%') <> 0
BEGIN
DROP TABLE ##tmp_weather_forecast
END

END TRY	  

BEGIN CATCH

       DECLARE @profile VARCHAR(255) = (
                    SELECT [NAME]
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
             ,@recipients = 'barb.eichberger@ltd.org' 
             ,@subject = @sub
             ,@body = @errormsg;

       RAISERROR (
                    @errormsg
                    ,@errsev
                    ,1
                    )
END CATCH

GO
