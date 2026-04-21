SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE FUNCTION [dbo].[F_getHHMMSSMMM_from_SPM] (@spm INT)

returns varchar(20)
AS
-- usage select dbo.F_getHHMMSSMMM_from_SPM(81000)
BEGIN

DECLARE @spmtime VARCHAR(20)

SELECT @spmtime = 
	(SELECT RIGHT(CONVERT(varchar, @spm / 86400 ) + ':' + -- Days
	CONVERT(varchar, DATEADD(ms, ( @spm % 86400 ) * 1000, 0), 114),12))

RETURN @spmtime

END
GO
