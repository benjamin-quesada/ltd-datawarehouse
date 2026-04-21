SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create function [dbo].[RemoveSpecialChars] (@s varchar(256)) returns varchar(256)
   with schemabinding
begin
   if @s is null
      return null
   declare @s2 varchar(256)
   set @s2 = ''
   declare @l int
   set @l = len(@s)
   declare @p int
   set @p = 1
   while @p <= @l begin
      declare @c int
      set @c = ascii(substring(@s, @p, 1))
      if @c between 48 and 57 or @c between 65 and 90 or @c between 97 and 122
         set @s2 = @s2 + char(@c)
      set @p = @p + 1
      end
   if len(@s2) = 0
      return null
   return @s2
   end
GO
