SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--USE [ltd_db]
--GO
--/****** Object:  UserDefinedFunction [dbo].[buses_active_today_udf]    Script Date: 3/11/2022 2:57:43 PM ******/
--SET ANSI_NULLS ON
--GO
--SET QUOTED_IDENTIFIER ON
--GO
CREATE   FUNCTION [tm].[buses_active_today_udf]()
RETURNS @results TABLE(bus VARCHAR(9), miles NUMERIC(9,2), last_block VARCHAR(5), miles_total_est NUMERIC(9,2), pull_in CHAR(5), at_ltd SMALLINT) AS
BEGIN
DECLARE @tbl_bus             TABLE(bus VARCHAR(9), miles NUMERIC(9,2))
DECLARE @tbl_buses_other     TABLE(bus VARCHAR(9), miles NUMERIC(9,2))
DECLARE @tbl_xing            TABLE(unique_id INT IDENTITY PRIMARY KEY, bus VARCHAR(9), miles NUMERIC(9,2), block VARCHAR(5), xing_spm INT, adherence INT)
DECLARE @tbl_locs_other      TABLE(unique_id INT IDENTITY PRIMARY KEY, bus VARCHAR(9), miles NUMERIC(9,2))
DECLARE @tbl_bus_max_id      TABLE(bus VARCHAR(9), max_id INT)
DECLARE @tbl_bus_at_ltd      TABLE(bus VARCHAR(9), at_ltd SMALLINT)
DECLARE @tbl_cur_pull_in     TABLE(blk_no VARCHAR(9), pull_in CHAR(5))
DECLARE @tbl_bus_last_blk    TABLE(bus VARCHAR(9), last_block VARCHAR(5), pull_in CHAR(5), last_xing INT, adherence INT)
DECLARE @tbl_bus_last_loc_id TABLE(bus VARCHAR(9), id BIGINT)
DECLARE @tbl_bus_miles_rem   TABLE(bus VARCHAR(9), miles NUMERIC(9,2))
 
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
  from [ltd-tmdata].tmmain.dbo.block            bk
  join [ltd-tmdata].tmmain.dbo.current_version  cv on cv.time_table_version_id = bk.time_table_version_id
  --join [ltd-tmdata].tmdailylog.dbo.roster_stats rs on rs.block_id              = bk.block_id
  JOIN [ltd-tmdata].tmdailylog.dbo.daily_pullout dp ON dp.block_id  = bk.block_id AND dp.calendar_id = cv.calendar_id
  
 
insert @tbl_xing(bus, miles, block, xing_spm, adherence)
select lm.veh
      ,lm.odometer
      ,lm.block
         ,lm.mdt_spm
         ,lm.long_field_2
  from reporting.[tm].[logged_messages] lm
  join [ltd-tmdata].tmmain.dbo.current_version        cv on cv.calendar_id = lm.calendar_id
  where lm.veh is not null
       and isnumeric(lm.veh)  = 1
    and lm.message_type_id = 16
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
SELECT
b.bus, MAX(loc.transmitted_message_id)
 FROM Reporting.tm.logged_messages loc
  join [ltd-tmdata].tmmain.dbo.current_version          cv  on cv.calendar_id = loc.calendar_id
  join [ltd-tmdata].tmmain.dbo.vehicle                  v   on v.PROPERTY_TAG = loc.veh
  join @tbl_bus b   on b.bus = v.property_tag
group by b.bus
 
set @cur_bus   = (select bus   from @tbl_xing where unique_id = @cur_id)
set @cur_miles = (select miles from @tbl_xing where unique_id = @cur_id)
set @pre_bus   = (select bus   from @tbl_xing where unique_id = @cur_id -1)
set @pre_miles = (select miles from @tbl_xing where unique_id = @cur_id -1)
 
while (@cur_id <= @max_id)
   begin
      if @cur_bus <> @pre_bus
         begin
            update @tbl_bus set miles = miles + @pre_miles where bus = @pre_bus
            set @pre_bus   = @cur_bus
            SET @pre_miles = @cur_miles
         END
      ELSE
         BEGIN
            if @cur_miles < @pre_miles
               begin
                  update @tbl_bus set miles = miles + @pre_miles where bus = @cur_bus
               end
 
               SET @pre_miles = @cur_miles
          END
         if @cur_id = @max_id
             update @tbl_bus set miles = miles + @pre_miles where bus = @cur_bus
 
      set @cur_id    = @cur_id +1
      set @cur_bus   = (select bus   from @tbl_xing where unique_id = @cur_id)
      SET @cur_miles = (SELECT miles FROM @tbl_xing WHERE unique_id = @cur_id)
   END
 
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
  join [ltd-tmdata].ltd_db.dbo.block_trips_end_spm_today bt on bt.blk                   = lb.last_block
  join [ltd-tmdata].tmmain.dbo.current_version    cv on cv.time_table_version_id = bt.time_table_version_id
 where lb.last_xing < bt.end_spm + lb.adherence 
 group by lb.bus
 
