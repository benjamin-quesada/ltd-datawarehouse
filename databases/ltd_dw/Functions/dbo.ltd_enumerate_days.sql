SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--USE [midas]
----GO
--/****** Object:  UserDefinedFunction [dbo].[ltd_enumerate_days]    Script Date: 4/16/2024 4:09:04 PM ******/
--SET ANSI_NULLS OFF
--GO
--SET QUOTED_IDENTIFIER ON
--GO
create FUNCTION [dbo].[ltd_enumerate_days] (@fromdate datetime, @thrudate datetime)
RETURNS @enumerated_days TABLE
   (
   the_day datetime
   )
AS
BEGIN 
   declare @i int
   set @i = 0
   while dateadd(day, @i, @fromdate) <= @thrudate
      begin
         insert into @enumerated_days select dateadd(day, @i, @fromdate)
          set @i = @i +1
      end
   RETURN
END

GO
