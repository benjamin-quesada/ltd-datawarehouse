SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE   PROCEDURE [tm].[Get_Adherence_drop_20241231]
as
-- exec tm.Get_Adherence


/*
  CREATED: 20190829
   AUTHOR: B EICHBERGER
  PURPOSE: Collect Daily Adherence data for longitudinal record in DW - WIP.
CHANGEDON: 20200121
 CHANGEBY: b eichberger
   CHANGE: Added error handling.

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

DECLARE @OutputTbl TABLE (ActionName varchar(32))

declare @startdt datetime = sysdatetime()
declare @maxdate table (maxdate int)
declare @backupdate int
select @backupdate = (select cast(convert(varchar(32),dateadd(day,-1,cast(getdate() as date)),112)+100000000 as INT))
insert @maxdate
select isnull(max(calendar_id),@backupdate) maxdate
 from [tm].[AdherenceStats] WITH (NOLOCK)

 update [process].[MergeLogs] 
set [MergeEndDatetime] = sysdatetime()
   where mergecode = 'ADH'
     and [ObjectDestination] = 'LTD_DW.tm.AdherenceStats'
	 AND [ObjectSource] = 'TM'
	 AND [ObjectProgram] = 'LTD_DW.tm.Get_Adherence'
	 AND [MergeEndDatetime] is null
	 AND recInsert = 0
	 AND recUpdate = 0
	 AND recDelete = 0

 insert [process].[MergeLogs] (
	   [MergeCode]
      ,[ObjectDestination]
      ,[ObjectSource]
      ,[ObjectProgram]
      ,[recInsert]
      ,[recUpdate]
      ,[recDelete]
      ,[MergeBeginDatetime])
	  Values(
	  'ADH', 'LTD_DW.tm.AdherenceStats','TM','LTD_DW.tm.Get_Adherence',0, 0, 0, @startdt)

select *
,AdherenceType			= case when adherence > 0 then 'HOT'
									  when adherence <= -5 then 'LATE'
									  else 'On Schedule' end
,cast((CONVERT(DECIMAL(10, 6), maplat * 0.0000001)) as varchar(32))+' '+cast((CONVERT(DECIMAL(10, 6), maplong * 0.0000001)) as varchar(32)) as LatLong
,[east_west_zone]         = case when maplong >= -1230400001 then 'east' else 'west' end 
,[north_south_zone]       = case when maplat >= 440489000 then 'north' else 'south' end 
into #AdherenceSource
 from (
select [calendar_id]            = lm.calendar_id
      ,[calendar_date]          = sc.calendar_date
	  ,[local_datetime]			= lm.local_timestamp
      ,[day_type]               = lsdtpc.service_type 
      ,[bus_class]              = v.bus_class
      ,[artic]                  = v.artic
      ,[emx_bus]                = v.emx_bus
	  ,the_bus					= v.veh
      ,[mdt_time]				= right('00'+cast(mdt_timestamp/3600 as varchar(32)),2) + ':' +
									right('00'+cast((mdt_timestamp/60) % 60 as varchar(32)),2) + ':' +
									right('00' + CAST(mdt_timestamp % 60 AS VARCHAR(32)),2)
      ,[mdt_spm]                = lm.mdt_timestamp 
      ,[route]                  = r.route_abbr
      ,[route_abbr]				= r.[route_abbr]
      ,[block]                  = b.block_abbr
      ,[dir]                    = left(rd.route_direction_name, 1) 
      ,[tp_id]                  = case when lm.message_type_id = 16 then tp.time_point_abbr else '0' end 
      ,[tp_name]                = case when lm.message_type_id = 16 then tp.time_pt_name else 'Not Assigned' end
	  ,[stop_id]				= gn.geo_node_abbr
      ,[stop_code]				= gn.geo_node_abbr
      ,[stop_name]				= gn.geo_node_name
      ,[adherence]              = Avg(lm.adherence)
      ,[valid_odometer]         = case when lm.validity & power(2,5) = power(2,5) then 1 else 0 end 
      ,[valid_adherence]        = case when lm.validity & power(2,6) = power(2,6) then 1 else 0 end 
      ,[valid_position]         = case when lm.validity & power(2,7) = power(2,7) then 1 else 0 end 
      ,[route_direction]        = case when lm.direction = 3 then 'I' else 'O' end
   	  ,right(lm.CALENDAR_ID, 8) CalendarKey
	  ,maplat = avg(CONVERT(DECIMAL(10, 6), lm.[latitude] * 0.0000001))
	  ,maplong = avg(CONVERT(DECIMAL(10, 6), lm.[longitude] * 0.0000001))
-- select top 100 *
  from [LTD-TMDATA].TMDailyLog.dbo.LOGGED_MESSAGE lm WITH (NOLOCK) 
  join @maxdate d on d.maxdate <= lm.CALENDAR_ID
 inner join [LTD-TMDATA].tmmain.dbo.service_calendar                     sc     WITH (NOLOCK) on sc.calendar_id        = lm.calendar_id
 inner join [LTD-TMDATA].ltd_db.dbo.ltd_service_day_type_per_calendar_id_from_tmmain lsdtpc WITH (NOLOCK) on lsdtpc.calendar_id    = lm.calendar_id
 inner join [LTD-TMDATA].tmmain.dbo.time_table_version                   ttv    WITH (NOLOCK) on sc.calendar_date between ttv.activation_date and ttv.deactivation_date
 inner join [LTD-TMDATA].tmmain.dbo.message_type                         mt     WITH (NOLOCK) on mt.message_type_id    = lm.message_type_id
  left join [LTD-TMDATA].tmmain.dbo.mdt_route                            mdtr   WITH (NOLOCK) on mdtr.route_offset_id  = lm.route_offset and mdtr.time_table_version_id = ttv.time_table_version_id
  left join [LTD-TMDATA].tmmain.dbo.[route]                              r      WITH (NOLOCK) on r.route_id            = mdtr.route_id
  left join [LTD-TMDATA].tmmain.dbo.route_direction                      rd     WITH (NOLOCK) on rd.route_direction_id = lm.direction
  left join [LTD-TMDATA].tmmain.dbo.block                                b      WITH (NOLOCK) on b.mdt_block_id        = lm.mdt_block_id and b.time_table_version_id = ttv.time_table_version_id
  left join [LTD-TMDATA].tmmain.dbo.mdt_node                             mdtn   WITH (NOLOCK) on mdtn.node_offset_id   = lm.time_point_offset
  left join [LTD-TMDATA].tmmain.dbo.geo_node                             gn     WITH (NOLOCK) on gn.geo_node_id        = mdtn.geo_node_id
  left join [LTD-TMDATA].tmmain.dbo.time_point                           tp     WITH (NOLOCK) on tp.time_point_id      = mdtn.time_point_id
  left join [LTD-TMDATA].tmmain.dbo.operator                             o      WITH (NOLOCK) on o.onboard_logon_id    = lm.current_driver
  left join [LTD-TMDATA].ltd_db.dbo.ltd_vehicle_info_from_tmmain         v      WITH (NOLOCK) on v.rnet_address        = case when lm.source_host > 512 then lm.source_host else lm.destination_host end
 where (CONVERT(DECIMAL(10, 6), lm.[latitude] * 0.0000001)) not between 44.042901 - .001 and 44.042901 + .001
	and (CONVERT(DECIMAL(10, 6), lm.[longitude] * 0.0000001)) not between  -123.041440 - .001 and -123.041440 + .001
	and r.route_abbr is not null
	and lm.direction <> 0
	and adherence is not null
	and mdt_timestamp > 9000
	and lm.latitude <> 0
	and lm.longitude <> 0
	and r.[route_abbr] <> 'swap'
group by 
lm.calendar_id
,sc.calendar_date
,lm.local_timestamp
,lsdtpc.service_type 
,v.bus_class
,v.artic
,v.emx_bus
,v.veh
,right('00'+cast(mdt_timestamp/3600 as varchar(32)),2) + ':' +
	right('00'+cast((mdt_timestamp/60) % 60 as varchar(32)),2) + ':' +
	right('00' + CAST(mdt_timestamp % 60 AS VARCHAR(32)),2)
,lm.mdt_timestamp 
,r.route_abbr
,r.route_abbr
,b.block_abbr
,left(rd.route_direction_name,1) 
,lm.message_type_ID
,TIME_POINT_ABBR
,TIME_PT_NAME 
,gn.geo_node_abbr
,gn.geo_node_abbr
,gn.geo_node_name 
,lm.validity
,lm.direction
,right(lm.CALENDAR_ID,8) 
) Q


MERGE tm.AdherenceStats as t
 USING #AdherenceSource as s on 
 t.[calendar_id] = s.[calendar_id]
AND t.[calendar_date] = s.[calendar_date]
AND t.[local_datetime] = s.[local_datetime]
AND t.[day_type] = s.[day_type]
AND t.[bus_class] = s.[bus_class]
AND t.[artic] = s.[artic]
AND t.[emx_bus] = s.[emx_bus]
AND t.[the_bus] = s.[the_bus]
AND t.[stop_id]	= s.[stop_id]			
AND t.[stop_code] = s.[stop_code]
AND t.[stop_name] = s.[stop_name]
AND t.[mdt_spm] = s.[mdt_spm]
AND t.[route] = s.[route]
AND t.[route_abbr] = s.[route_abbr]
AND t.[route_direction] = s.[route_direction]
AND t.[block] = s.[block]
AND t.[dir] = s.[dir]
AND t.[tp_id] = s.[tp_id]
AND t.[tp_name] = s.[tp_name]
WHEN NOT MATCHED BY TARGET THEN 
INSERT (
[calendar_id]
,[calendar_date]
,[local_datetime]
,[day_type]
,[bus_class]
,[artic]
,[emx_bus]
,[the_bus]
,[mdt_time]
,[mdt_spm]
,[route]
,[route_abbr]
,[block]
,[dir]
,[tp_id]
,[tp_name]
,[stop_id]				
,[stop_code] 
,[stop_name] 
,[adherence]
,[adherencetype]
,[valid_odometer]
,[valid_adherence]
,[valid_position]
,[east_west_zone]
,[north_south_zone]
,[route_direction]
,[CalendarKey]
,[maplat]
,[maplong]
,[LatLong])
VALUES (
s.[calendar_id]
,s.[calendar_date]
,s.[local_datetime]
,s.[day_type]
,s.[bus_class]
,s.[artic]
,s.[emx_bus]
,s.[the_bus]
,s.[mdt_time]
,s.[mdt_spm]
,s.[route]
,s.[route_abbr]
,s.[block]
,s.[dir]
,isnull(s.[tp_id],0)
,isnull(s.[tp_name],'Not Assigned')
,s.[stop_id]			
,s.[stop_code]
,s.[stop_name]
,s.[adherence]
,s.[adherencetype]
,s.[valid_odometer]
,s.[valid_adherence]
,s.[valid_position]
,s.[east_west_zone]
,s.[north_south_zone]
,s.[route_direction]
,s.[CalendarKey]
,s.[maplat]
,s.[maplong]
,s.[LatLong])
WHEN MATCHED AND
s.[adherence] <> t.[adherence]
OR s.[adherencetype] <> t.[adherencetype]
OR s.[valid_odometer] <> t.[valid_odometer]
OR s.[valid_adherence] <> t.[valid_adherence]
OR s.[valid_position] <> t.[valid_position]
THEN UPDATE
set  t.[adherence] = s.[adherence]
, t.[adherencetype] = s.[adherencetype]
, t.[valid_odometer] = s.[valid_odometer]
, t.[valid_adherence] = s.[valid_adherence]
, t.[valid_position] = s.[valid_position]
, t.record_update_date = sysdatetime()
OUTPUT $action into @OutputTbl;

declare @i int = (select isnull(count(*),0) from @OutputTbl where ActionName = 'Insert' group by ActionName )
declare @u int = (select isnull(count(*),0) from @OutputTbl where ActionName = 'Update' group by ActionName )
declare @d int = (select isnull(count(*),0) from @OutputTbl where ActionName = 'Delete' group by ActionName )

update [process].[MergeLogs] 
set recInsert =  isnull(@i,0)
,recUpdate = isnull(@u,0)
,recDelete = isnull(@d,0)
,[MergeEndDatetime] = sysdatetime()
   where mergecode = 'ADH'
     and [ObjectDestination] = 'LTD_DW.tm.AdherenceStats'
	 AND [ObjectSource] = 'TM'
	 AND [ObjectProgram] = 'LTD_DW.tm.Get_Adherence'
	 AND [MergeEndDatetime] is null
	 AND MergeBeginDatetime = @startdt
	 AND (recInsert = 0 or recUpdate = 0 or recDelete = 0)

drop table #AdherenceSource



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
             ,@recipients = 'barb.eichberger@ltd.org;ServiceDesk@ltd.org' 
             ,@subject = @sub
             ,@body = @errormsg;

       RAISERROR (
                    @errormsg
                    ,@errsev
                    ,1
                    )
END CATCH
GO
