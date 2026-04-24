SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create  FUNCTION [dbo].[fn_GetFullName_LastFirstM](
@fName nvarchar(256), 
@mName nvarchar(256),
@lName nvarchar(256))
  
RETURNS nvarchar(768) AS  
BEGIN 
DECLARE @fullName nvarchar(768)
SELECT @fullName = LTRIM(RTRIM(LTRIM(@lName))+RTRIM(', '+LTRIM(ISNULL(@fName,'')))+' '+RTRIM(' '+LTRIM(@mName)))
return @fullName
END
GO
