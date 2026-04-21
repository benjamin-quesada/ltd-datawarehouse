SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [nf].[prepare_data_for_cte] (
	@startDateInt INT)
AS

/*
CREATED DT:		20211014
CREATED BY:		B. Eichberger
PURPOSE   :		Build a longitudinal record of nf parameters required for CTE reporting/KPIs
USAGE	  :		exec nf.prepare_data_for_cte 120211012 (parameter presented by loop programming 
				in sql agent job based on dates not yet processed )

*/


BEGIN TRY
SET NOCOUNT ON

  DECLARE @SPROC VARCHAR(100)
  SET @SPROC = OBJECT_SCHEMA_NAME(@@PROCID) + '.' + OBJECT_NAME(@@PROCID)

--DECLARE @startdateint INT = 120210401
--declare @startDateDt DATE = (select TOP(1) CONVERT(date,cast((max(@startDateInt)-100000000) as char(10)),120) ORDER BY 1 )
--DECLARE @endDateDt DATE = (SELECT TOP(1) CAST(GETDATE()-2 AS DATE) ORDER BY 1)
DECLARE @endDateInt INT = (SELECT TOP(1) CONVERT(varchar(32),GETDATE()-2,112)+100000000 ORDER BY 1)
DECLARE @min bigint, @max bigint
SELECT @Min=0 ,@Max=59;
;

SELECT TOP (@Max-@Min+1) @Min-1+row_number() over(order by t1.number) as N
INTO #minutelist
FROM master..spt_values t1 
    CROSS JOIN master..spt_values t2

DECLARE @minh bigint, @maxh bigint
SELECT @Minh=0 ,@Maxh=23;
;
SELECT TOP (@Maxh-@Minh+1) @Minh-1+row_number() over(order by t1.number) as N
INTO #hourlist
FROM master..spt_values t1 
    CROSS JOIN master..spt_values t2


SELECT rn = ROW_NUMBER() OVER (ORDER BY	CAST(last_input_time AS DATE)),
license_number,CAST(last_input_time AS DATE) last_input_dt,
CAST(CONVERT(VARCHAR(32),CAST(last_input_time AS DATE),112) AS INT)+100000000 calId
INTO #timeloop 
FROM [ltd_dw].[fact].[new_flyer_parameters_limited] 
	WHERE CAST(CONVERT(VARCHAR(32),CAST(last_input_time AS DATE),112) AS INT)+100000000
			BETWEEN @startDateInt AND @endDateInt
	 -- AND license_number = 20208
GROUP BY license_number,CAST(last_input_time AS DATE) ,
CAST(CONVERT(VARCHAR(32),CAST(last_input_time AS DATE),112) AS INT)+100000000 


