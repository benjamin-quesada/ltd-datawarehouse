SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE   PROCEDURE [dbo].[p_weather_current_load]

as


/*
AUTHOR   : BEichberger
DATE     : 04-16-2021
PURPOSE  : Read and stage Data Extract from https://openweathermap.org/api/one-call-api

-- exec [dbo].[p_weather_current_load]

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


if (select count(*) from tempdb.sys.tables where name like '%OutputTblw42%')<> 0
BEGIN
drop table ##OutputTblw42
END

if (select count(*) from tempdb.sys.tables where name like '%OutputTblw42%') = 0
BEGIN
create table ##OutputTblw42(
	[dt] datetime NULL,
	[file_loaded] [nvarchar](255) NULL
)
END


if (select count(*) from tempdb.sys.tables where name like '%tmp_weather_current%')<> 0
BEGIN
drop table ##tmp_weather_current
END

if (select count(*) from tempdb.sys.tables where name like '%tmp_weather_current%') = 0
BEGIN
CREATE TABLE ##tmp_weather_current(
	[lat] [float] NULL,
	[lon] [float] NULL,
	[dt] [datetime] NULL,
	sunrise datetime null,
	sunset datetime null,
	[temp] [float] NULL,
	[feels_like] [float] NULL,
	[pressure] [float] NULL,
	[humidity] [float] NULL,
	[clouds] [float] NULL,
	[visibility] [float] NULL,
	[wind_speed] [float] NULL,
	[file_loaded] [varchar](255) NULL
) 
END

insert into ##tmp_weather_current
(lat
,lon
,[dt]
,sunrise
,sunset
,[temp]
,[feels_like]
,[pressure]
,[humidity]
,[clouds]
,[visibility]
,[wind_speed]
,file_loaded
)
select lat, lon 
,convert( datetime, switchoffset( 
	cast(dateadd(s, cast(dt as bigint), '1970-01-01') as datetime), 
		datepart(TZOFFSET,
			cast(dateadd(s, cast(dt as bigint), '1970-01-01') as datetime)
			at TIME ZONE 'Pacific Standard Time')))
,convert( datetime, switchoffset( 
	cast(dateadd(s, cast(sunrise as bigint), '1970-01-01') as datetime), 
		datepart(TZOFFSET,
			cast(dateadd(s, cast(sunrise as bigint), '1970-01-01') as datetime)
			at TIME ZONE 'Pacific Standard Time')))
,convert( datetime, switchoffset( 
	cast(dateadd(s, cast(sunset as bigint), '1970-01-01') as datetime), 
		datepart(TZOFFSET,
			cast(dateadd(s, cast(sunset as bigint), '1970-01-01') as datetime)
			at TIME ZONE 'Pacific Standard Time')))
	,temp
	,[feels_like]
	,[pressure]
	,[humidity]
	,[clouds]
	,[visibility]
	,[wind_speed]
	,file_loaded from (
		SELECT 
		  lat, lon,
		 JSON_VALUE(curr_weather, '$.dt') AS dt,
		 JSON_VALUE(curr_weather, '$.sunrise') AS sunrise,
		 JSON_VALUE(curr_weather, '$.sunset') AS sunset,
		 JSON_VALUE(curr_weather, '$.temp') AS temp,
		 JSON_VALUE(curr_weather, '$.feels_like') AS feels_like,
		 JSON_VALUE(curr_weather, '$.pressure') AS pressure,
		 JSON_VALUE(curr_weather, '$.humidity') AS humidity,
		 JSON_VALUE(curr_weather, '$.clouds') AS clouds,
		 JSON_VALUE(curr_weather, '$.visibility') AS visibility,
		 JSON_VALUE(curr_weather, '$.wind_speed') AS wind_speed
		 ,fileloading as file_loaded
		-- select * 
		FROM [dbo].[weather_current_stage] s
	) q
--where not exists (select * from [dbo].[weather_current] where cast(dt as datetime) = cast(q.dt as datetime))


if (select count(*) from ##tmp_weather_current) <> 0
BEGIN

INSERT INTO -- truncate table 
[dbo].[weather]
(lat
,lon
,[dt]
,sunrise
,sunset
,[temp]
,[feels_like]
,[pressure]
,[humidity]
,[clouds]
,[visibility]
,[wind_speed]
,file_loaded )
OUTPUT inserted.dt, inserted.file_loaded into ##OutputTblw42
select lat
,lon
,[dt]
,sunrise
,sunset
,[temp]
,[feels_like]
,[pressure]
,[humidity]
,[clouds]
,[visibility]
,[wind_speed]
,file_loaded from ##tmp_weather_current c
where not exists (select 1 from [dbo].[weather] where dt = c.dt and lat = c.lat and lon = c.lon)

END

insert [process].[Fileload] (
	  [FileSourceName]
      ,[FileSourceGroup]
      ,[FileRowCount])
 select file_loaded,'WTHR',count(*) from ##OutputTblw42 group by file_loaded

 
if (select count(*) from tempdb.sys.tables where name like '%OutputTblw42%')<> 0
BEGIN
drop table ##OutputTblw42
END


if (select count(*) from tempdb.sys.tables where name like '%tmp_weather_current%')<> 0
BEGIN
DROP TABLE ##tmp_weather_current
END

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
