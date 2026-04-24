SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
------------------LTD_GLOSSARY---------------
-- created by:	Sopheap Suy
-- created dt:  10/10/2023
-- purpose	 :  view for Charging Data Operator Pro
-- Source	 :  [ltd_dw].[abb].[stage_ChargingData_OperatorPro]


-- use       :  select * from [abb].[ChargingData_OperatorPro]


CREATE VIEW [abb].[ChargingData_OperatorPro]
AS
SELECT [Charger Serial #]
      ,[Energy Delivered (kWh)]
      ,[EV Charger Name]
	  ,[Charge Session ID]
      ,[Charger ID]
      ,ISNULL([ID Tag],'') [ID Tag]
      ,[Connector Number]
      ,[Start Reason]
      ,[Session Start Time]
      ,[Session Stop Time]
      ,[Duration]
      ,ISNULL([Battery State Of Charge At Session Start],0) [Battery State Of Charge At Session Start]
      ,ISNULL([Battery State Of Charge At Session Stop],0) [Battery State Of Charge At Session Stop]
      ,[Stop Reason]
      ,[Stop Reason Detailed]
      ,ISNULL([Transaction ID],'') [Transaction ID]
      ,[Payment Reference]
  FROM [abb].[stage_ChargingData_OperatorPro]
  GROUP BY 
	  [Charger Serial #]
      ,[Energy Delivered (kWh)]
      ,[EV Charger Name]
	  ,[Charge Session ID]
      ,[Charger ID]
      ,ISNULL([ID Tag],'') 
      ,[Connector Number]
      ,[Start Reason]
      ,[Session Start Time]
      ,[Session Stop Time]
      ,[Duration]
      ,ISNULL([Battery State Of Charge At Session Start],0) 
      ,ISNULL([Battery State Of Charge At Session Stop],0) 
      ,[Stop Reason]
      ,[Stop Reason Detailed]
      ,ISNULL([Transaction ID],'') 
      ,[Payment Reference]
GO
