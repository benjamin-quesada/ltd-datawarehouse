SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE   view [model].[Vehicle_and_Equipment_v]
as

/*----------LTD_GLOSSARY--------------
Standardized Equipment List 

CREATED ON	: 20241122
CREATED BY	: B. Eichberger
PURPOSE		: TO BE USED IN MODELS and all other queries as the standard
			  31924 Replace TM Miles data source in EAM Model

CHANGED ON	: 20241122
CHANGED BY	: B. Eichberger
PURPOSE		: RID 39434 EAM Classifications, Bus Dept Rework
			  for Dept_dept_code changes

			  
CHANGED ON	: 20250807
CHANGED BY	: B. Eichberger
PURPOSE		: RID 39434 EAM Classifications, Bus Dept Rework
			  for Dept_dept_code changes

--------------------------------------*/

select b.ltd_bus_class,
	o.EQ_equip_no,
	'BUS' eq_group,
    o.[VEHICLE TYPE],
	o.class_text,
    --o.class_text as bus_text_class,
	 case when o.class_text = 'SOLD' then cast((cast(b.eq_equip_no as int)/100)*100 as varchar(32)) else o.class_text end bus_text_class,
    o.[VEHICLE YEAR],
    o.UnitAgeDays,
    o.[VEHICLE MANUFACTURER],
    o.[VEHICLE MODEL],
    [VEHICLE DESC] = replace(replace(o.[VEHICLE DESC],'`','-FT'),'ý ','-'),
    isnull(o.artic,0) artic,
    isnull(o.emx_bus,0) emx_bus,
    isnull(o.hybrid,0) hybrid,
    isnull(o.electric,0) electric,
    o.[SHOP STATUS],
    o.[WORK ORDER STATUS],
    o.[FUEL CARD NUMBER],
    o.[FIXED MONTHLY COST],
    o.[OPEN WORK ORDERS],
    o.[MONTHS IN OPERATION],
    o.[DEPRECIATION MONTHS LIFE],
    o.[DEPRECIATION MONTHS REMAINING],
    o.[LAST METER READING],
    o.[LIFE TOTAL MILES],
	o.is_retired_or_sold,
	is_retired_or_sold_count = o.is_retired_or_sold,
    o.original_cost,
	coalesce(s4.DigitsOnly,st.digitsOnly,s2.DigitsOnly,s3.DigitsOnly) as [VEHICLE LENGTH FLEET]
,case when o.artic = 1 then 'Include' else 'Exclude' end as art_text
,case when o.emx_bus = 1 then 'Include' else 'Exclude' end as emx_text
,case when o.hybrid = 1 then 'Include' else 'Exclude' end as hyb_text
,case when o.electric = 1 then 'Include' else 'Exclude' end as ele_text
,case when isnumeric(b.ltd_bus_class) = 1 then cast(b.ltd_bus_class as int) else 99999 end as ltd_class_sort
,t.FLEET_TEXT,
 t.PROPERTY_TAG,
 t.MFG_MODEL_TEXT,
 t.VEHICLE_TYPE_TEXT,
 t.RNET_ADDRESS,
 t.MODEL_YEAR,
 isnull(t.DECOMMISSION,0) DECOMMISSION,
 t.TOTAL_CAPACITY,
 t.FLEET_ID,
 t.SEATING_CAPACITY,
 t.VEHICLE_MFG_TEXT,
 o.license_no,
 sla_status,
 case when b.electric = 1 then 'Electric'
		    when b.atric = 1 and o.hybrid = 0 and o.electric = 0 then 'Articulated Fueled'
		    when b.atric = 1 and o.hybrid = 1 and o.electric = 0 then 'Articulated Hybrid'
		    when b.atric = 1 and o.hybrid = 1 then 'Articulated Hybrid'
	        when b.atric = 0 and o.hybrid = 1 then 'Hybrid'
			when b.atric = 1 and o.hybrid = 0 and o.electric = 0 then 'Articulated'
			when b.atric = 0 and o.hybrid = 1 and o.electric = 0 then 'Hybrid' 
			else 'Fueled' end as bus_kind
