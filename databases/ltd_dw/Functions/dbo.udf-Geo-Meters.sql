SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Function [dbo].[udf-Geo-Meters](@Lat1 FLOAT, @Lng1 FLOAT, @Lat2 FLOAT, @Lng2 FLOAT)
Returns Float as
Begin
    Return ACOS(SIN(PI()*@Lat1/180.0)*SIN(PI()*@Lat2/180.0)+COS(PI()*@Lat1/180.0)*COS(PI()*@Lat2/180.0)*COS(PI()*@Lng2/180.0-PI()*@Lng1/180.0)) * 6371008.8
    -- 6.371 mean radius of earth in meters
End
GO
