SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [abb].[Get_ABB_kWh_Fuel_Tickets]
AS
/*
-- from original [abb].Get_ABB_kWh_Fuel_Tickets_TimeAdjusted
-- called by integration services packages in Fleet/NewFlyer kWh Fuel Ticket Files
-- added xref for mac address changes from matt imlach
-- dump data to new table for comparixson
-- truncate table abb.[Fuel_Ticket_Integration_TimeAdjusted_w_xref]
exec [abb].[Get_ABB_kWh_Fuel_Tickets] 

------------------LTD_GLOSSARY---------------
UPDATED BY:	Sopheap Suy
UPDATED DT:  10/31/2024
purpose	 :  Add object activities on who, what, when call this object
			write this data to aud.object_activity table everytime it's called */


BEGIN TRY

SET NOCOUNT ON

DECLARE @SPROC VARCHAR(100)
SET @SPROC = OBJECT_SCHEMA_NAME(@@PROCID) + '.' + OBJECT_NAME(@@PROCID)

INSERT INTO DBA.[aud].[Object_Activity]
	([server_name], [database_name] ,[host_name], [System_User], [object_name]
	,[client_net_address], [local_net_address], [auth_Scheme], [last_read], [last_write]
	,[most_recent_sql_handle], [Timestamp], object_type)
SELECT DISTINCT @@SERVERNAME, DB_NAME(),HOST_NAME(),SYSTEM_USER, @SPROC,
	client_net_address, local_net_address , auth_Scheme, last_read, last_write 
	,most_recent_sql_handle, CURRENT_TIMESTAMP AS [Timestamp], 'PROC'
FROM sys.dm_exec_connections 
WHERE session_id = @@SPID ;


declare @stdtInt int = (select min(sdt) from (
				(select ISNULL(MAX(dbo.F_DATE_TO_CALENDAR_ID(chgtday)),120210501) sdt
				FROM [abb].[Fuel_Ticket_Integration_TimeAdjusted_w_xref]
				)) o )

declare @startdt date = (SELECT [dbo].[F_CALENDAR_ID_TO_DATE](@stdtInt))
--SELECT @startdt
--SELECT @stdtInt

--	UPDATE [process].[MergeLogs]
--	SET [MergeEndDatetime] = sysdatetime()
--	WHERE mergecode = 'NFEAM'
--		AND [ObjectDestination] ='ltd_dw.abb.Fuel_Ticket_Integration_TimeAdjusted_w_xref'
--		AND [ObjectSource] = 'ABB'
--		AND [ObjectProgram] = 'ltd_dw.abb.Get_ABB_kWh_Fuel_Tickets_TimeAdjusted_with_xref'
--		AND [MergeEndDatetime] IS NULL
--		AND recInsert = 0
--		AND recUpdate = 0
--		AND recDelete = 0
--;

SELECT license_number,mileageDt,MAX(last_meter_reading) mileage
INTO #getmileage 
FROM 
(

SELECT rowsrc = 'eam',
	RTRIM(LTRIM(m.eq_equip_no))+' 'AS license_number,
	dbo.F_DATE_TO_CALENDAR_ID(cast(last_meter_date AS datetime))-100000000 mileageDt,
	MAX(r.last_meter_reading) last_meter_reading
	FROM [ltd-eam].proto.emsdba.EQ_MAIN m 
	JOIN [LTD-EAM].proto.[emsdba].[EQ_MAIN_ADDL] a ON a.EQ_equip_no = m.EQ_equip_no 
			AND (a.electric_asset = 'Y' )
	JOIN [ltd-eam].proto.emsdba.EQ_METER_READ r ON m.EQ_equip_no = r.EQ_equip_no
	AND CAST(CONVERT(VARCHAR(32),cast(last_meter_date AS datetime),112) AS INT) >= (@stdtInt-100000000)
	GROUP BY RTRIM(LTRIM(m.eq_equip_no))+' ' ,
	dbo.F_DATE_TO_CALENDAR_ID(cast(last_meter_date AS datetime))
	
	UNION 

--SELECT 'nf',[license_number]+ ' '
--	,dbo.F_DATE_TO_CALENDAR_ID(CAST(locationtime_local AS DATETIME))-100000000
--	,MAX([mileage]) 
--	-- select top(100) *
--	FROM [ltd_electric_bus].[dbo].[newflyer_trip_locations] WITH (NOLOCK) 
--	WHERE 1=1
--	AND dbo.F_DATE_TO_CALENDAR_ID(CAST(locationtime_local AS DATETIME)) >= @stdtInt
--	GROUP BY [license_number]+ ' '
--	,dbo.F_DATE_TO_CALENDAR_ID(CAST(locationtime_local AS DATETIME))-100000000
	
--	UNION 

SELECT 'pa',license_number+ ' '
	,dbo.F_DATE_TO_CALENDAR_ID(CAST(last_input_time_local AS DATETIME))-100000000
	,MAX(last_input_value)  
	FROM [ltd_electric_bus].dbo.[newflyer_parameters] WITH (NOLOCK) 
	WHERE 1=1
	AND parameter_type = 10004
	AND dbo.F_DATE_TO_CALENDAR_ID(CAST(last_input_time_local AS DATETIME)) >= @stdtInt
	GROUP BY license_number+ ' '
	,dbo.F_DATE_TO_CALENDAR_ID(CAST(last_input_time_local AS DATETIME))-100000000
	
	) g
