SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

create function [dbo].[F_CALENDAR_ID_TO_DATE] (@iCalendarID int)
returns datetime
as 
/* -------------------------------------------------------------------
 	FUNCTION: F_CALENDAR_ID_TO_DATE
   -------------------------------------------------------------------
Arguments: @dtDateIn:  Date to translate to CALENDAR_ID

Returns: Returns an integer that represents the CALENDAR_ID
         active on @dtDateIn.
-------------------------------------------------------------------
Date         Name           Description
                            query, but commented out, for reference.
-------------------------------------------------------------------
--  $Copyright: Copyright 2004, All Rights Reserved, Trapeze ITS U.S.A., LLC $
*/   
begin
    declare @dtCalendarDate datetime,
      @chCalendarID char(9)

    /*
    select @dtCalendarID=CALENDAR_DATE
    from [TMRealTime].TMMain.dbo.SERVICE_CALENDAR
        where CALENDAR_ID=@iCalendarID
    */

    -- Convert calendar_id integer type to varchar type
    set @chCalendarID = cast(@iCalendarID as char(9))

    -- Extract fields from calendar_id and build datetime 
    set @dtCalendarDate = cast(substring(@chCalendarID,6,2)
      +'/'+substring(@chCalendarID,8,2)
      +'/'+substring(@chCalendarID,2,4) as datetime)

    -- Return result
    return @dtCalendarDate
end

GO
