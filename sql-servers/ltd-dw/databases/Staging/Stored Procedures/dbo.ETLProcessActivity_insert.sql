SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [dbo].[ETLProcessActivity_insert]  (@ETLProcessID INT)
AS

INSERT dbo.ETLProcessActivity(ETLProcessID, StartTime )
VALUES ( @ETLProcessID, GETDATE())

RETURN SCOPE_IDENTITY()
--returning ETLProcessActivityID

GO
