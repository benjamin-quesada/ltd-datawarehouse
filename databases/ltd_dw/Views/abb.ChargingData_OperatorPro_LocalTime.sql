SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE view [abb].[ChargingData_OperatorPro_LocalTime]
as

select u.[Charger Serial #]
	  ,u.[Charge Session ID]
     , u.license_number
     , u.[Energy Delivered (kWh)]
     , u.[EV Charger Name]
     , u.[Charger ID]
     , u.[ID Tag]
     , u.[Connector Number]
     , u.[Start Reason]
     , u.SessionStartTimeLocal
     , u.SessionStopTimeLocal
     , u.Duration
     , u.[Battery State Of Charge At Session Start]
     , u.[Battery State Of Charge At Session Stop]
     , u.[Stop Reason]
     , u.[Stop Reason Detailed]
     , u.[Transaction ID]
     , u.[Payment Reference] from ( 
select [Charger Serial #]
	  ,p.[Charge Session ID]
	  ,x.[BUS NO] license_number
      ,[Energy Delivered (kWh)]
      ,[EV Charger Name]
      ,[Charger ID]
      ,isnull([ID Tag],'') [ID Tag]
      ,[Connector Number]
      ,[Start Reason]
      ,l.SessionStartTimeLocal
      ,l.SessionStopTimeLocal
      ,[Duration]
      ,isnull([Battery State Of Charge At Session Start],0) [Battery State Of Charge At Session Start]
      ,isnull([Battery State Of Charge At Session Stop],0) [Battery State Of Charge At Session Stop]
      ,[Stop Reason]
      ,[Stop Reason Detailed]
      ,isnull([Transaction ID],'') [Transaction ID]
      ,[Payment Reference]
  from [ltd_dw].[abb].[stage_ChargingData_OperatorPro] p
  inner join abb.stage_ChargingData_OperatorPro_LocalTime l on l.[Charge Session ID] = p.[Charge Session ID]
				  join abb.Fuel_Ticket_Mac_Xref x on x.[MAC ID] = p.[Payment Reference]
				  and cast(l.SessionStopTimeLocal as datetime) between x.[FIRST TRANSACTION] and isnull(x.[LAST TRANSACTION],getdate()+1)
				where  p.[Energy Delivered (kWh)] <> 0 
				--and l.SessionStartTimeLocal between	'7/27/2022' and '8/25/2022'	
  group by 
  [Charger Serial #]
	  ,p.[Charge Session ID]
  ,x.[BUS NO]
      ,[Energy Delivered (kWh)]
      ,[EV Charger Name]
      ,[Charger ID]
      ,isnull([ID Tag],'') 
      ,[Connector Number]
      ,[Start Reason]
      ,l.SessionStartTimeLocal
      ,l.SessionStopTimeLocal
      ,[Duration]
      ,isnull([Battery State Of Charge At Session Start],0) 
      ,isnull([Battery State Of Charge At Session Stop],0) 
      ,[Stop Reason]
      ,[Stop Reason Detailed]
      ,isnull([Transaction ID],'') 
      ,[Payment Reference]
union
all
select [Charger Serial #] collate SQL_Latin1_General_CP850_CI_AS
	  ,p.[Charge Session ID]
      ,d.EQ_equip_no collate SQL_Latin1_General_CP850_CI_AS as license_number 
      ,[Energy Delivered (kWh)] 
      ,[EV Charger Name] collate SQL_Latin1_General_CP850_CI_AS
      ,[Charger ID] collate SQL_Latin1_General_CP850_CI_AS
      ,isnull([ID Tag],'') collate SQL_Latin1_General_CP850_CI_AS [ID Tag]
      ,[Connector Number] 
      ,[Start Reason] collate SQL_Latin1_General_CP850_CI_AS
      ,l.SessionStartTimeLocal
      ,l.SessionStopTimeLocal
      ,[Duration]
      ,isnull([Battery State Of Charge At Session Start],0) [Battery State Of Charge At Session Start]
      ,isnull([Battery State Of Charge At Session Stop],0) [Battery State Of Charge At Session Stop]
      ,[Stop Reason]
      ,[Stop Reason Detailed]
      ,isnull([Transaction ID],'') [Transaction ID]
      ,[Payment Reference]
  from [ltd_dw].[abb].[stage_ChargingData_OperatorPro] p
inner join [ltd-eam].proto.[emsdba].[EQ_SUBSYS_DETAIL] d 
					 on replace(d.text_value,':','') = p.[Payment Reference]  collate SQL_Latin1_General_CP850_CI_AS
					  and d.SUBSYS_subsystem = 'LINUXPL' 
					  and d.SUBPROP_subsys_prop = 'POWER LINE #'
					  and d.EQ_equip_no like '2[0-9][0-9][0-9][0-9]'
					  and d.EQ_equip_no not in (select [BUS NO] collate SQL_Latin1_General_CP850_CI_AS from abb.Fuel_Ticket_Mac_Xref group by [BUS NO])
inner join abb.stage_ChargingData_OperatorPro_LocalTime l on l.[Charge Session ID] = p.[Charge Session ID]
				--and l.SessionStartTimeLocal between	'7/27/2022' and '8/25/2022'	
group by 
  [Charger Serial #]
	  ,p.[Charge Session ID]
  ,d.EQ_equip_no
      ,[Energy Delivered (kWh)]
      ,[EV Charger Name]
      ,[Charger ID]
      ,isnull([ID Tag],'') 
      ,[Connector Number]
      ,[Start Reason]
      ,l.SessionStartTimeLocal
      ,l.SessionStopTimeLocal
      ,[Duration]
      ,isnull([Battery State Of Charge At Session Start],0) 
      ,isnull([Battery State Of Charge At Session Stop],0) 
      ,[Stop Reason]
      ,[Stop Reason Detailed]
      ,isnull([Transaction ID],'') 
      ,[Payment Reference]					
) u
--where SessionStartTimeLocal between '7/27/2022' and '8/25/2022'

group by 
u.[Charger Serial #]
	  ,u.[Charge Session ID]
     , u.license_number
     , u.[Energy Delivered (kWh)]
     , u.[EV Charger Name]
     , u.[Charger ID]
     , u.[ID Tag]
     , u.[Connector Number]
     , u.[Start Reason]
     , u.SessionStartTimeLocal
     , u.SessionStopTimeLocal
     , u.Duration
     , u.[Battery State Of Charge At Session Start]
     , u.[Battery State Of Charge At Session Stop]
     , u.[Stop Reason]
     , u.[Stop Reason Detailed]
     , u.[Transaction ID]
     , u.[Payment Reference]
--order by u.SessionStartTimeLocal desc
GO
