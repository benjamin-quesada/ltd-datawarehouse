SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE function [dbo].[F_DATE_TO_SEC_SINCE_MIDNITE](@dtDateValue datetime)
returns int
as 
/* -------------------------------------------------------------------
 	FUNCTION: F_DATE_TO_SEC_SINCE_MIDNITE
   -------------------------------------------------------------------
Arguments: @dtDateValue:  date value to convert to 
                          seconds-since-midnight

Returns: Returns an integer that represents seconds-since-midnight.
-------------------------------------------------------------------
Date         Name           Description
-----------  -------------- --------------------------------------
4/6/2005      J.Melter      Function to convert a date to 
                            seconds-since-midnight
-------------------------------------------------------------------
--  $Copyright: Copyright 2004, All Rights Reserved, Trapeze ITS U.S.A., LLC $
*/   
begin
    -- Convert seconds-since-midnite to date string
    return
        -- hours
        datepart(hour,@dtDateValue)*3600
        +
        -- minutes
        datepart(minute,@dtDateValue)*60
        +
        -- seconds
        datepart(second,@dtDateValue)
end
GO
