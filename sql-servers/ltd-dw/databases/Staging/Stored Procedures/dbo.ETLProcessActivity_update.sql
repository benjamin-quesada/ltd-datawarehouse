SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE   PROCEDURE [dbo].[ETLProcessActivity_update]  (@ETLProcessActivityID INT, @row INT)
AS

UPDATE dbo.ETLProcessActivity
SET EndTime = GETDATE(),
	ProcessRowCount = @row
WHERE ETLProcessActivityID = @ETLProcessActivityID
AND EndTime IS NULL;


GO
