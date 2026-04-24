SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE FUNCTION [dbo].[fn_IntToTimeString] (@time INT)
RETURNS VARCHAR(20)
AS
BEGIN
    DECLARE @return VARCHAR(20);
    SET @return = '';
    IF @time IS NOT NULL
       AND @time >= 0
       AND @time < 240000
        SELECT
            @return
            = REPLACE( CONVERT(VARCHAR(20), CONVERT(TIME, LEFT(RIGHT('000000'
                     + CONVERT(VARCHAR(6), @time), 6), 2)
                     + ':'
                     + SUBSTRING(RIGHT('000000' + CONVERT(VARCHAR(6), @time), 6), 3, 2) + ':'
                     + RIGHT('00' + CONVERT(VARCHAR(6), @time), 2)),109),'.0000000',' '
 );
    RETURN @return;
END;
GO
