SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE FUNCTION [dbo].[F_getHHMM_from_SPM] (@spm INT)

returns varchar(20)
AS
-- usage 
-- select dbo.F_getHHMM_from_SPM(80933)
BEGIN

DECLARE @spmtime VARCHAR(20)

SELECT @spmtime = 
	(SELECT LEFT(RIGHT(CONVERT(varchar, @spm / 86400 ) + ':' + -- Days
	CONVERT(varchar, DATEADD(ms, ( @spm % 86400 ) * 1000, 0), 114),12),5))

RETURN @spmtime

END
GO