GROUP BY license_number,mileageDt
-- select * from #getmileage


SELECT 
'A' AS RecordTypeFuelXtn,
CAST(CONVERT(VARCHAR(32),CAST(ISNULL(SessionStopTimeLocal,getdate()+1) AS DATETIME),112)  AS VARCHAR(32)) chgtday,
CAST(CONVERT(VARCHAR(32),CAST(ISNULL(SessionStopTimeLocal,getdate()+1) AS DATETIME),112) AS INT)  chgtdayInt,
[Charge Session ID],
RIGHT('00'+CONVERT(VARCHAR(32),DATEPART(HOUR,MAX(CAST(ISNULL(SessionStopTimeLocal,getdate()+1) AS DATETIME)))),2) + RIGHT('00'+CONVERT(VARCHAR(32),DATEPART(MINUTE,MAX(CAST(ISNULL(SessionStopTimeLocal,getdate()+1) AS DATETIME)))),2) chgtime,
LEFT(RTRIM(LTRIM(ISNULL(license_number,'99999')))+' ',6) license_number,
'ABB     ' userId,
RIGHT('00'+CAST([Connector Number] AS VARCHAR(2)),2) AS PumpId ,
RIGHT([Charger Serial #],3) SiteId,
'KWH ' FuelType,
RIGHT('000000'+REPLACE(CAST(SUM(ISNULL(quantity,0)) AS DECIMAL(6,2)),'.',''),6) quantity,
'00000000' meter2,
CAST(SUM(ISNULL(quantity,0)) AS DECIMAL(6,2)) quantity_deformatted,
'  ' ENDSPACE 
INTO -- select * from 
#fuelTicketData
 FROM
 (
SELECT o.[Charger Serial #],
       SUM(o.[Energy Delivered (kWh)]) quantity,
	   m.[BUS NO] AS license_number,
       o.[Charger ID],
       o.[Connector Number],
       t.SessionStartTimeLocal,
       t.SessionStopTimeLocal,
       o.Duration,
	   o.[Charge Session ID],
       MIN(o.[Battery State Of Charge At Session Start]) sessionStartCharge,
       MAX(o.[Battery State Of Charge At Session Stop]) sessionStopCharge
       -- select * 
	   FROM abb.[stage_ChargingData_OperatorPro_LocalTime] t
	   JOIN abb.[stage_ChargingData_OperatorPro] o ON t.[Charge Session ID] = o.[Charge Session ID]
	   JOIN abb.Fuel_Ticket_Mac_Xref m ON m.[MAC ID] = REPLACE(o.[ID Tag],'VID:','')
group BY 
       o.[Charger Serial #],[BUS NO] ,
	   REPLACE(o.[ID Tag],'VID:',''),
       o.[Charger ID],
       o.[Connector Number],
       t.SessionStartTimeLocal,
       t.SessionStopTimeLocal,
       o.Duration,
	   o.[Charge Session ID],
       o.[Payment Reference]
	   ) t  
 GROUP BY 
CAST(CONVERT(VARCHAR(32),CAST(ISNULL(SessionStopTimeLocal,getdate()+1) AS DATETIME),112) AS VARCHAR(32)) ,
CAST(CONVERT(VARCHAR(32),CAST(ISNULL(SessionStopTimeLocal,getdate()+1) AS DATETIME),112) AS INT)  ,
LEFT(RTRIM(LTRIM(ISNULL(license_number,'99999')))+' ',6),
RIGHT('00'+CAST([Connector Number] AS VARCHAR(2)),2) ,
RIGHT([Charger Serial #],3) ,[Charge Session ID]
-- select * from #fuelTicketData


DECLARE @OutputTbl TABLE (actionname varchar(11));

INSERT abb.[Fuel_Ticket_Integration_TimeAdjusted_w_xref] (
	   [Fuel_String]
      ,[recordTypeFuelXtn]
      ,[chgtday]
      ,[chgtime]
      ,[license_number]
      ,[userId]
      ,[siteId]
      ,[pumpID]
      ,[FuelType]
	  ,[charge_session_id]
      ,[quantity]
      ,[meter1]
	  ,quantity_deformatted)
OUTPUT 'INSERTED' INTO @OutputTbl
SELECT 
     [Fuel_String]
      ,[recordTypeFuelXtn]
      ,[chgtday]
      ,[chgtime]
      ,ISNULL([license_number],'99999') [license_number]
      ,[userId]
      ,[siteId] 
      ,[pumpID] 
      ,[FuelType]
	  ,[Charge Session ID]
      ,ISNULL([quantity],'000000') [quantity]
      ,ISNULL([meter1] ,'00000000') [meter1]
	  ,ISNULL([quantity_deformatted],0.00) [quantity_deformatted]
	  FROM (
 SELECT Fuel_String = ISNULL(i.RecordTypeFuelXtn ,'A')
					  + i.chgtday
					  + i.chgtime
					  + ISNULL(i.license_number,'99999') COLLATE SQL_Latin1_General_CP850_CI_AS 
					  + i.userId COLLATE SQL_Latin1_General_CP850_CI_AS 
					  + i.SiteId
					  + i.PumpID
					  + i.FuelType
					  + ISNULL(i.quantity,'000000')
					  + RIGHT('00000000'+ REPLACE(CAST(MAX(CAST(ROUND(ISNULL(m.mileage,'00000000'),1) AS DECIMAL(9,1))) AS VARCHAR(32)),'.',''),8)
					  + ISNULL(i.meter2,'0000000')
					  + i.ENDSPACE 
	  , i.recordTypeFuelXtn 
      , i.chgtday
      , i.chgtime
      , ISNULL(i.license_number,'99999') license_number
	  , i.userId
      , i.siteId
      , i.pumpID
      , i.FuelType
	  , i.[Charge Session ID]
      , i.quantity
      , RIGHT('00000000'+ REPLACE(CAST(MAX(CAST(ROUND(ISNULL(m.mileage,0),1) AS DECIMAL(9,1))) AS VARCHAR(32)),'.',''),8) meter1
	  , i.quantity_deformatted
	  , i.meter2 -- select * 
FROM #fuelTicketData i 
LEFT JOIN #getmileage m on m.license_number = i.[license_number] AND m.mileagedt = (SELECT MAX(mileageDt) FROM #getmileage WHERE license_number = i.[license_number] AND mileageDt <= i.chgtdayInt )
--ORDER BY i.chgtday desc
/*
 "Error in abb.Get_ABB_kWh_Fuel_Tickets: 515|Cannot insert the value NULL into column 'record_created_date', table 'ltd_dw.abb.Fuel_Ticket_Integration_TimeAdjusted_w_xref'; column does not allow nulls. INSERT fails.|0|16". Possible failure reasons: Problems with the query, "ResultSet" property not set correctly, parameters not set correctly, or connection not established correctly.
 */
GROUP BY 
i.RecordTypeFuelXtn
, i.chgtday
, i.chgtime
, i.license_number
, i.userId
, i.SiteId
, i.PumpID
, i.FuelType
, i.[Charge Session ID]
, i.quantity
, i.meter2
, i.ENDSPACE
, i.quantity_deformatted
) f
WHERE NOT EXISTS (SELECT 1 FROM abb.Fuel_Ticket_Integration_TimeAdjusted_w_xref x 
					WHERE x.[charge_session_id] = f.[Charge Session ID]  )
--ORDER BY f.chgtday desc

DECLARE @instd INT

SELECT @instd = (
	SELECT count(*)
	FROM @OutputTbl WHERE actionname = 'INSERTED'
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
		'NFEAM'
		,'ltd_dw.abb.Fuel_Ticket_Integration_TimeAdjusted_w_xref'
		,'ABB'
		,'ltd_dw.abb.Get_ABB_kWh_Fuel_Tickets_TimeAdjusted_with_xref'
		,ISNULL(@instd, 0)
		,0
		,0
		,@startdt
		,SYSDATETIME()
		)
		

END TRY

BEGIN CATCH

       DECLARE @profile VARCHAR(255) = (
                    SELECT TOP (1) NAME
                    FROM msdb.dbo.sysmail_profile
					ORDER BY Name DESC
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
END CATCH


GO