insert @tbl_buses_other(bus, miles)
select distinct
       veh.property_tag
      ,0
  from [ltd-tmdata].tmdailylog.dbo.logged_message_short loc
  join [ltd-tmdata].tmmain.dbo.vehicle                  veh on veh.rnet_address = loc.source_host
  join [ltd-tmdata].tmmain.dbo.current_version          cv  on cv.calendar_id   = loc.calendar_id
  join [ltd-tmdata].tmmain.dbo.fleet                    flt on flt.fleet_id     = veh.fleet_id
where loc.calendar_id = cv.calendar_id
   and isnumeric(veh.property_tag) = 1
   and flt.fleet_text = 'fixed route'
   and not (loc.latitude / 10000000.0 between 44.042760 and 44.044320 and loc.longitude / 10000000.0 between -123.04201 and -123.03891)
   and not exists(select * from @tbl_bus i where i.bus = veh.property_tag)
 
insert @tbl_bus_last_loc_id(bus, id)
select b.bus
      ,max(loc.logged_message_short_id)
  from [ltd-tmdata].tmdailylog.dbo.logged_message_short loc
  join [ltd-tmdata].tmmain.dbo.current_version          cv  on cv.calendar_id = loc.calendar_id
  join [ltd-tmdata].tmmain.dbo.vehicle                  v   on v.rnet_address = loc.source_host
  join @tbl_buses_other                    b   on b.bus          = v.property_tag
group by b.bus
 
insert @tbl_bus_at_ltd(bus, at_ltd)
select ll.bus
         ,[at_ltd] = case when loc.latitude / 10000000.0 between 44.042760 and 44.044320 and loc.longitude / 10000000.0 between -123.04201 and -123.03891 then 1 else 0 end
  from [ltd-tmdata].tmdailylog.dbo.logged_message_short loc
  join [ltd-tmdata].tmmain.dbo.current_version          cv  on cv.calendar_id = loc.calendar_id
  join @tbl_bus_last_loc_id                ll  on ll.id          = loc.logged_message_short_id
 
insert @tbl_locs_other(bus, miles)
select bus.bus
      ,[odometer] = cast(loc.odometer / 100.0 as numeric(9,2))
  from [ltd-tmdata].tmdailylog.dbo.logged_message_short loc
  join [ltd-tmdata].tmmain.dbo.vehicle                  veh on veh.rnet_address = loc.source_host
  join @tbl_buses_other                    bus on bus.bus          = veh.property_tag
  join [ltd-tmdata].tmmain.dbo.current_version          cv  on cv.calendar_id   = loc.calendar_id
where loc.calendar_id = cv.calendar_id
order by bus, loc.message_timestamp
 
set @cur_id    = 2
set @max_id    = (select max(unique_id) from @tbl_locs_other)
set @cur_bus   = (select bus   from @tbl_locs_other where unique_id = @cur_id)
set @cur_miles = (select miles from @tbl_locs_other where unique_id = @cur_id)
set @pre_bus   = (select bus   from @tbl_locs_other where unique_id = @cur_id -1)
SET @pre_miles = (SELECT miles FROM @tbl_locs_other WHERE unique_id = @cur_id -1)
 
WHILE (@cur_id <= @max_id)
   BEGIN
      IF @cur_bus <> @pre_bus
         BEGIN
            UPDATE @tbl_buses_other SET miles = miles + @pre_miles WHERE bus = @pre_bus
            SET @pre_bus   = @cur_bus
            SET @pre_miles = @cur_miles
         END
      ELSE
         BEGIN
            IF @cur_miles < @pre_miles
               BEGIN
                  UPDATE @tbl_buses_other SET miles = miles + @pre_miles WHERE bus = @cur_bus
               END
 
               SET @pre_miles = @cur_miles
          END
         IF @cur_id = @max_id
             UPDATE @tbl_buses_other SET miles = miles + @pre_miles WHERE bus = @cur_bus
 
      SET @cur_id    = @cur_id +1
      SET @cur_bus   = (SELECT bus   FROM @tbl_locs_other WHERE unique_id = @cur_id)
      SET @cur_miles = (SELECT miles FROM @tbl_locs_other WHERE unique_id = @cur_id)
   END
 
INSERT @results(bus, miles, last_block, miles_total_est, pull_in, at_ltd)
SELECT b.bus
      ,b.miles
         ,lb.last_block
         ,b.miles + em.miles + 11 --estimated DH miles/block
         ,lb.pull_in
         ,al.at_ltd
  FROM      @tbl_bus           b
  LEFT JOIN @tbl_bus_last_blk  lb ON lb.bus = b.bus   
  LEFT JOIN @tbl_bus_at_ltd    al ON al.bus = b.bus
  LEFT JOIN @tbl_bus_miles_rem em ON em.bus = b.bus
 
INSERT @results(bus, miles, at_ltd)
SELECT b.bus
      ,b.miles
 ,al.at_ltd
  FROM @tbl_buses_other        b
  LEFT JOIN @tbl_bus_at_ltd    al ON al.bus = b.bus
-- where b.miles >= @other_miles_threshold
 
RETURN
END
GO
