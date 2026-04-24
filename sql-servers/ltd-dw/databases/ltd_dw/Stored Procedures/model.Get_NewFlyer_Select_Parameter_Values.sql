SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [model].[Get_NewFlyer_Select_Parameter_Values] (
	@startDateDt date, @licCurr INT )
AS

/*
CREATED DT:		20220428
CREATED BY:		B. Eichberger
PURPOSE   :		Build a longitudinal record of nf parameters required for CTE reporting/KPIs
USAGE	  :		exec nf.prepare_data_for_cte 120211012 (parameter presented by loop programming 
				in sql agent job based on dates not yet processed )

				-- exec [model].[Get_NewFlyer_Select_Parameter_Values] '4/1/2021', 20201	
*/


BEGIN TRY
SET NOCOUNT ON

  DECLARE @SPROC VARCHAR(100)
  SET @SPROC = OBJECT_SCHEMA_NAME(@@PROCID) + '.' + OBJECT_NAME(@@PROCID)

  /*
  120210524065189	120210524065400	67484583762020208	67484583762	20208
  */

--DECLARE @startDateDt DATE = '5/24/2021'
--DECLARE @licCurr INT = 20208

DROP TABLE IF EXISTS #hourlistNFP
DROP TABLE IF EXISTS #minutelistNFP
DROP TABLE IF EXISTS #secondlistNFP
DROP TABLE IF EXISTS #dayDetailNFP
DROP TABLE IF EXISTS #dayControlNFP

DECLARE @startdateint INT = CAST(CONVERT(VARCHAR(32),@startDateDt,112) AS BIGINT)+100000000
--DECLARE @endDateInt INT = (SELECT CONVERT(varchar(32),GETDATE()-2,112)+100000000)
DECLARE @min bigint, @max bigint

SELECT @Min=0 ,@Max=59;
;
SELECT TOP (@Max-@Min+1) @Min-1+row_number() over(order by t1.number) as N
INTO -- select * from 
#secondlistNFP
FROM master..spt_values t1 
    CROSS JOIN master..spt_values t2

SELECT @Min=0 ,@Max=59;
;
SELECT TOP (@Max-@Min+1) @Min-1+row_number() over(order by t1.number) as N
INTO #minutelistNFP
FROM master..spt_values t1 
    CROSS JOIN master..spt_values t2

DECLARE @minh bigint, @maxh bigint
SELECT @Minh=0 ,@Maxh=23;
;
SELECT TOP (@Maxh-@Minh+1) @Minh-1+row_number() over(order by t1.number) as N
INTO #hourlistNFP
FROM master..spt_values t1 
    CROSS JOIN master..spt_values t2

SELECT rn = ROW_NUMBER() OVER (ORDER BY	CAST(last_input_time AS DATE)),
license_number,CAST(last_input_time AS DATE) last_input_dt,
CAST(CONVERT(VARCHAR(32),CAST(last_input_time AS DATE),112) AS BIGINT)+100000000 calId
INTO #timeloopNFP 
FROM [ltd_dw].[fact].[new_flyer_parameters_limited] 
	WHERE CAST(CONVERT(VARCHAR(32),CAST(last_input_time AS DATE),112) AS BIGINT)+100000000
			= @startDateInt 
	  AND license_number = @licCurr
GROUP BY license_number,CAST(last_input_time AS DATE) ,
CAST(CONVERT(VARCHAR(32),CAST(last_input_time AS DATE),112) AS BIGINT)+100000000 

