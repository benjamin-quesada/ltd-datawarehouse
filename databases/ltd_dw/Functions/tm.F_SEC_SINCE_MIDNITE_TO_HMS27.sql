SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE FUNCTION [tm].[F_SEC_SINCE_MIDNITE_TO_HMS27](@iSeconds INT,@bPadHours BIT)
RETURNS CHAR(6)
AS 
/* -------------------------------------------------------------------
 	FUNCTION: F_SEC_SINCE_MIDNITE_TO_HMS
   -------------------------------------------------------------------
Arguments: @iSeconds:  seconds-since-midnight to 
                       convert to HMS format.
           @bPadHours: bit value, 1=if hours are single digit, zero-pad
                       to force to two digits, eg 8:00:00 would return
                       as 080000. If @bPadHours was 0 then 8:00:00 would
                       be return as 80000.

Returns: Returns a char(6) that represents HMS (hours, minutes, seconds)
         since midnight in the form, HHMMSS or HMMSS. Note that a 24 
         hour format is always returned, eg 1:00:00 PM would be returned
         as 130000.
----------------------------------------------------------------------
Date         Name           Description
-----------  -------------- ------------------------------------------
4/6/2005      J.Melter      Function to convert seconds-since-midnight
                            integer parameter to and HMS char(6)
11/15/2007   J.Melter       Updated to allow for hours to be greater
                            than 24 with a limit of 99.
----------------------------------------------------------------------
--  $Copyright: Copyright 2004, All Rights Reserved, Trapeze ITS U.S.A., LLC $
*/   
BEGIN
    DECLARE @chHMS CHAR(6),
            @iHours INT
    -- Calculate the hours
    SET @iHours=@iSeconds/3600
	
    -- if hours is greater than 99
    -- (if it would exceed char(6)
    IF (@iHours>99)
       -- we must limit hours to the max
       SET @iHours=99

    -- if more than one day's worth of seconds was provided...
--    if (@iSeconds>=86400)
--    begin
        -- Adjust the seconds value to be seconds-since-midnite for one day
--        set @iSeconds=@iSeconds%86400
--    end
--    else
    -- Account for apparently invalid data in mdt_timestamp column
    -- so far the MDT_S15_AUTO_COUNT_2 containing the S15_TIME_COUNTER_STRUCT
    -- caused values of -1, -2 and -3. See IlG_Common\LogMsgDefns.h,
    -- MSG_EX_CLASS(MDT_S15_AUTO_COUNT_2)::PrepareLogging where value
    -- is set to be inserted into TMDailyLog..logged_message table.

    -- if seconds was negative
    IF (@iSeconds<0)
    BEGIN
        -- Adjust the seconds value to be seconds-since-midnite for one day
        SET @iSeconds=0
    END

    -- Convert seconds-since-midnite to HMS and return it
    RETURN
        CASE @bPadHours
            WHEN 1 THEN   
            CAST(REPLACE(STR(@iHours,2,0),' ','0') AS VARCHAR)
            ELSE
			CAST(@iHours AS VARCHAR)
        END
        +
        CAST(REPLACE(STR(@iSeconds%3600/60,2,0),' ','0') AS VARCHAR)
        +
        CAST(REPLACE(STR(@iSeconds%3600%60,2,0),' ','0') AS VARCHAR)
END
GO
