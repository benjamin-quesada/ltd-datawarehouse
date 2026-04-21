SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create view [eam].[fuel_and_mileage_by_cost_yr_mo]

as
/**********************************************

CREATED BY	: B. Eichberger
CREATED ON	: 20251120
PURPOSE		: 31496 Backlog: EAM Fuel Report - get this started at least

*/

select 
c.eq_equip_no
,v.artic, v.emx_bus, v.hybrid, v.electric,[LIFE TOTAL MILES],is_retired_or_sold,[VEHICLE LENGTH FLEET]	, MODEL_YEAR
,c.cost_year
,c.cost_month
,c.meter_1_usage
,c.cng_qty
,c.fuel_qty
,m.class_class_maint
,m.dept_dept_code
,m.life_total_meter_1
,cost_year_month = cast(c.cost_year as varchar(4)) + RIGHT('0' + cast(c.cost_month as varchar(2)), 2)
from [ltd-eam].proto.emsdba.eq_cost_data c
inner join [ltd-eam].proto.emsdba.eq_main m on m.eq_equip_no = c.eq_equip_no
left join model.vehicle_v v on v.PROPERTY_TAG collate SQL_Latin1_General_CP850_CI_AS = c.eq_equip_no
--inner join ltd_db.dbo.bus_classes b on b.eq_equip_no = c.eq_equip_no 
where c.cost_year > 2019 and 
(c.meter_1_usage > 0 or c.fuel_qty > 0) and
 m.CLASS_class_maint <> 'fleet' and
 m.CLASS_class_maint <> 'allfleet' 
GO