if(select count(*) from #timeloopNFP) < 1
BEGIN
insert [nf].[newflyer_zero_parameters_limited] (license_number,calId,fileloaddt)
select @licCurr,@startDateInt,@startDateDt
END

if(select count(*) from #timeloopNFP) >= 1
BEGIN
-- select * from #timeloopNFP order by calid
-- delete from #timeloopNFP where calid > 120210511
DECLARE @i INT = 1
DECLARE @r INT
SELECT @r = (SELECT MAX(rn) FROM #timeloopNFP)

WHILE @i <= @r

BEGIN

DECLARE @calId INT = (SELECT TOP(1) calid FROM #timeloopNFP WHERE rn = @i ORDER BY rn)
DECLARE @currlicense INT = (SELECT TOP(1) license_number FROM #timeloopNFP WHERE rn = @i ORDER BY rn)
DECLARE @currDt DATE = (SELECT TOP(1) last_input_dt FROM #timeloopNFP WHERE rn = @i ORDER BY rn)

DELETE FROM fact.NewFlyer_Parameters_Pivot WHERE calId = @calId AND license_number = @currlicense

DROP TABLE IF EXISTS #dayControlNFP
CREATE table #dayControlNFP (calid INT,spm INT, cal_spm_key BIGINT,[Date And Time Format] VARCHAR(42),[Date And Time] DATETIME2)
INSERT #dayControlNFP 
(calid,
    spm,
    cal_spm_key,
    [Date And Time Format],
    [Date And Time])
SELECT @calId calId, --,h.*, m.*, s.*,
spm =[dbo].[F_DATE_TO_SEC_SINCE_MIDNITE](
	CAST(CAST(@currDt AS VARCHAR(12))+' '+CAST(h.N AS VARCHAR(12)) 
			+':'+ RIGHT( '00'+CAST(m.N AS VARCHAR(12)),2) 
			+':'+ RIGHT( '00'+CAST(s.N AS VARCHAR(12)),2) AS DATETIME)),
cal_spm_key = CAST(@calId AS VARCHAR(32)) 
			+ RIGHT('000000' + CAST([dbo].[F_DATE_TO_SEC_SINCE_MIDNITE](
				CAST(CAST(@currDt AS VARCHAR(12))+' '+CAST(h.N AS VARCHAR(12)) 
				+':'+ RIGHT( '00'+CAST(m.N AS VARCHAR(12)),2) 
				+':'+ RIGHT( '00'+CAST(s.N AS VARCHAR(12)),2) AS DATETIME)) AS VARCHAR(32)),6)
,FORMAT(CAST(CAST(@currDt AS VARCHAR(12))+' '+CAST(h.N AS VARCHAR(12)) 
		+':'+ RIGHT( '00'+CAST(m.N AS VARCHAR(12)),2)
		+':'+ RIGHT( '00'+CAST(s.N AS VARCHAR(12)),2) AS DATETIME)
		,'M/d/yyyy %H:mm:ss') [Date And Time Format]
,CAST(CAST(@currDt AS VARCHAR(12))+' '+CAST(h.N AS VARCHAR(12)) 
		+':'+ RIGHT( '00'+CAST(m.N AS VARCHAR(12)),2) 
		+':'+ RIGHT( '00'+CAST(s.N AS VARCHAR(12)),2) AS DATETIME2) [Date And Time]
FROM #hourlistNFP h
	CROSS JOIN #minuteListNFP m
	CROSS JOIN #secondlistNFP s
	ORDER BY 
CAST(CAST(@currDt AS VARCHAR(12))+' '+CAST(h.N AS VARCHAR(12)) 
		+':'+ RIGHT( '00'+CAST(m.N AS VARCHAR(12)),2) 
		+':'+ RIGHT( '00'+CAST(s.N AS VARCHAR(12)),2) AS DATETIME) 
OPTION (MAXDOP 2)

----SELECT * FROM #dayControlNFP
DROP TABLE IF EXISTS #dayDetailNFP
CREATE TABLE #dayDetailNFP (calid INT, spm INT, cal_spm_key bigint, [Date And Time Format] VARCHAR(42),[Date And Time] DATETIME2,parameter_type INT,license_number INT,last_input_value NUMERIC( 18,8))
INSERT #dayDetailNFP (calid,
    spm,
	cal_spm_key,
    [Date And Time Format],
    [Date And Time],
    parameter_type,
    license_number,
    last_input_value)
SELECT d.calId,
       d.spm,
       d.cal_spm_key,
       d.[Date And Time Format],
       d.[Date And Time]
	, o.parameter_type
	, o.license_number
	, o.last_input_value
	FROM #dayControlNFP d
	LEFT JOIN (
		SELECT t.parameter_type_description
				,t.parameter_type
				,p.license_number
				,CAST(p.last_input_value AS DECIMAL(14,5)) last_input_value
				,FORMAT(CAST(p.last_input_time AS DATETIME),'M/d/yyyy %H:mm:ss') [Date and Time Format] 
				,CAST(FORMAT(CAST(p.last_input_time AS DATETIME),'M/d/yyyy %H:mm:ss') AS DATETIME) [Date and Time] 
			FROM [ltd_dw].[fact].[new_flyer_parameters_limited] p
			JOIN dim.new_flyer_parameter_type t ON t.[parameter_type] = p.[parameter_type]
			WHERE 1=1 
			AND p.license_number = @currlicense 
			AND p.last_input_time = @currDt 
			) o
		ON d.[Date And Time] = o.[Date And Time]
OPTION (MAXDOP 2)

INSERT fact.NewFlyer_Parameters_Pivot(
	 [license_number]
    ,[calId]
	,cal_spm_param 
    ,[Date And Time]
    ,[Speed(Kph)]
    ,[Mileage(Km)]
    ,[Mileage(Miles)]
	,[NF TK_AmbTemp (40 ft)]
    ,[NF TK_HVACMainSwitchStatus]
    ,[VAN_DCDC_IIN_ST (SPN 65495)]
    ,[VAN_DCDC_VIN_ST (SPN 65492)]
    ,[NF XE_DICO_PWR_AX_MOT 1 (Auxiliary Motor Power Draw)]
    ,[NF CM0711 Average Consumption Rate TripkWh-mi]
    ,[NF CM0711_Electric_Heater_Energy_Consumption_kWh]
    ,[NF CM0711_XE_XALT_Charging_Energy_Transfer_kWh]
    ,[NF XPAND BATT_Sys_Energy_System]
    ,[NF XPAND_SYS_SOC (PGN: 65349)]
    ,[NF XE_DICO_BR_RWES_FB (Auxiliary Heater Power Draw)]
    ,[NF CM0711_Trip_Motor_Energy_Consumption_kWh]
    ,[NF CM0711_Trip_Regen_Energy_kWh])
SELECT 
ISNULL(s.[license_number],0) [license_number]
,ISNULL(s.[calId],0) [calId]
,al_spm_param = cast(CAST([dbo].[F_DATE_TO_CALENDAR_ID]([Date And Time]) AS VARCHAR(32))
				+ RIGHT('000000'+ cast([dbo].[F_DATE_TO_SEC_SINCE_MIDNITE]([Date And Time]) as varchar(32)),6) as bigint) 
,s.[Date And Time] [Date And Time]
,ISNULL(s.[Speed(Kph)],0) [Speed(Kph)]
,ISNULL(s.[Mileage(Km)],0) [Mileage(Km)]
,[Mileage(Miles)]=case when isnull([Mileage(Km)],0)= 0 then 0 else [Mileage(Km)]*0.62137119223733 end 
,ISNULL(s.[NF TK_AmbTemp (40 ft)],0) [NF TK_AmbTemp (40 ft)]
,ISNULL(s.[NF TK_HVACMainSwitchStatus],0) [NF TK_HVACMainSwitchStatus]
,ISNULL(s.[VAN_DCDC_IIN_ST (SPN 65495)],0) [VAN_DCDC_IIN_ST (SPN 65495)]
,ISNULL(s.[VAN_DCDC_VIN_ST (SPN 65492)],0) [VAN_DCDC_VIN_ST (SPN 65492)]
,ISNULL(s.[NF XE_DICO_PWR_AX_MOT 1 (Auxiliary Motor Power Draw)],0) [NF XE_DICO_PWR_AX_MOT 1 (Auxiliary Motor Power Draw)]
,ISNULL(s.[NF CM0711 Average Consumption Rate TripkWh-mi],0) [NF CM0711 Average Consumption Rate TripkWh-mi]
,ISNULL(s.[NF CM0711_Electric_Heater_Energy_Consumption_kWh],0) [NF CM0711_Electric_Heater_Energy_Consumption_kWh]
,ISNULL(s.[NF CM0711_XE_XALT_Charging_Energy_Transfer_kWh],0) [NF CM0711_XE_XALT_Charging_Energy_Transfer_kWh]
,ISNULL(s.[NF XPAND BATT_Sys_Energy_System],0) [NF XPAND BATT_Sys_Energy_System]
,ISNULL(s.[NF XPAND_SYS_SOC (PGN: 65349)],0) [NF XPAND_SYS_SOC (PGN: 65349)]
,ISNULL(s.[NF XE_DICO_BR_RWES_FB (Auxiliary Heater Power Draw)],0) [NF XE_DICO_BR_RWES_FB (Auxiliary Heater Power Draw)]
,ISNULL(s.[NF CM0711_Trip_Motor_Energy_Consumption_kWh],0) [NF CM0711_Trip_Motor_Energy_Consumption_kWh]
,ISNULL(s.[NF CM0711_Trip_Regen_Energy_kWh],0) [NF CM0711_Trip_Regen_Energy_kWh]
FROM (
SELECT pvt.license_number
	, pvt.calId
	, pvt.[Date And Time]
	, pvt.cal_spm_key
	, pvt.spm
	, MAX(pvt.[10003]) [Speed(Kph)]
	, MAX(pvt.[10004]) [Mileage(Km)]
	, MAX(pvt.[13073]) [NF TK_AmbTemp (40 ft)]
	, MAX(pvt.[13068]) [NF TK_HVACMainSwitchStatus]
	, MAX(pvt.[31463]) [VAN_DCDC_IIN_ST (SPN 65495)]
	, MAX(pvt.[31464]) [VAN_DCDC_VIN_ST (SPN 65492)]
	, MAX(pvt.[31465]) [NF XE_DICO_PWR_AX_MOT 1 (Auxiliary Motor Power Draw)]
	, max(pvt.[50093]) [NF CM0711 Average Consumption Rate TripkWh-mi]
	, max(pvt.[49823]) [NF CM0711_Electric_Heater_Energy_Consumption_kWh]
	, max(pvt.[49824]) [NF CM0711_XE_XALT_Charging_Energy_Transfer_kWh]
	, MAX(pvt.[39223]) [NF XPAND BATT_Sys_Energy_System]
	, MAX(pvt.[40340]) [NF XPAND_SYS_SOC (PGN: 65349)]
	, MAX(pvt.[50105]) [NF XE_DICO_BR_RWES_FB (Auxiliary Heater Power Draw)]
	, MAX(pvt.[49838]) [NF CM0711_Trip_Motor_Energy_Consumption_kWh]
	, MAX(pvt.[49839]) [NF CM0711_Trip_Regen_Energy_kWh]
  FROM #dayDetailNFP s
PIVOT 
(MAX([last_input_value])
FOR parameter_type IN 
		([10003], [280], [281], [40340], [31463], [31464], [31465]
	   , [39223], [10004], [13068], [13073], [50105], [49823],[49824], [49838], [49839], [50093]
		)
) AS pvt
GROUP BY
	   pvt.license_number
			 , pvt.calId
			 , pvt.[Date And Time]
			 , pvt.cal_spm_key
			 , pvt.spm
) s
LEFT JOIN (SELECT [license_nmbr],[group_id],[group_name],vehicle_id FROM [nf].[new_flyer_vehicle] 
			WHERE vehicle_id IS NOT NULL
			GROUP BY [license_nmbr],[group_id],[group_name],vehicle_id ) ve ON ve.license_nmbr = s.license_number 
WHERE s.license_number IS NOT null
OPTION (MAXDOP 2)


DROP TABLE IF EXISTS #dayDetailNFP
DROP TABLE IF EXISTS #dayControlNFP

SELECT @i = @i + 1

IF @i > @r
BREAK
	ELSE CONTINUE

END

DROP TABLE IF EXISTS #hourlistNFP
DROP TABLE IF EXISTS #minutelistNFP
DROP TABLE IF EXISTS #secondlistNFP
DROP TABLE IF EXISTS #dayDetailNFP
DROP TABLE IF EXISTS #dayControlNFP
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
