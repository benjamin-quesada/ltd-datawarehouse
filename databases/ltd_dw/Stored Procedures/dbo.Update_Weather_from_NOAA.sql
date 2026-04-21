SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[Update_Weather_from_NOAA]
as
-- exec [dbo].[Update_Weather_from_NOAA]
SET NOCOUNT ON;

  DECLARE @SPROC VARCHAR(100)
  SET @SPROC = OBJECT_SCHEMA_NAME(@@PROCID) + '.' + OBJECT_NAME(@@PROCID)


BEGIN TRY

declare @startdt datetime = sysdatetime()
DECLARE @OutputTbl TABLE (newweather varchar(11))

	UPDATE [process].[MergeLogs]
	SET [MergeEndDatetime] = sysdatetime()
	WHERE mergecode = 'NOAA'
		AND [ObjectDestination] = '[LTD-DW].dbo.Weather'
		AND [ObjectSource] = 'NOAA'
		AND [ObjectProgram] = 'LTD_DW.dbo.Update_Weather_from_NOAA'
		AND [MergeEndDatetime] IS NULL
		AND recInsert = 0
		AND recUpdate = 0
		AND recDelete = 0

	INSERT dbo.Weather (
		[ID]
		,[YR]
		,[mth]
		,[dateId]
		,[ELEMENT]
		,[VALUE]
		,[MFLAG]
		,[QFLAG]
		,[SFLAG]
		,[record_created_date]
		)
	OUTPUT Inserted.ID
	INTO @OutputTbl
	SELECT [ID]
		,[YR]
		,[mth]
		,[dateId]
		,[ELEMENT]
		,[VALUE]
		,[MFLAG]
		,[QFLAG]
		,[SFLAG]
		,[record_created_date]
	FROM (
		SELECT [ID]
			,[YR]
			,[mth]
			,dateId = cast(YR AS VARCHAR(12)) + cast(Mth AS VARCHAR(12)) + '01'
			,[ELEMENT]
			,[V1] VALUE
			,[M1] MFLAG
			,[Q1] QFLAG
			,[S1] SFLAG
			,record_created_date
		FROM [ltd_dw].[stg].[weather_noaa]
		
		UNION
		
		SELECT [ID]
			,[YR]
			,[mth]
			,dateId = cast(YR AS VARCHAR(12)) + cast(Mth AS VARCHAR(12)) + '02'
			,[ELEMENT]
			,[V2]
			,[M2]
			,[Q2]
			,[S2]
			,record_created_date
		FROM [ltd_dw].[stg].[weather_noaa]
		
		UNION
		
		SELECT [ID]
			,[YR]
			,[mth]
			,dateId = cast(YR AS VARCHAR(12)) + cast(Mth AS VARCHAR(12)) + '03'
			,[ELEMENT]
			,[V3]
			,[M3]
			,[Q3]
			,[S3]
			,record_created_date
		FROM [ltd_dw].[stg].[weather_noaa]
		
		UNION
		
		SELECT [ID]
			,[YR]
			,[mth]
			,dateId = cast(YR AS VARCHAR(12)) + cast(Mth AS VARCHAR(12)) + '04'
			,[ELEMENT]
			,[V4]
			,[M4]
			,[Q4]
			,[S4]
			,record_created_date
		FROM [ltd_dw].[stg].[weather_noaa]
		
		UNION
		
		SELECT [ID]
			,[YR]
			,[mth]
			,dateId = cast(YR AS VARCHAR(12)) + cast(Mth AS VARCHAR(12)) + '05'
			,[ELEMENT]
			,[V5]
			,[M5]
			,[Q5]
			,[S5]
			,record_created_date
		FROM [ltd_dw].[stg].[weather_noaa]
		
		UNION
		
		SELECT [ID]
			,[YR]
			,[mth]
			,dateId = cast(YR AS VARCHAR(12)) + cast(Mth AS VARCHAR(12)) + '06'
			,[ELEMENT]
			,[V6]
			,[M6]
			,[Q6]
			,[S6]
			,record_created_date
		FROM [ltd_dw].[stg].[weather_noaa]
		
		UNION
		
		SELECT [ID]
			,[YR]
			,[mth]
			,dateId = cast(YR AS VARCHAR(12)) + cast(Mth AS VARCHAR(12)) + '07'
			,[ELEMENT]
			,[V7]
			,[M7]
			,[Q7]
			,[S7]
			,record_created_date
		FROM [ltd_dw].[stg].[weather_noaa]
		
		UNION
		
		SELECT [ID]
			,[YR]
			,[mth]
			,dateId = cast(YR AS VARCHAR(12)) + cast(Mth AS VARCHAR(12)) + '08'
			,[ELEMENT]
			,[V8]
			,[M8]
			,[Q8]
			,[S8]
			,record_created_date
		FROM [ltd_dw].[stg].[weather_noaa]
		
		UNION
		
		SELECT [ID]
			,[YR]
			,[mth]
			,dateId = cast(YR AS VARCHAR(12)) + cast(Mth AS VARCHAR(12)) + '09'
			,[ELEMENT]
			,[V9]
			,[M9]
			,[Q9]
			,[S9]
			,record_created_date
		FROM [ltd_dw].[stg].[weather_noaa]
		
		UNION
		
		SELECT [ID]
			,[YR]
			,[mth]
			,dateId = cast(YR AS VARCHAR(12)) + cast(Mth AS VARCHAR(12)) + '10'
			,[ELEMENT]
			,[V10]
			,[M10]
			,[Q10]
			,[S10]
			,record_created_date
		FROM [ltd_dw].[stg].[weather_noaa]
		
		UNION
		
		SELECT [ID]
			,[YR]
			,[mth]
			,dateId = cast(YR AS VARCHAR(12)) + cast(Mth AS VARCHAR(12)) + '11'
			,[ELEMENT]
			,[V11]
			,[M11]
			,[Q11]
			,[S11]
			,record_created_date
		FROM [ltd_dw].[stg].[weather_noaa]
		
		UNION
		
		SELECT [ID]
			,[YR]
			,[mth]
			,dateId = cast(YR AS VARCHAR(12)) + cast(Mth AS VARCHAR(12)) + '12'
			,[ELEMENT]
			,[V12]
			,[M12]
			,[Q12]
			,[S12]
			,record_created_date
		FROM [ltd_dw].[stg].[weather_noaa]
		
		UNION
		
		SELECT [ID]
			,[YR]
			,[mth]
			,dateId = cast(YR AS VARCHAR(12)) + cast(Mth AS VARCHAR(12)) + '13'
			,[ELEMENT]
			,[V13]
			,[M13]
			,[Q13]
			,[S13]
			,record_created_date
		FROM [ltd_dw].[stg].[weather_noaa]
		
		UNION
		
		SELECT [ID]
			,[YR]
			,[mth]
			,dateId = cast(YR AS VARCHAR(12)) + cast(Mth AS VARCHAR(12)) + '14'
			,[ELEMENT]
			,[V14]
			,[M14]
			,[Q14]
			,[S14]
			,record_created_date
		FROM [ltd_dw].[stg].[weather_noaa]
		
		UNION
		
		SELECT [ID]
			,[YR]
			,[mth]
			,dateId = cast(YR AS VARCHAR(12)) + cast(Mth AS VARCHAR(12)) + '15'
			,[ELEMENT]
			,[V15]
			,[M15]
			,[Q15]
			,[S15]
			,record_created_date
		FROM [ltd_dw].[stg].[weather_noaa]
		
		UNION
		
		SELECT [ID]
			,[YR]
			,[mth]
			,dateId = cast(YR AS VARCHAR(12)) + cast(Mth AS VARCHAR(12)) + '16'
			,[ELEMENT]
			,[V16]
			,[M16]
			,[Q16]
			,[S16]
			,record_created_date
		FROM [ltd_dw].[stg].[weather_noaa]
		
		UNION
		
		SELECT [ID]
			,[YR]
			,[mth]
			,dateId = cast(YR AS VARCHAR(12)) + cast(Mth AS VARCHAR(12)) + '17'
			,[ELEMENT]
			,[V17]
			,[M17]
			,[Q17]
			,[S17]
			,record_created_date
		FROM [ltd_dw].[stg].[weather_noaa]
		
		UNION
		
		SELECT [ID]
			,[YR]
			,[mth]
			,dateId = cast(YR AS VARCHAR(12)) + cast(Mth AS VARCHAR(12)) + '18'
			,[ELEMENT]
			,[V18]
			,[M18]
			,[Q18]
			,[S18]
			,record_created_date
		FROM [ltd_dw].[stg].[weather_noaa]
		
		UNION
		
		SELECT [ID]
			,[YR]
			,[mth]
			,dateId = cast(YR AS VARCHAR(12)) + cast(Mth AS VARCHAR(12)) + '19'
			,[ELEMENT]
			,[V19]
			,[M19]
			,[Q19]
			,[S19]
			,record_created_date
		FROM [ltd_dw].[stg].[weather_noaa]
		
		UNION
		
		SELECT [ID]
			,[YR]
			,[mth]
			,dateId = cast(YR AS VARCHAR(12)) + cast(Mth AS VARCHAR(12)) + '20'
			,[ELEMENT]
			,[V20]
			,[M20]
			,[Q20]
			,[S20]
			,record_created_date
		FROM [ltd_dw].[stg].[weather_noaa]
		
		UNION
		
		SELECT [ID]
			,[YR]
			,[mth]
			,dateId = cast(YR AS VARCHAR(12)) + cast(Mth AS VARCHAR(12)) + '21'
			,[ELEMENT]
			,[V21]
			,[M21]
			,[Q21]
			,[S21]
			,record_created_date
		FROM [ltd_dw].[stg].[weather_noaa]
		
		UNION
		
		SELECT [ID]
			,[YR]
			,[mth]
			,dateId = cast(YR AS VARCHAR(12)) + cast(Mth AS VARCHAR(12)) + '22'
			,[ELEMENT]
			,[V22]
			,[M22]
			,[Q22]
			,[S22]
			,record_created_date
		FROM [ltd_dw].[stg].[weather_noaa]
		
		UNION
		
		SELECT [ID]
			,[YR]
			,[mth]
			,dateId = cast(YR AS VARCHAR(12)) + cast(Mth AS VARCHAR(12)) + '23'
			,[ELEMENT]
			,[V23]
			,[M23]
			,[Q23]
			,[S23]
			,record_created_date
		FROM [ltd_dw].[stg].[weather_noaa]
		
		UNION
		
		SELECT [ID]
			,[YR]
			,[mth]
			,dateId = cast(YR AS VARCHAR(12)) + cast(Mth AS VARCHAR(12)) + '24'
			,[ELEMENT]
			,[V24]
			,[M24]
			,[Q24]
			,[S24]
			,record_created_date
		FROM [ltd_dw].[stg].[weather_noaa]
		
		UNION
		
		SELECT [ID]
			,[YR]
			,[mth]
			,dateId = cast(YR AS VARCHAR(12)) + cast(Mth AS VARCHAR(12)) + '25'
			,[ELEMENT]
			,[V25]
			,[M25]
			,[Q25]
			,[S25]
			,record_created_date
		FROM [ltd_dw].[stg].[weather_noaa]
		
		UNION
		
		SELECT [ID]
			,[YR]
			,[mth]
			,dateId = cast(YR AS VARCHAR(12)) + cast(Mth AS VARCHAR(12)) + '26'
			,[ELEMENT]
			,[V26]
			,[M26]
			,[Q26]
			,[S26]
			,record_created_date
		FROM [ltd_dw].[stg].[weather_noaa]
		
		UNION
		
		SELECT [ID]
			,[YR]
			,[mth]
			,dateId = cast(YR AS VARCHAR(12)) + cast(Mth AS VARCHAR(12)) + '27'
			,[ELEMENT]
			,[V27]
			,[M27]
			,[Q27]
			,[S27]
			,record_created_date
		FROM [ltd_dw].[stg].[weather_noaa]
		
		UNION
		
		SELECT [ID]
			,[YR]
			,[mth]
			,dateId = cast(YR AS VARCHAR(12)) + cast(Mth AS VARCHAR(12)) + '28'
			,[ELEMENT]
			,[V28]
			,[M28]
			,[Q28]
			,[S28]
			,record_created_date
		FROM [ltd_dw].[stg].[weather_noaa]
		
		UNION
		
		SELECT [ID]
			,[YR]
			,[mth]
			,dateId = cast(YR AS VARCHAR(12)) + cast(Mth AS VARCHAR(12)) + '29'
			,[ELEMENT]
			,[V29]
			,[M29]
			,[Q29]
			,[S29]
			,record_created_date
		FROM [ltd_dw].[stg].[weather_noaa]
		
		UNION
		
		SELECT [ID]
			,[YR]
			,[mth]
			,dateId = cast(YR AS VARCHAR(12)) + cast(Mth AS VARCHAR(12)) + '30'
			,[ELEMENT]
			,[V30]
			,[M30]
			,[Q30]
			,[S30]
			,record_created_date
		FROM [ltd_dw].[stg].[weather_noaa]
		
		UNION
		
		SELECT [ID]
			,[YR]
			,[mth]
			,dateId = cast(YR AS VARCHAR(12)) + cast(Mth AS VARCHAR(12)) + '31'
			,[ELEMENT]
			,[V31]
			,[M31]
			,[Q31]
			,[S31]
			,record_created_date
		FROM [ltd_dw].[stg].[weather_noaa]
		) o
	WHERE NOT EXISTS (
			SELECT id,dateId,Element
			FROM dbo.weather WITH (NOLOCK)
			WHERE dateId = o.dateId
				AND ELEMENT = o.ELEMENT
				and ID = o.ID
				AND [VALUE] = cast(o.[VALUE] as float)
			)
	AND [VALUE] <> -9999

	DECLARE @instd INT

	SELECT @instd = (
			SELECT count(*)
			FROM @OutputTbl
			)

	INSERT [process].[MergeLogs] (
		[MergeCode]
		,[ObjectDestination]
		,[ObjectSource]
		,[ObjectProgram]
		,[recInsert]
		,[recUpdate]
		,[recDelete]
		,[MergeBeginDatetime]
		,MergeEndDatetime
		)
	VALUES (
		'NOAA'
		,'[LTD-DW].dbo.Weather'
		,'NOAA'
		,'LTD_DW.dbo.Update_Weather_from_NOAA'
		,isnull(@instd, 0)
		,0
		,0
		,@startdt
		,sysdatetime()
		)
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
             ,@recipients = 'barb.eichberger@ltd.org' 
             ,@subject = @sub
             ,@body = @errormsg;

       RAISERROR (
                    @errormsg
                    ,@errsev
                    ,1
                    )
END CATCH


GO
