SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

create PROCEDURE [hastus].[create_layovers_by_the_minute] AS
--This stored procedure creates a row in ltd-layovers_per_minute for each minute between arrival and departure in layovers

declare @minute smallint
declare @booking_id varchar(6), @sched_type_id smallint, @place_id varchar(6), @arrival_minutes smallint, @departure_minutes smallint
declare c_layovers  cursor for select booking_id, sched_type_id, place_id, arrival_minutes, departure_minutes from hastus.layovers

open c_layovers
fetch next from c_layovers into @booking_id, @sched_type_id, @place_id, @arrival_minutes, @departure_minutes

while @@fetch_status = 0
   begin
      begin transaction
      set @minute = @arrival_minutes
      while @minute <= @departure_minutes
         begin
            insert into [hastus].[layovers_by_the_minute] (booking_id, sched_type_id, place_id, minute) values(@booking_id, @sched_type_id, @place_id, @minute)
            set @minute = @minute +1
         end
      fetch next from c_layovers into @booking_id, @sched_type_id, @place_id, @arrival_minutes, @departure_minutes
      commit transaction
   end

close c_layovers
deallocate c_layovers
GO
