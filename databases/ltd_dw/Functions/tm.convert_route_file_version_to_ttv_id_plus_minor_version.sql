SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE FUNCTION [tm].[convert_route_file_version_to_ttv_id_plus_minor_version] (@rte_file_ver INT) RETURNS VARCHAR(10) AS
BEGIN 
   RETURN CAST(@rte_file_ver / POWER(2,8) AS VARCHAR(4)) + '.' + CAST(@rte_file_ver - (@rte_file_ver / POWER(2,8) * POWER(2,8)) AS VARCHAR(4))
END
GO