,vehicle_id
,o.DEPT_dept_code
from (
select [EQ_equip_no] = e.[EQ_equip_no] collate SQL_Latin1_General_CP1_CI_AS
      ,e.[EQTYP_equip_type] [VEHICLE TYPE]
	  ,e.CLASS_class_maint as class_text
      ,e.[year] as [VEHICLE YEAR]
	  ,datediff(day,e.in_service_date,getdate()) UnitAgeDays
      ,e.[manufacturer] as [VEHICLE MANUFACTURER]
      ,e.[model] as [VEHICLE MODEL], sla_status
          ,replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(e.[description],'2016 ','')
			,'2017 ',''),'2018 ','')
			,'2003 ',''),'2007 ','')
			,'2023 ',''),'2011 ','')
			,'2017 ',''),'2018 ','')
			,'2019 ',''),'2014 ','')
			,'2015 ',''),'2010 ','')
			,'2021 ',''),'2020 ','')
			,'2022 ',''),'2024','')
			,'2024 ',''),'2025',''),'2026','') as [VEHICLE DESC]
	  ,[artic]          = case when e.CLASS_class_meter in('770','1000','6100','7100','9100','1400','15100','19100','20100')            then 1 else 0 end 
      ,[emx_bus]        = case when e.CLASS_class_meter in('6100','9100','15100','20100','24100')                                               then 1 else 0 end
      ,[hybrid]         = case when e.CLASS_class_meter in('1000', '1100','6100','7100','9100','1400','15100','16200', '19200','20100') then 1 else 0 end 
      ,[electric]       = case when a.electric_asset = 'Y' then 1 else 0 end   
	  ,nonElectric		= case when a.electric_asset <> 'Y' then 1 else 0 end 
      ,e.[shop_status] as [SHOP STATUS]
	  ,is_retired_or_sold = case when retire_date is not null or sale_date is not null 
								or CLASS_class_meter = 'SOLD' 
								or DEPT_dept_code = 'SOLD'
								then 1 else 0 end
      ,e.[work_order_status] as [WORK ORDER STATUS]
      ,e.[fuel_card_no] as [FUEL CARD NUMBER]
      ,e.[fixed_monthly_cost] [FIXED MONTHLY COST]
      ,e.[qty_open_work_orders] [OPEN WORK ORDERS]
      ,e.[months_in_operation] [MONTHS IN OPERATION]
      ,e.[deprec_months_life] [DEPRECIATION MONTHS LIFE]
      ,e.[depr_mths_remaining] [DEPRECIATION MONTHS REMAINING]
      ,e.[last_meter_1_reading] [LAST METER READING]
      ,e.[life_total_meter_1] [LIFE TOTAL MILES]
	  ,e.[original_cost]
	  ,e.license_no, e.DEPT_dept_code
  from -- select * from
  [LTD-EAM].proto.[emsdba].[EQ_MAIN] e with (nolock)
  left join [LTD-EAM].proto.[emsdba].[EQ_MAIN_ADDL] a on a.EQ_equip_no = e.EQ_equip_no
   where [DEPT_dept_code] = 'REV' and [EQTYP_equip_type] <> 'Engine' and e.CLASS_class_meter <> 'FLEET' 
  --and isnumeric(e.EQ_equip_no) = 1 
	) o
  left join (select v.FLEET_TEXT,v.PROPERTY_TAG,v.MFG_MODEL_TEXT, vehicle_id
  ,v.VEHICLE_TYPE_TEXT,v.RNET_ADDRESS,v.MODEL_YEAR,v.DECOMMISSION
  ,v.TOTAL_CAPACITY,v.FLEET_ID,v.SEATING_CAPACITY,v.VEHICLE_MFG_TEXT
  from [LTD-TMDATA].TMDATAMART.[dbo].[VEHICLE] v
where v.VEHICLE_TYPE_TEXT = 'Revenue Vehicles'
) t on t.PROPERTY_TAG = o.[EQ_equip_no] 
  inner join [LTD-EAM].ltd_db.dbo.bus_classes b on b.[eq_equip_no] = o.[EQ_equip_no] and b.ltd_bus_class <> 'unknown'
  cross apply dbo.DigitsOnlyEE(substring(o.[VEHICLE DESC], charindex('`',o.[VEHICLE DESC])-2,charindex('`',o.[VEHICLE DESC]))) st
  cross apply dbo.DigitsOnlyEE(substring(o.[VEHICLE DESC], charindex('-',o.[VEHICLE TYPE])-2,charindex('-',o.[VEHICLE TYPE]))) s2  
  cross apply dbo.DigitsOnlyEE(substring(o.[VEHICLE DESC], charindex('`',o.[VEHICLE TYPE])-2,charindex('`',o.[VEHICLE TYPE]))) s3
  cross apply dbo.DigitsOnlyEE(left(o.[VEHICLE DESC],3)) s4
where t.vehicle_id <> 299
union

select o.EQ_equip_no,
	o.EQ_equip_no,
	case when class_text = 'CUTAWAY' then 'CUTAWAY' else 'OTHER' end eq_group,
    o.[VEHICLE TYPE],
	o.class_text,
    o.class_text as bus_text_class,
    o.[VEHICLE YEAR],
    o.UnitAgeDays,
    o.[VEHICLE MANUFACTURER],
    o.[VEHICLE MODEL],
    [VEHICLE DESC] = replace(replace(o.[VEHICLE DESC],'`','-FT'),'ý ','-'),
    0 artic,
    0 emx_bus,
    0 hybrid,
    0 electric,
    o.[SHOP STATUS],
    o.[WORK ORDER STATUS],
    o.[FUEL CARD NUMBER],
    o.[FIXED MONTHLY COST],
    o.[OPEN WORK ORDERS],
    o.[MONTHS IN OPERATION],
    o.[DEPRECIATION MONTHS LIFE],
    o.[DEPRECIATION MONTHS REMAINING],
    o.[LAST METER READING],
    o.[LIFE TOTAL MILES],
	o.is_retired_or_sold,
	is_retired_or_sold_count = o.is_retired_or_sold,
    o.original_cost,
	null 
