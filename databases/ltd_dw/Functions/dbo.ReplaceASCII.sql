SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE FUNCTION [dbo].[ReplaceASCII](@inputString VARCHAR(8000))
RETURNS VARCHAR(55)
AS
     BEGIN
         DECLARE @badStrings VARCHAR(100);
         DECLARE @increment INT= 1;
         WHILE @increment <= DATALENGTH(@inputString)
             BEGIN
                 IF(ASCII(SUBSTRING(@inputString, @increment, 1)) < 33)
                     BEGIN
                         SET @badStrings = CHAR(ASCII(SUBSTRING(@inputString, @increment, 1)));
                         SET @inputString = REPLACE(@inputString, @badStrings, '');
                 END;
                 SET @increment = @increment + 1;
             END;
         RETURN @inputString;
     END;
GO
