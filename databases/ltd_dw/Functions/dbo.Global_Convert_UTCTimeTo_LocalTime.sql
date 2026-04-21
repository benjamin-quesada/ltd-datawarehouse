SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE FUNCTION [dbo].[Global_Convert_UTCTimeTo_LocalTime]
(
   @LocalTimeZone        VARCHAR(50),
   @UTCDateTime          DATETIME
)
RETURNS DATETIME
AS
BEGIN
   DECLARE @ConvertedDateTime DATETIME;

   SELECT @ConvertedDateTime = @UTCDateTime AT TIME ZONE 'UTC' AT TIME ZONE @LocalTimeZone
   RETURN @ConvertedDateTime

END
GO