DECLARE @i INT = 1
DECLARE @r INT
SELECT @r = (SELECT MAX(rn) FROM #timeloop)

WHILE @i <= @r

BEGIN

DECLARE @calId INT = (SELECT TOP(1) calid FROM #timeloop WHERE rn = @i ORDER BY rn)
DECLARE @currlicense INT = (SELECT TOP(1) license_number FROM #timeloop WHERE rn = @i ORDER BY rn)
DECLARE @currDt DATE = (SELECT TOP(1) last_input_dt FROM #timeloop WHERE rn = @i ORDER BY rn)

DELETE FROM nf.prepared_for_cte WHERE calId = @calId and license_number = @currlicense

DROP TABLE IF EXISTS #dayControl

SELECT FORMAT(CAST(CAST(@currDt AS VARCHAR(12))+' '+CAST(h.N AS VARCHAR(12)) +':'+ RIGHT( '00'+CAST(m.N AS VARCHAR(12)),2) AS SMALLDATETIME),'M/d/yyyy %H:mm') [Date And Time Format]
,CAST(CAST(@currDt AS VARCHAR(12))+' '+CAST(h.N AS VARCHAR(12)) +':'+ RIGHT( '00'+CAST(m.N AS VARCHAR(12)),2) AS DATETIME) [Date And Time]
,@calId calId
INTO #dayControl
FROM #hourlist h
	CROSS JOIN #minutelist m

DROP TABLE IF EXISTS #dayDetail


SELECT d.[Date And Time], d.calId
	, o.parameter_type
	, o.license_number
	, o.last_input_value
INTO #dayDetail
	FROM #dayControl d
	LEFT JOIN (--SELECT license_number,COUNT(*) FROM (
		SELECT t.parameter_type_description
				,t.parameter_type
				,p.license_number
				,CAST(p.last_input_value AS DECIMAL(14,5)) last_input_value
				,FORMAT(CAST(p.last_input_time AS DATETIME2),'M/d/yyyy %H:mm') [Date and Time Format] 
				,CAST(FORMAT(CAST(p.last_input_time AS DATETIME2),'M/d/yyyy %H:mm') AS DATETIME) [Date and Time] 
			FROM -- select top(100) * from 
			[ltd_dw].[fact].[new_flyer_parameters_limited] p
			JOIN -- select * from 
			dim.new_flyer_parameter_type t ON t.[parameter_type] = p.[parameter_type]
			WHERE 1=1 
			AND p.license_number = @currlicense --20208 -- 
			AND CAST(p.last_input_time AS DATE) = @currDt -- '2021-08-01 14:09:33' --
			) o
		ON d.[Date And Time] = o.[Date And Time]


INSERT -- truncate table
nf.prepared_for_cte
(license_number
, calId
,vehicle_id
,[group_id]
,[group_name]
, [Date And Time]
, [GPS LAT]
, [GPS LON]
, [Speed(Kph)]
, [Mileage(Km)]
, [NF TK_AmbTemp (40 ft)]
, [NF XPAND BATT_Sys_Energy_System]
, [VAN_DCDC_IIN_ST (SPN 65495)]
, [VAN_DCDC_VIN_ST (SPN 65492)]
, [NF XE_DICO_PWR_AX_MOT 1 (Auxiliary Motor Power Draw)]
, [NF XPAND_SYS_SOC (PGN: 65349)]
, [NF XE_DICO_BR_RWES_FB (Auxiliary Heater Power Draw)]
, [NF CM0711_Electric_Heater_Energy_Consumption_kWh]
, [NF CM0711_Trip_Motor_Energy_Consumption_kWh]
, [NF CM0711_Trip_Regen_Energy_kWh])
SELECT [license_number]
	,s.calId
	,ve.vehicle_id
	,ve.group_id
	,ve.group_name
    ,[Date And Time]
    ,s.[GPS LAT]
    ,s.[GPS LON]
    ,s.[Speed(Kph)]
    ,s.[Mileage(Km)]
    ,s.[NF TK_AmbTemp (40 ft)]
    ,s.[NF XPAND BATT_Sys_Energy_System]
    ,s.[VAN_DCDC_IIN_ST (SPN 65495)]
    ,s.[VAN_DCDC_VIN_ST (SPN 65492)]
    ,s.[NF XE_DICO_PWR_AX_MOT 1 (Auxiliary Motor Power Draw)]
    ,s.[NF XPAND_SYS_SOC (PGN: 65349)]
    ,s.[NF XE_DICO_BR_RWES_FB (Auxiliary Heater Power Draw)]
	,s.[NF CM0711_Electric_Heater_Energy_Consumption_kWh]
	,s.[NF CM0711_Trip_Motor_Energy_Consumption_kWh]
	,s.[NF CM0711_Trip_Regen_Energy_kWh]
	FROM (
		SELECT pvt.license_number
			 , pvt.calId
			 , pvt.[Date And Time]
			 , MAX(pvt.[280]) [GPS LAT]
			 , MAX(pvt.[281]) [GPS LON]
			 --, max(pvt.[49839]) [NF CM0711_Trip_Regen_Energy_kWh]
			 --, max(pvt.[39941]) [NF CHRG_SYS_FAIL_IND (T7-23)]
			 --, max(pvt.[30275]) [BMU_SOC_MSG_CM (PGN: 65439)]
			 , MAX(pvt.[10003]) [Speed(Kph)]
			 , MAX(pvt.[10004]) [Mileage(Km)]
			 , MAX(pvt.[13073]) [NF TK_AmbTemp (40 ft)]
			 --, MAX(pvt.[13068]  [NF TK_HVACMainSwitchStatus]
			 , MAX(pvt.[31463]) [VAN_DCDC_IIN_ST (SPN 65495)]
			 , MAX(pvt.[31464]) [VAN_DCDC_VIN_ST (SPN 65492)]
			 , MAX(pvt.[31465]) [NF XE_DICO_PWR_AX_MOT 1 (Auxiliary Motor Power Draw)]
			 --, max(pvt.[50093]) [NF CM0711 Average Consumption Rate TripkWh-mi]
			 --, max(pvt.[49823]) [NF CM0711_Electric_Heater_Energy_Consumption_kWh]
			 --, max(pvt.[49824]) [NF CM0711_XE_XALT_Charging_Energy_Transfer_kWh]
			 , MAX(pvt.[39223]) [NF XPAND BATT_Sys_Energy_System]
			 , MAX(pvt.[40340]) [NF XPAND_SYS_SOC (PGN: 65349)]
			 , MAX(pvt.[50105]) [NF XE_DICO_BR_RWES_FB (Auxiliary Heater Power Draw)]
			 , MAX(pvt.[49823]) [NF CM0711_Electric_Heater_Energy_Consumption_kWh]
			 , MAX(pvt.[49838]) [NF CM0711_Trip_Motor_Energy_Consumption_kWh]
			 , MAX(pvt.[49839]) [NF CM0711_Trip_Regen_Energy_kWh]
			FROM #dayDetail s
PIVOT 
(MAX([last_input_value])
FOR parameter_type IN 
		([10003], [280], [281], [40340], [31463], [31464], [31465], [39223], [10004], [13068], [13073], [50105]
		,[49823], [49838], [49839]
		)
) AS pvt
GROUP BY
	   pvt.license_number,[Date And Time], pvt.calId
) s
LEFT JOIN (SELECT [license_nmbr],[group_id],[group_name],vehicle_id FROM [nf].[new_flyer_vehicle] 
			WHERE vehicle_id IS NOT NULL
			GROUP BY [license_nmbr],[group_id],[group_name],vehicle_id ) ve ON ve.license_nmbr = s.license_number 
WHERE s.license_number IS NOT null
ORDER BY s.[Date And Time]



DROP TABLE #dayControl

SELECT @i = @i + 1

IF @i > @r
BREAK
	ELSE CONTINUE

END



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
