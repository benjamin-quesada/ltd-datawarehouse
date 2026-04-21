SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE FUNCTION [tm].[F_SEC_SINCE_MIDNITE_TO_HMSFMT] (@Sec INT)
RETURNS CHAR(10)
AS 
/* -------------------------------------------------------------------
 	FUNCTION: F_SEC_SINCE_MIDNITE_TO_HMS
   -------------------------------------------------------------------
Arguments: @Sec:  Seconds to HH:MI:SS

-------------------------------------------------------------------
Date         Name           Description
                            query, but commented out, for reference.
-------------------------------------------------------------------
--  $Copyright: Copyright 2004, All Rights Reserved, Trapeze ITS U.S.A., LLC $
*/   
BEGIN
    RETURN
    CASE WHEN @Sec<0 THEN '-'+REPLACE(STR((ABS(@Sec)/3600),2),' ','0') + ':'+REPLACE(STR((ABS(@Sec)/60)%60,2),' ','0')+':'+REPLACE(STR(ABS(@Sec)%60,2),' ','0')
                        ELSE REPLACE(STR((ABS(@Sec)/3600),2),' ','0') + ':'+REPLACE(STR((ABS(@Sec)/60)%60,2),' ','0')+':'+REPLACE(STR(ABS(@Sec)%60,2),' ','0') END

END

GO
