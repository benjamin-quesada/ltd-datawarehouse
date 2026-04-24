SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

create function [dbo].[F_DATE_TO_CALENDAR_ID] (@dtDateIn datetime)
returns int
as 
/* -------------------------------------------------------------------
 	FUNCTION: F_DATE_TO_CALENDAR_ID
   -------------------------------------------------------------------
Arguments: @dtDateIn:  Date to translate to CALENDAR_ID

Returns: Returns a numeric that represents the CALENDAR_ID
         active on @dtDateIn.
-------------------------------------------------------------------
Date         Name           Description
-----------  -------------- --------------------------------------
1/9/2004     D.Tigges       Function to translate Date to CALENDAR_ID
12/20/2004   D.Tigges       Modified function to calculate the "expected" calendar_id
                            based upon TransitMaster business rules.  Kept original
                            query, but commented out, for reference.
-------------------------------------------------------------------
--  $Copyright: Copyright 2004, All Rights Reserved, Trapeze ITS U.S.A., LLC $
*/   
begin
    declare @nCalendarID numeric(10)

/*
    select @nCalendarID = CALENDAR_ID
    from TMDataMart.dbo.CALENDAR
        where convert(datetime,@dtDateIn,101) = CALENDAR_DATE
*/

    set @nCalendarID = 100000000 + (datepart(yyyy,@dtDateIn)*10000) + (datepart(mm,@dtDateIn)*100) + datepart(dd,@dtDateIn)

    return @nCalendarID
end

GO