,null  art_text
,null  emx_text
,null  hyb_text
,null  ele_text
,null as ltd_class_sort
,null,
 null,
 null,
 null,
 null,
 null,
 null,
 null,
 null,
 null,
 null,
 null,
 sla_status,
 null bus_kind
,null vehicle_id
,dept_dept_code
from (
select [EQ_equip_no] = e.[EQ_equip_no] collate SQL_Latin1_General_CP1_CI_AS
      ,e.[EQTYP_equip_type] [VEHICLE TYPE]
	  ,e.CLASS_class_maint as class_text
      ,e.[year] as [VEHICLE YEAR]
	  ,datediff(day,e.in_service_date,getdate()) UnitAgeDays
      ,e.[manufacturer] as [VEHICLE MANUFACTURER]
      ,e.[model] as [VEHICLE MODEL], sla_status
          ,replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(e.[description],'2016 ','')
			,'2017 ',''),'2018 ','')
			,'2003 ',''),'2007 ','')
			,'2023 ',''),'2011 ','')
			,'2017 ',''),'2018 ','')
			,'2019 ',''),'2014 ','')
			,'2015 ',''),'2010 ','')
			,'2021 ',''),'2020 ','')
			,'2022 ',''),'2024','')
			,'2025 ','') as [VEHICLE DESC]
	  --,[artic]          = CASE WHEN e.CLASS_class_meter IN('770','1000','6100','7100','9100','1400','15100','19100','20100')            THEN 1 ELSE 0 END 
   --   ,[emx_bus]        = CASE WHEN e.CLASS_class_meter IN('6100','9100','15100','20100','24100')                                               THEN 1 ELSE 0 END
   --   ,[hybrid]         = CASE WHEN e.CLASS_class_meter IN('1000', '1100','6100','7100','9100','1400','15100','16200', '19200','20100') THEN 1 ELSE 0 END 
   --   ,[electric]       = CASE WHEN a.electric_asset = 'Y' THEN 1 ELSE 0 END   
	  --,nonElectric		= CASE WHEN a.electric_asset <> 'Y' THEN 1 ELSE 0 END 
      ,e.[shop_status] as [SHOP STATUS]
	  ,is_retired_or_sold = case when retire_date is not null or sale_date is not null 
								or CLASS_class_meter = 'SOLD' 
								or DEPT_dept_code = 'SOLD'
								then 1 else 0 end
      ,e.[work_order_status] as [WORK ORDER STATUS]
      ,e.[fuel_card_no] as [FUEL CARD NUMBER]
      ,e.[fixed_monthly_cost] [FIXED MONTHLY COST]
      ,e.[qty_open_work_orders] [OPEN WORK ORDERS]
      ,e.[months_in_operation] [MONTHS IN OPERATION]
      ,e.[deprec_months_life] [DEPRECIATION MONTHS LIFE]
      ,e.[depr_mths_remaining] [DEPRECIATION MONTHS REMAINING]
      ,e.[last_meter_1_reading] [LAST METER READING]
      ,e.[life_total_meter_1] [LIFE TOTAL MILES]
	  ,e.[original_cost]
	  ,e.license_no,dept_dept_code
  from -- select * from
  [LTD-EAM].proto.[emsdba].[EQ_MAIN] e with (nolock)
 	where [DEPT_dept_code] <> 'REV' --AND [EQTYP_equip_type] <> 'Engine' AND e.CLASS_class_meter <> 'FLEET' 
		  and e.EQTYP_equip_type not in ( '1994 GILLIG LF', '2017 BYD', '2003 NF LF-60', '2003 GILLIG LF-40', '1998 GILLIG LF-40', '1991 GILLIG HF', 'AUCTION', '1991 GILLIG HF-35`', 'BUS' )

	) o
--  LEFT JOIN (SELECT v.FLEET_TEXT,v.PROPERTY_TAG,v.MFG_MODEL_TEXT, vehicle_id
--  ,v.VEHICLE_TYPE_TEXT,v.RNET_ADDRESS,v.MODEL_YEAR,v.DECOMMISSION
--  ,v.TOTAL_CAPACITY,v.FLEET_ID,v.SEATING_CAPACITY,v.VEHICLE_MFG_TEXT
--  FROM [LTD-TMDATA].TMDATAMART.[dbo].[VEHICLE] v
----WHERE v.VEHICLE_TYPE_TEXT <> 'Revenue Vehicles'
--) t ON t.PROPERTY_TAG = o.[EQ_equip_no] 
 --WHERE t.vehicle_id <> 299


GO
