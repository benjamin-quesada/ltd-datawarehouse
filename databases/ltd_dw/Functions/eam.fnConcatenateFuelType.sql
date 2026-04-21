SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

    CREATE FUNCTION [eam].[fnConcatenateFuelType]
    (
    @EQ_Equip_no varchar(90)
    )

    RETURNS nvarchar(120)
    --WITH ENCRYPTION

    AS 

    BEGIN
        DECLARE @StrFP nvarchar(3750)
        --DECLARE @Custpo TABLE(spaceDescription INT, CustomerID INT)
        SET @StrFP = ''
        SET @StrFP = ''
        SELECT @StrFP =  + @StrFP + '; ' + CAST(fuel_type AS nvarchar(50)) 
        FROM wrk.equipfuel co
        WHERE co.EQ_Equip_no = @EQ_Equip_no
    RETURN SUBSTRING(@StrFP, 2, LEN(@StrFP))
    END

GO
