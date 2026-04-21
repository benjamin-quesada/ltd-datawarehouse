SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [tm].[buses_active_today_from_udf]


AS


/**********LTD_GLOSSARY************

CREATED ON:		20220311
CREATED BY:		Eichberger
PURPOSE   :		Catch Daily Log Active bus messages for EAM Mileage and Fueling Reports

EXAMPLE	  :		exec tm.[buses_active_today_from_udf] 

Modify on :		2023-10-30
Modify by :		Sopheap Suy
Purpose	  :		Shorten number of calls to Database

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

DECLARE @calin INT = (SELECT TOP(1) calendar_id FROM [ltd-tmdata].tmmain.dbo.current_version ORDER BY CALENDAR_ID )
DECLARE @caldt date = (SELECT cast(cast((@calin-100000000) as varchar(10)) as DATE))
declare @tbl_bus             table(bus varchar(9), miles numeric(9,2))
declare @tbl_buses_other     table(bus varchar(9), miles numeric(9,2))
declare @tbl_xing            table(unique_id int identity primary key, bus varchar(9), miles numeric(9,2), block varchar(5), xing_spm int, adherence int)
declare @tbl_locs_other      table(unique_id int identity primary key, bus varchar(9), miles numeric(9,2))
declare @tbl_bus_max_id      table(bus varchar(9), max_id int)
declare @tbl_bus_at_ltd      table(bus varchar(9), at_ltd smallint)
declare @tbl_cur_pull_in     table(blk_no varchar(9), pull_in char(5))
declare @tbl_bus_last_blk    table(bus varchar(9), last_block varchar(5), pull_in char(5), last_xing int, adherence int)
declare @tbl_bus_last_loc_id table(bus varchar(9), id bigint)
declare @tbl_bus_miles_rem   table(bus varchar(9), miles numeric(9,2))

declare @max_id    int
declare @cur_id    int = 2
declare @pre_bus   varchar(9)
declare @cur_bus   varchar(9)
declare @pre_miles numeric(9,2)
declare @cur_miles numeric(9,2)
declare @other_miles_threshold int = 25

insert @tbl_cur_pull_in(blk_no, pull_in)
select [blk_no]  = bk.block_abbr
      ,[pull_in] = tm.convert_passing_time(dp.scheduled_pullin_time)
  from [ltd-tmdata].tmmain.dbo.[block]            bk WITH (NOLOCK)
  join [ltd-tmdata].tmmain.dbo.current_version  cv WITH (NOLOCK) on cv.time_table_version_id = bk.time_table_version_id
  --join [ltd-tmdata].tmdailylog.dbo.roster_stats rs WITH (NOLOCK) on rs.block_id              = bk.block_id
  join [ltd-tmdata].tmdailylog.dbo.daily_pullout dp on dp.block_id             = bk.block_id and dp.calendar_id = cv.calendar_id
OPTION (MAXDOP 2)



select [calendar_id]            = lm.calendar_id
      ,[veh]                    = v.veh
      ,[odometer]               = cast((lm.odometer / 100.0) as numeric(7,2)) 
      ,[block]                  = b.block_abbr
     ,[long_field_2]            = lm.long_field_2
	 ,mdt_spm					= lm.MDT_TIMESTAMP 
	 ,lm.MESSAGE_TYPE_ID
	 ,local_timestamp
  INTO #tempLogMsg
  FROM   [ltd-tmdata].tmdailylog.dbo.logged_message                       lm WITH (NOLOCK)
  inner join [ltd-tmdata].tmmain.dbo.service_calendar                     sc WITH (NOLOCK)     on sc.calendar_id        = lm.calendar_id
  LEFT JOIN [ltd-tmdata].tmmain.dbo.TIME_TABLE_VERSION ttv WITH (NOLOCK) 
			ON sc.calendar_date between ttv.activation_date and ttv.deactivation_date
  LEFT join [ltd-tmdata].tmmain.dbo.route_direction                      rd WITH (NOLOCK)     on rd.route_direction_id = lm.direction
  left join [ltd-tmdata].tmmain.dbo.[block]                               b WITH (NOLOCK)      on b.mdt_block_id        = lm.mdt_block_id and b.time_table_version_id = ttv.time_table_version_id
  left join [ltd-tmdata].ltd_db.dbo.ltd_vehicle_info_from_tmmain          v WITH (NOLOCK)      on v.rnet_address        = case when lm.source_host > 512 then lm.source_host else lm.destination_host end
 where lm.calendar_id >= @calin
	and lm.message_type_id = 16
 OPTION (MAXDOP 2)

insert @tbl_xing(bus, miles, block, xing_spm, adherence)
select lm.veh
      ,lm.odometer
      ,lm.[block]
      ,lm.mdt_spm
      ,lm.long_field_2
  from #tempLogMsg lm WITH (NOLOCK)
  join [ltd-tmdata].tmmain.dbo.current_version cv WITH (NOLOCK)  on cv.calendar_id = lm.calendar_id
  where lm.veh is not null
        AND isnumeric(lm.veh)  = 1
        AND lm.message_type_id = 16
 order by cast(lm.veh as int), lm.local_timestamp

set @max_id = (select max(unique_id) from @tbl_xing)

insert @tbl_bus(bus, miles) 
select distinct bus, 0 
  from @tbl_xing 

insert @tbl_bus_max_id(bus, max_id) 
select bus, max(unique_id) 
  from @tbl_xing 
 group by bus

insert @tbl_bus_last_loc_id(bus, id)
select b.bus
      ,max(loc.logged_message_short_id)
  from [ltd-tmdata].tmdailylog.dbo.logged_message_short loc WITH (NOLOCK)
  join [ltd-tmdata].tmmain.dbo.current_version          cv WITH (NOLOCK)  on cv.calendar_id = loc.calendar_id
  join [ltd-tmdata].tmmain.dbo.vehicle                  v WITH (NOLOCK)   on v.rnet_address = loc.source_host
  join @tbl_bus                            b   on b.bus          = v.property_tag
group by b.bus
OPTION (MAXDOP 2)


select @cur_bus = bus, @cur_miles = miles  from @tbl_xing where unique_id = @cur_id
select @pre_bus = bus, @pre_miles = miles  from @tbl_xing where unique_id = @cur_id -1


while (@cur_id <= @max_id)
   begin
      if @cur_bus <> @pre_bus
         begin
            update @tbl_bus set miles = miles + @pre_miles where bus = @pre_bus
            set @pre_bus   = @cur_bus
            set @pre_miles = @cur_miles
         end
      else
         begin
            if @cur_miles < @pre_miles
               begin
                  update @tbl_bus set miles = miles + @pre_miles where bus = @cur_bus
               end

               set @pre_miles = @cur_miles
          end
         if @cur_id = @max_id
             update @tbl_bus set miles = miles + @pre_miles where bus = @cur_bus

      set @cur_id    = @cur_id +1
	  select @cur_bus = bus, @cur_miles = miles  from @tbl_xing where unique_id = @cur_id
   end
 
insert @tbl_bus_last_blk(bus, last_block, last_xing, adherence)
select m.bus
      ,x.block
      ,x.xing_spm
      ,x.adherence
  from @tbl_bus_max_id m
  join @tbl_xing       x on x.unique_id = m.max_id

update lb
   set pull_in = cb.pull_in
  from @tbl_bus_last_blk lb
  join @tbl_cur_pull_in  cb on cb.blk_no = lb.last_block

insert @tbl_bus_miles_rem(bus, miles)
select lb.bus
      ,sum(bt.trip_length_miles)
  from @tbl_bus_last_blk             lb
  join [ltd-tmdata].ltd_db.dbo.block_trips_end_spm_today bt WITH (NOLOCK) on bt.blk                   = lb.last_block
  join [ltd-tmdata].tmmain.dbo.current_version    cv WITH (NOLOCK) on cv.time_table_version_id = bt.time_table_version_id
 where lb.last_xing < bt.end_spm + lb.adherence 
 group by lb.bus
OPTION (MAXDOP 2)

insert @tbl_buses_other(bus, miles)
select distinct
       veh.property_tag
      ,0
  from [ltd-tmdata].tmdailylog.dbo.logged_message_short loc WITH (NOLOCK)
  join [ltd-tmdata].tmmain.dbo.vehicle                  veh WITH (NOLOCK) on veh.rnet_address = loc.source_host
  join [ltd-tmdata].tmmain.dbo.current_version          cv WITH (NOLOCK)  on cv.calendar_id   = loc.calendar_id
  join [ltd-tmdata].tmmain.dbo.fleet                    flt WITH (NOLOCK) on flt.fleet_id     = veh.fleet_id
where loc.calendar_id = cv.calendar_id
   AND isnumeric(veh.property_tag) = 1
   and flt.fleet_text = 'fixed route'
   and not (loc.latitude / 10000000.0 between 44.042760 and 44.044320 and loc.longitude / 10000000.0 between -123.04201 and -123.03891)
   and not exists(select * from @tbl_bus i where i.bus = veh.property_tag)
OPTION (MAXDOP 2)

insert @tbl_bus_last_loc_id(bus, id)
select b.bus
      ,max(loc.logged_message_short_id)
  from [ltd-tmdata].tmdailylog.dbo.logged_message_short loc
  join [ltd-tmdata].tmmain.dbo.current_version          cv  on cv.calendar_id = loc.calendar_id
  join [ltd-tmdata].tmmain.dbo.vehicle                  v   on v.rnet_address = loc.source_host
  join @tbl_buses_other                    b   on b.bus          = v.property_tag
group by b.bus
OPTION (MAXDOP 2)

insert @tbl_bus_at_ltd(bus, at_ltd)
select ll.bus
         ,[at_ltd] = case when loc.latitude / 10000000.0 between 44.042760 and 44.044320 and loc.longitude / 10000000.0 between -123.04201 and -123.03891 then 1 else 0 end
  from [ltd-tmdata].tmdailylog.dbo.logged_message_short loc
  join [ltd-tmdata].tmmain.dbo.current_version          cv  on cv.calendar_id = loc.calendar_id
  join @tbl_bus_last_loc_id                ll  on ll.id          = loc.logged_message_short_id
OPTION (MAXDOP 2)

insert @tbl_locs_other(bus, miles)
select bus.bus
      ,[odometer] = cast(loc.odometer / 100.0 as numeric(9,2))
  from [ltd-tmdata].tmdailylog.dbo.logged_message_short loc WITH (NOLOCK)
  join [ltd-tmdata].tmmain.dbo.vehicle                  veh WITH (NOLOCK) on veh.rnet_address = loc.source_host
  join @tbl_buses_other                    bus on bus.bus          = veh.property_tag
  join [ltd-tmdata].tmmain.dbo.current_version          cv WITH (NOLOCK)  on cv.calendar_id   = loc.calendar_id
where loc.calendar_id = cv.calendar_id
order by bus, loc.message_timestamp
OPTION (MAXDOP 2)

set @cur_id    = 2
set @max_id    = (select max(unique_id) from @tbl_locs_other)

select @cur_bus = bus, @cur_miles = miles  from @tbl_locs_other where unique_id = @cur_id
select @pre_bus = bus, @pre_miles = miles  from @tbl_locs_other where unique_id = @cur_id -1

while (@cur_id <= @max_id)
   begin
      if @cur_bus <> @pre_bus
         begin
            update @tbl_buses_other set miles = miles + @pre_miles where bus = @pre_bus
            set @pre_bus   = @cur_bus
            set @pre_miles = @cur_miles
         end
      else
         begin
            if @cur_miles < @pre_miles
               begin
                  update @tbl_buses_other set miles = miles + @pre_miles where bus = @cur_bus
               end

               set @pre_miles = @cur_miles
          end
         if @cur_id = @max_id
             update @tbl_buses_other set miles = miles + @pre_miles where bus = @cur_bus

      set @cur_id    = @cur_id +1
	  select @cur_bus = bus, @cur_miles = miles  from @tbl_locs_other where unique_id = @cur_id
   end

  
declare @results table(calendar_id INT, bus varchar(9), miles numeric(9,2), last_block varchar(5), miles_total_est numeric(9,2), pull_in char(5), at_ltd smallint) 

insert @results(calendar_id, bus, miles, last_block, miles_total_est, pull_in, at_ltd)
select   @calIn
		,b.bus
		,b.miles
        ,lb.last_block
        ,b.miles + em.miles + 11 --estimated DH miles/block
        ,lb.pull_in
        ,al.at_ltd
  from      @tbl_bus           b
  left join @tbl_bus_last_blk  lb on lb.bus = b.bus   
  left join @tbl_bus_at_ltd    al on al.bus = b.bus
  left join @tbl_bus_miles_rem em on em.bus = b.bus

insert @results(calendar_id,bus, miles, at_ltd)
SELECT @calin
	  ,b2.bus
      ,b2.miles
	  ,al2.at_ltd
  from @tbl_buses_other        b2
  left join @tbl_bus_at_ltd    al2 on al2.bus = b2.bus
-- where b.miles >= @other_miles_threshold


SELECT d.class,
       d.bus,
       d.the_date,
	   CAST(CONVERT(VARCHAR(32),d.the_date,112) AS INT)+100000000 calendar_id,
       d.life_miles,
       d.miles_eam,
       d.fueled_qty
INTO #temp_eam_miles
FROM [LTD-EAM].ltd_db.dbo.daily_vehicle_daily_miles_eam_and_tm d
WHERE 1=1
--AND d.the_date >= @caldt AND d.the_date < DATEADD(DAY,1,@caldt)
      AND
      ( ISNULL(d.miles_eam,0) > 0
  --        OR 
		--ISNULL(d.miles_tm,0) > 0
      )
ORDER BY d.class ASC,
         d.bus ASC
OPTION (MAXDOP 2)


CREATE INDEX #temp_eam_miles_calendar_id ON #temp_eam_miles ([calendar_id])
INCLUDE ([bus],[miles_eam]);


-- drop table [tm].[bus_miles_active_daily_staging]
IF(SELECT COUNT(*) FROM sys.tables WHERE name = 'bus_miles_active_daily_staging') = 0
BEGIN
CREATE TABLE [tm].[bus_miles_active_daily_staging](
	rn INT IDENTITY(1,1) NOT NULL,
	calendar_id INT NOT NULL,
	[bus] [VARCHAR](9) NULL,
	[tm_miles] [NUMERIC](9, 2) NULL,
	[eam_miles] NUMERIC(9,2) NULL,
	[last_block] [VARCHAR](5) NULL,
	[miles_total_est] [NUMERIC](9, 2) NULL,
	[pull_in] [CHAR](5) NULL,
	[at_ltd] [SMALLINT] NULL,
	record_created_date DATETIME2 NOT NULL DEFAULT SYSDATETIME()
) 
END

INSERT tm.[bus_miles_active_daily_staging]
(	calendar_id,
    bus,
    tm_miles,
	eam_miles,
	last_block,
	miles_total_est,
	pull_in,
	at_ltd )
select b.calendar_id,
	b.bus,
    b.miles AS tm_miles,
	e.miles_eam AS eam_miles,
	b.last_block,
	b.miles_total_est,
	b.pull_in,
	b.at_ltd
  from @results b
  LEFT JOIN #temp_eam_miles e ON e.bus COLLATE SQL_Latin1_General_CP1_CI_AS = b.bus collate SQL_Latin1_General_CP1_CI_AS 
				AND e.calendar_id = b.calendar_id
  LEFT JOIN @tbl_bus_at_ltd    al on al.bus = b.bus
OPTION (MAXDOP 2)

drop table #temp_eam_miles

END TRY	  


BEGIN CATCH

       DECLARE @profile VARCHAR(255) = (
                    SELECT NAME
                    FROM msdb.dbo.sysmail_profile
                    )
       DECLARE @errormsg VARCHAR(max)
             ,@error INT
             ,@message VARCHAR(max)
             ,@xstate INT
             ,@errsev INT
             ,@sub VARCHAR(255);

       SELECT @error = ERROR_NUMBER()
             ,@errsev = ERROR_SEVERITY()
             ,@message = ERROR_MESSAGE()
             ,@xstate = XACT_STATE();

       SELECT @errormsg = 'Error in ' + isnull(@SPROC, '') + ': ' + cast(isnull(@error, '') AS NVARCHAR(32)) + '|' + coalesce(@message, '') + '|' + cast(isnull(@xstate, '') AS NVARCHAR(32)) + '|' +cast(isnull(@errsev, '') AS NVARCHAR(32))

       SELECT @sub = 'ERROR: ' + @SPROC

       EXEC msdb.dbo.sp_send_dbmail @profile_name = @profile
             ,@recipients = 'barb.eichberger@ltd.org'--;servicedesk@ltd.org' 
             ,@subject = @sub
             ,@body = @errormsg;

       RAISERROR (
                    @errormsg
                    ,@errsev
                    ,1
                    )
END CATCH
GO
