SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [rpt].[eam_ftk_combining_abb] 
as

select k.ftk_date, 100000000 + cast(convert(varchar(32),ftk_date,112) as INT) tktDate_id,
case when k.fuel_type = 'KwH' then qty_fuel * 0.029931063 end as kwh_gallon_equiv,
case when k.fuel_type = 'KwH' then qty_fuel * 0.029931063 else qty_fuel end as all_fuel_gallon,
k.EQ_equip_no
,k.qty_fuel,value_fuel, k.qty_fluid, k.fuel_type, f.[description] 
from [LTD-EAM].proto.emsdba.FTK_MAIN k 
JOIN [LTD-EAM].proto.emsdba.FUE_TYPES f on f.fuel_type = k. fuel_type
WHERE k.fuel_type in ('KWH','ULS','UNL') and k.reversal <> 'y' 
UNION
SELECT sessiondt
      , sessionIntDt
	  , energydelivered * 0.029931063 as kwh_gallon_equiv 
      , energydelivered * 0.029931063 as all_gallon_equiv 
	  , eq_equip_no
	  , energydelivered, NULL, NULL, 'KWH'
	  ,'KILOWATT HOUR'
	  FROM [nf].[new_flyer_ftk_join_events]
GO
