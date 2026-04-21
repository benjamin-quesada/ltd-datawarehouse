SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/************************************
Stolen from http://www.bennadel.com/blog/473-sql-iszero-and-nullif-for-dividing-by-zero.htm
This simply checks the passed in number to see if it Zero. If it is, then I just pass back the alternate number. 
If is not Zero, then I pass back the original value. This allows me to pass in computational-heavy numbers without 
having to compute them more than once.
*****************************************/



CREATE FUNCTION [dbo].[IsZero] (
@Number FLOAT,
@IsZeroNumber FLOAT
)
RETURNS FLOAT
AS
BEGIN
 

IF (@Number = 0)
BEGIN
SET @Number = @IsZeroNumber
END
 

RETURN (@Number)
 

END
GO
