SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [nf].[multisource_kWh_fuel_tickets]
@fueldt date
as
/* 
CREATED ON	: 20210816
CREATED BY	: B Eichberger
PURPOSE		: DRAFT - show how/if combining data across the various sources can be successful

exec nf.multisource_kWh_fuel_tickets '6/15/2021'

*/
SET NOCOUNT ON;

declare @lastloaddt datetime = @fueldt -- (select dateadd(hour, -1, max(record_created_date)) from [dbo].[newflyer_charge_tickets])
declare @rangDtStart date = (select dateadd(day,-1,@lastloaddt) )
declare @rangDtEnd date = (select dateadd(day,1,@lastloaddt))

delete from [dbo].[newflyer_charge_tickets] where cast([Session Start Time] as date) = @lastloaddt
;
WITH chg as (

	SELECT d.eq_equip_no 
			,[Charger Serial #]
			,[Connector Number]
			,[EV Charger Name]
			,sum(isnull([Energy Delivered (kWh)],0)) [Energy Delivered (kWh)]
			,min(cast([Session Start Time] as datetime2)) [Session Start Time]
			,max(cast([Session Stop Time] as datetime2)) [Session Stop Time]
			,min([Battery State Of Charge At Session Start]) [Battery SOC At Session Start]
			,max([Battery State Of Charge At Session Stop]) [Battery SOC At Session Stop]
			,[Duration Minutes] =	
					sum(DATEPART(hh,Duration) * 60.0 +
						DATEPART(mi,Duration) +
						(DATEPART(ss,Duration) /60.0))
				  ,[Stop Reason]
				  ,[Stop Reason Detailed]
			  FROM [ltd_dw].[nf].[operator_pro_stage] s WITH (NOLOCK)
			  join [ltd-eam].proto.[emsdba].[EQ_SUBSYS_DETAIL] d WITH (NOLOCK)
			  on s.[Payment Reference] collate SQL_Latin1_General_CP850_CI_AS = replace(d.text_value,':','') 
			   where d.active = 'Y' and isnull([Energy Delivered (kWh)],0) <> 0
			   and cast(s.[Session Start Time] as date) >= @rangDtStart
			   and cast(s.[Session Start Time] as date) <= @rangDtEnd
			 group by 
			 d.eq_equip_no 
				  ,[Charger Serial #]
				  ,[Connector Number]
				  ,[Energy Delivered (kWh)]
				  ,[EV Charger Name]
				  ,[Stop Reason]
				  ,[Stop Reason Detailed]
				 )
	
	
,miles as (
			  SELECT license_number,last_meter_date, MAX(mileage) mileage FROM 
				(SELECT RTRIM(LTRIM(r.eq_equip_no))+' 'AS license_number,
					last_meter_date,
					MAX(r.last_meter_reading) mileage
					FROM [ltd-eam].proto.emsdba.EQ_METER_READ r
					JOIN [ltd-eam].proto.emsdba.EQ_MAIN m ON m.EQ_equip_no = r.EQ_equip_no
					WHERE m.CLASS_class_pm = '20200'
					AND last_meter_date >= @fueldt 
					GROUP BY RTRIM(LTRIM(r.eq_equip_no))+' ' ,
					last_meter_date
	
					UNION

					SELECT [license_nmbr]+ ' '
					,last_event_time
					,MAX([last_mileage]) 
					FROM [ltd_dw].[dbo].[newflyer_vehicledata1] WITH (NOLOCK) 
					WHERE last_event_time >= @fueldt 
					GROUP BY [license_nmbr]+ ' ',last_event_time 
					) m
					WHERE m.mileage IS NOT null
			   GROUP BY license_number,last_meter_date	 
			)
			
,soc as (select license_number,parameter_type,parameter_type_description,cast(last_input_time as datetime) last_input_time,last_input_value
				from ltd_dw.nf.new_flyer_parameters WITH (NOLOCK) 
				where parameter_type  = 40340 
				and cast(last_input_time as datetime) >= @rangDtStart
				and cast(last_input_time as datetime) <= @rangDtEnd
				group by license_number,parameter_type,parameter_type_description,cast(last_input_time as datetime),last_input_value
				)	
,ev as (select license_number,cast(event_time as datetime) event_time,event_type_id
			,event_type_description,end_time , event_category
	from ltd_dw.dbo.newflyer_events WITH (NOLOCK) 
	where event_type_id = 4190310 
			and cast(event_time as datetime) >= @rangDtStart
			and cast(event_time as datetime) <= @rangDtEnd
		GROUP BY license_number,cast(event_time as datetime),event_type_id
			,event_type_description,end_time , event_category
			)

			
insert [dbo].[newflyer_charge_tickets]
(	   [eq_equip_no]
      ,[EV Charger Serial Nbr]
	  ,[Connector Number]
      ,[Energy Delivered (kWh)]
      ,[Session Start Time]
      ,[Session Stop Time]
      ,[Duration Minutes]
      ,[soc_reported_byABB_start]
      ,[soc_reported_byABB_stop]
      ,[soc_reported_byBus_start]
      ,[soc_reported_byBus_stop]
      ,[odo]
      ,[event_type_description]
      ,[event_category]
      ,[min_event_time]
      ,[max_event_time]
      ,[trimmed_event_name])
select r.eq_equip_no
,[Charger Serial #]
,[Connector Number]
,cast([Energy Delivered (kWh)] as decimal(12,3)) [Energy Delivered (kWh)]
,[Session Start Time]
,[Session Stop Time]
,[Duration Minutes]
,cast([Battery SOC At Session Start] as decimal(12,3)) soc_reported_byABB_start
,cast([Battery SOC At Session Stop] as decimal(12,3)) soc_reported_byABB_stop
,min(cast(soc.last_input_value as decimal(12,3))) soc_reported_byBus_start
,max(cast(soc.last_input_value as decimal(12,3))) soc_reported_byBus_stop
,max(last_mileage) odo
,event_type_description
,v.event_category
,min(v.event_time) min_event_time
,max(v.event_time) max_event_time
,substring(v.event_type_description,1, charindex('(',event_type_description)-1) trimmed_event_name
from (
	select e.* ,max(miles.[mileage]) last_mileage
	from chg e
	left join miles
			on miles.license_number = e.eq_equip_no
			and miles.last_meter_date between dateadd(minute,-15,e.[Session Start Time]) and dateadd(minute,+15,e.[Session Stop Time] )
	group by 
	eq_equip_no 
	,[Charger Serial #]
    ,[Connector Number]
	,[Energy Delivered (kWh)]
	,[EV Charger Name]
	,[Session Start Time]
	,[Session Stop Time] 
	,[Duration Minutes]
	,[Battery SOC At Session Start]
	,[Battery SOC At Session Stop]
	,[Stop Reason]
	,[Stop Reason Detailed]
	 ) r
left JOIN ev v WITH (NOLOCK) on v.license_number = r.eq_equip_no
	and v.event_time >= r.[Session Start Time]
	and v.event_time <= r.[Session Stop Time]
left join soc
			on soc.license_number = r.eq_equip_no
				and soc.last_input_time  >= r.[Session Start Time] 
				and soc.last_input_time  <= r.[Session Stop Time]
	where v.event_type_id = 4190310
	--and not exists (select * from [dbo].[newflyer_charge_tickets] t
	--				where t.[EV Charger Name] = r.[EV Charger Name] collate SQL_Latin1_General_CP1_CI_AS
	--					and t.[Session Start Time] = r.[Session Start Time] 
	--					and t.[Session Stop Time] = r.[Session Stop Time] 
	--					and t.eq_equip_no = r.eq_equip_no collate SQL_Latin1_General_CP1_CI_AS )
group by 
 r.eq_equip_no
,[Charger Serial #]
,[Connector Number]
,[Energy Delivered (kWh)]
,[Session Start Time]
,[Session Stop Time]
,[Duration Minutes]
,[Battery SOC At Session Start]
,[Battery SOC At Session Stop]
,event_type_description
,event_category
OPTION (MAXDOP 2)	
	
GO
