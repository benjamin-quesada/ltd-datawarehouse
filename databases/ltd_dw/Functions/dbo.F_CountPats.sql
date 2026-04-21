SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
Create FUNCTION [dbo].[F_CountPats] 
(
@txt varchar(max),
@Pat varchar(max)
)
RETURNS 
@tab TABLE 
(
 ID int
)
AS
BEGIN
Declare @pos int
Declare @oldpos int
Select @oldpos=0
select @pos=patindex(@pat,@txt) 
while @pos > 0 and @oldpos<>@pos
 begin
   insert into @tab Values (@pos)
   Select @oldpos=@pos
   select @pos=patindex(@pat,Substring(@txt,@pos + 1,len(@txt))) + @pos
end

RETURN 
END

GO
