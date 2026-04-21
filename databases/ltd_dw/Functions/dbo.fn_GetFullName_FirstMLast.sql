SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  FUNCTION [dbo].[fn_GetFullName_FirstMLast](
@fName nvarchar(256), 
@mName nvarchar(256),
@lName nvarchar(256))
  
RETURNS nvarchar(768) AS  
BEGIN 
DECLARE @fullName nvarchar(768)
SELECT @fullName = LTRIM(RTRIM(LTRIM(@fName))+RTRIM(' '+LTRIM(ISNULL(@mName,'')))+RTRIM(' '+LTRIM(@lName)))
return @fullName
END
GO
