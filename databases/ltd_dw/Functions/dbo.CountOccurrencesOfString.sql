SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*  Usage:
    SELECT t.[YourColumn], c.StringCount
    FROM YourDatabase.dbo.YourTable t
        CROSS APPLY dbo.CountOccurrencesOfString('your search string',     t.[YourColumn]) c
*/
CREATE FUNCTION [dbo].[CountOccurrencesOfString]
(
    @searchTerm nvarchar(max),
    @searchString nvarchar(max)

)
RETURNS TABLE
AS
    RETURN 
    SELECT (DATALENGTH(@searchString)-DATALENGTH(REPLACE(@searchString,@searchTerm,'')))/NULLIF(DATALENGTH(@searchTerm), 0) AS StringCount
GO
