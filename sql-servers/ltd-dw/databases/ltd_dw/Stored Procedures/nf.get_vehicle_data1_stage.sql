SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [nf].[get_vehicle_data1_stage]
--GRANT EXECUTE ON [nf].[get_vehicle_data1_stage] TO public
@filenm VARCHAR(255)

-- exec nf.get_vehicle_data1_stage 'E:\filedrop\newflyer\NewFlyerParams_20201_202205010300.txt'


AS
BEGIN TRY
SET NOCOUNT ON

  DECLARE @SPROC VARCHAR(100)
  SET @SPROC = OBJECT_SCHEMA_NAME(@@PROCID) + '.' + OBJECT_NAME(@@PROCID)

DECLARE @sqlcmd NVARCHAR(MAX) = ''
SELECT @sqlcmd = @sqlcmd + '
insert ltd_dw.[nf].[newflyer_vehicledata1_stage] (response,[fileloadname]) 
SELECT response,'''+@filenm+''' FROM ( 
SELECT p.[response] 
FROM OPENROWSET (BULK '''+@filenm+''', SINGLE_CLOB) as j
 CROSS APPLY OPENJSON(BulkColumn) 
WITH (
[response] nvarchar(max) as json
) AS p) o '


EXEC sp_executesql @sqlcmd

END TRY

BEGIN CATCH


       DECLARE @profile VARCHAR(255) = (
                    SELECT TOP(1) [NAME]
                    FROM msdb.dbo.sysmail_profile
                    )
       DECLARE @errormsg VARCHAR(MAX)
             ,@error INT
             ,@message VARCHAR(MAX)
             ,@xstate INT
             ,@errsev INT
             ,@sub VARCHAR(255);

       SELECT @error = ERROR_NUMBER()
             ,@errsev = ERROR_SEVERITY()
             ,@message = ERROR_MESSAGE()
             ,@xstate = XACT_STATE();

       SELECT @errormsg = 'Error in ' + ISNULL(@SPROC, '') + ': ' + CAST(ISNULL(@error, '') AS NVARCHAR(32)) + '|' + COALESCE(@message, '') + '|' + CAST(ISNULL(@xstate, '') AS NVARCHAR(32)) + '|' +CAST(ISNULL(@errsev, '') AS NVARCHAR(32))

       SELECT @sub = 'ERROR: ' + @SPROC

       EXEC msdb.dbo.sp_send_dbmail @profile_name = @profile
             ,@recipients = 'barb.eichberger@ltd.org' 
             ,@subject = @sub
             ,@body = @errormsg;

       RAISERROR (
                    @errormsg
                    ,@errsev
                    ,1
                    )
END CATCH
GO
GRANT EXECUTE ON  [nf].[get_vehicle_data1_stage] TO [public]
GO
