SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE VIEW [tm].[logged_messages_moving_electric]
AS
SELECT q.CALENDAR_ID
	  ,q.VEHICLE_ID
	  ,q.PROPERTY_TAG
	  ,q.LOCAL_TIMESTAMP
	  ,q.StateOfCharge
	  ,LAG(StateOfCharge,1) OVER (PARTITION BY VEHICLE_ID ORDER BY LOCAL_TIMESTAMP) LastStateofCharge
	  ,CASE WHEN q.StateOfCharge > LAG(StateOfCharge,1) OVER (PARTITION BY VEHICLE_ID ORDER BY LOCAL_TIMESTAMP) 
		THEN  q.StateOfCharge - LAG(StateOfCharge,1) OVER (PARTITION BY VEHICLE_ID ORDER BY LOCAL_TIMESTAMP) 
		ELSE 0 END ChargeRecovery
	  ,q.SecondsToEmpty
	  ,q.MilesToEmpty
	FROM (
	SELECT lm.CALENDAR_ID, v.VEHICLE_ID, v.PROPERTY_TAG, lm.MESSAGE_TIMESTAMP, lm.LOCAL_TIMESTAMP
	, case when lm.ST_MDT_VERSION = 0x3FF then null else lm.ST_MDT_VERSION end/10.0 as StateOfCharge 
	, CASE when lm.LOWER32 = 0x3FFFFF then null else lm.LOWER32 end as SecondsToEmpty
    , case when lm.UPPER32 = 0x3FFFFF then null else lm.UPPER32 end/100.0 as MilesToEmpty
    from [LTD-TMDATA].TMDailyLog.dbo.LOGGED_MESSAGE lm
    inner join [LTD-TMDATA].TMMain.dbo.VEHICLE v
      on lm.SOURCE_HOST = v.RNET_ADDRESS
    where MESSAGE_TYPE_ID = 137 and lm.ST_MDT_VERSION <> 0x3FF AND CAT_2 <> 1 AND lm.CALENDAR_ID >= 120241112
) q


GO
