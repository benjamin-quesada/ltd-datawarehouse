SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

CREATE function [tm].[ltd_distance_between_points](@p_lat_1 int, @p_long_1 int, @p_lat_2 int, @p_long_2 int) returns int as

/* algorithm derived from vba code at from: "http://nmml.afsc.noaa.gov/Software/ExcelGeoFunctions/excelgeofunc.htm" */

begin
   declare @r_lat_1 float, @r_lat_2 float, @r_long float, @r_x float
   declare @d_lat_1 decimal(9,7), @d_lat_2 decimal(9,7), @d_long_1 decimal(10,7), @d_long_2 decimal(10,7) 

   if @p_lat_1 is null or @p_lat_1 = 0 or @p_long_1 is null or @p_long_1 = 0 or @p_lat_2 is null or @p_lat_2 = 0 or @p_long_2 is null or @p_long_2 = 0 or
     (@p_lat_1 = @p_lat_2 and @p_long_1 = @p_long_2) return 0

   set @d_lat_1 = @p_lat_1/10000000.0
   set @d_lat_2 = @p_lat_2/10000000.0
   set @d_long_1 = @p_long_1/10000000.0
   set @d_long_2 = @p_long_2/10000000.0
   set @r_lat_1 = radians(@d_lat_1)
   set @r_lat_2 = radians(@d_lat_2)
   set @r_long = radians(@d_long_2 - @d_long_1)
   set @r_x = sin(@r_lat_1) * sin(@r_lat_2) + cos(@r_lat_1) * cos(@r_lat_2) * cos(@r_long)
   if @r_x < -1 or @r_x > 1 return -1
  return acos(@r_x) * 60 * (180/3.141592) * 6076
end
GO
