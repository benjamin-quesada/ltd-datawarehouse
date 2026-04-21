SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

CREATE function [tm].[convert_passing_time] (@p_xing_time int) returns char(5) as

begin
   declare @hour as int
   declare @min as int
   declare @s_hh as varchar(2)
   declare @s_mm as varchar(2)

   if @p_xing_time < 0
      set @p_xing_time = 0

   set @hour = @p_xing_time / 3600
   set @min  = (@p_xing_time - (@hour * 3600)) / 60
   set @s_hh = right('0' + cast(@hour as varchar(2)),2)
   set @s_mm = right('0' + cast(@min as varchar(2)),2)

   return @s_hh + ':' + @s_mm
end

GO
