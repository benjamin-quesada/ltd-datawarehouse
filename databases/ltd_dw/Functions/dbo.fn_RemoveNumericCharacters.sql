SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE Function [dbo].[fn_RemoveNumericCharacters](@Temp nVarChar(1000))
Returns VarChar(1000)
AS
Begin

    Declare @NumRange as varchar(50) = '%[0-9]%'
    While PatIndex(@NumRange, @Temp) > 0
        Set @Temp = Stuff(@Temp, PatIndex(@NumRange, @Temp), 1, '')

    Return @Temp
End
GO
