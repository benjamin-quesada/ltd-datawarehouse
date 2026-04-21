SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS OFF
GO


CREATE function [tm].[convert_spm_to_hh_mm_ss] (@p_xing_time int) returns char(8) with schemabinding as

begin
   declare @hour as int
   declare @min as int
   declare @sec as int
   declare @s_hh as varchar(2)
   declare @s_mm as varchar(2)
   declare @s_ss as varchar(2)


   if @p_xing_time < 1
      set @p_xing_time = 0

   set @hour = @p_xing_time / 3600
   set @min = (@p_xing_time - (@hour * 3600)) / 60
   set @sec = @p_xing_time - (@hour * 3600) - (@min * 60)
   set @s_hh = right('0' + cast(@hour as varchar(2)),2)
   set @s_mm = right('0' + cast(@min as varchar(2)),2)
   set @s_ss = right('0' + cast(@sec as varchar(2)),2)

   return @s_hh + ':' + @s_mm + ':' + @s_ss
end
GO
