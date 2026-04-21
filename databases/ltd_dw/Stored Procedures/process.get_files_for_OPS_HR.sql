SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   PROCEDURE [process].[get_files_for_OPS_HR]
AS

SET NOCOUNT ON;

EXECUTE sp_configure 'show advanced options', 1;
GO
