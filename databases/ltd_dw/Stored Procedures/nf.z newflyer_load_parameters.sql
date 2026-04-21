SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [nf].[z newflyer_load_parameters]
as
-- exec [nf].[newflyer_load_parameters]
BEGIN TRY

set nocount on;

DECLARE @SPROC VARCHAR(100)
SET @SPROC = OBJECT_SCHEMA_NAME(@@PROCID) + '.' + OBJECT_NAME(@@PROCID)

DECLARE @sdt datetime2 = SYSDATETIME()
declare @insCount INT = 0 

DECLARE @i INT = (SELECT MIN([vpLoadKey]) -- select * 
								from [nf].[newflyer_parameters_stage]
								)
DECLARE @r INT = (SELECT MAX([vpLoadKey]) -- select * 
								from [nf].[newflyer_parameters_stage]
								)

WHILE @i <= @r
BEGIN

DECLARE @json nvarchar(max)  = ''
SELECT @json = @json + (SELECT response FROM [nf].[newflyer_parameters_stage] WHERE [vpLoadKey] = @i)
--SELECT [vpLoadKey],response FROM [nf].[newflyer_parameters_stage] WHERE [vpLoadKey] = @i
declare @currvpLoadKey int = 1
select @currvpLoadKey = (SELECT [vpLoadKey] FROM [nf].[newflyer_parameters_stage] WHERE [vpLoadKey] = @i)
select @currvpLoadKey

INSERT [nf].[newflyer_parameters](
       [vehicle_id]
      ,[license_number]
      ,[parameter_type]
      ,[parameter_type_description]
      ,[last_input_value]
      ,[last_input_time]
      ,[last_input_time_local]
	  ,record_created_date
	)
SELECT u.vehicle_id,
       u.license_number,
       u.parameter_type,
       u.parameter_type_description,
       u.last_input_value,
       u.last_input_time,
       u.last_input_time_local,
       u.sdt FROM (
SELECT CAST(vehicle_id AS INT) vehicle_id,
       license_number,
	   parameter_type,
	   REPLACE(replace(replace([parameter_type_description],'%20',' '),'%3A',':'),'%2F','-') [parameter_type_description]	   ,
	   last_input_value,
	   convert(datetime2(0),cast(REPLACE([last_input_time],'%3A',':') as datetime2)) [last_input_time],
       convert(datetime2(0),cast(REPLACE([last_input_time],'%3A',':') as datetime2) AT TIME ZONE 'UTC' AT TIME ZONE 'Pacific Standard Time' ) [last_input_time_local],
	   @sdt sdt
	FROM OPENJSON(@json, '$.properties.data')
WITH (vehicle_id NVARCHAR(32) '$.vehicle_id',
	  license_number NVARCHAR(32) '$.license_number',
	  parameter_type INTEGER '$.parameter_type',
      parameter_type_description VARCHAR(122) '$.parameter_type_description',
      last_input_value NUMERIC(18,7)'$.last_input_value',
      last_input_time VARCHAR(32) '$.last_input_time'
	  ) o
WHERE NOT EXISTS (SELECT 1 FROM nf.newflyer_parameters WHERE
				o.parameter_type = parameter_type 
				AND o.vehicle_id = vehicle_id
				AND o.last_input_time = last_input_time
			)
) u WHERE u.vehicle_id IS NOT null

delete from [nf].[newflyer_parameters_stage] where vpLoadKey = @currvpLoadKey

select @insCount = @insCount + (select count(distinct [vehParamsKey]) from [nf].[newflyer_parameters]  where record_created_date = @sdt)


insert process.mergeLogs
(		[MergeCode]
           ,[ObjectDestination]
           ,[ObjectSource]
           ,[ObjectProgram]
           ,[recInsert]
           ,[recUpdate]
           ,[recDelete]
           ,[MergeBeginDatetime]
           ,[MergeEndDatetime])
select 'NFVD',
'ltd_dw.nf.newflyer_parameters',
'NFAPI',
'SSIS_ISC_PROCESS_NewFlyer_GetNewFlyerParameters' ,
isnull(@insCount,0) ,0,0,
@sdt,
sysdatetime()


SELECT @i = @i + 1
IF @i > @r
BREAK
	ELSE CONTINUE

END
END TRY
BEGIN CATCH

       DECLARE @profile VARCHAR(255) = (
                    SELECT NAME
                    FROM msdb.dbo.sysmail_profile
                    )
       DECLARE @errormsg VARCHAR(max)
             ,@error INT
             ,@message VARCHAR(max)
             ,@xstate INT
             ,@errsev INT
             ,@sub VARCHAR(255);

       SELECT @error = ERROR_NUMBER()
             ,@errsev = ERROR_SEVERITY()
             ,@message = ERROR_MESSAGE()
             ,@xstate = XACT_STATE();

       SELECT @errormsg = 'Error in ' + isnull(@SPROC, '') + ': ' + cast(isnull(@error, '') AS NVARCHAR(32)) + '|' + coalesce(@message, '') + '|' + cast(isnull(@xstate, '') AS NVARCHAR(32)) + '|' +cast(isnull(@errsev, '') AS NVARCHAR(32))

       SELECT @sub = 'ERROR: ' + @SPROC

       EXEC msdb.dbo.sp_send_dbmail @profile_name = @profile
             ,@recipients = 'barb.eichberger@ltd.org'--;servicedesk@ltd.org' 
             ,@subject = @sub
             ,@body = @errormsg;

       RAISERROR (
                    @errormsg
                    ,@errsev
                    ,1
                    )
END CATCH
GO
