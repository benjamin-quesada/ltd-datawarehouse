SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE   PROCEDURE [dbo].[miles_and_road_calls]
AS
/* ------------------LTD_GLOSSARY---------------
UPDATED BY:	Sopheap Suy
UPDATED DT:  10/31/2024
purpose	 :  Add object activities on who, what, when call this object
			write this data to aud.object_activity table everytime it's called */

BEGIN
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

select [veh_class]           = bc.ltd_bus_class
      ,[class_numeric]       = case when isnumeric(bc.ltd_bus_class) = 1 then cast(bc.ltd_bus_class as int) else 9999 end
      ,[artic_class]         = case bc.atric when 1 then 'Y' else 'N' end + '-' + right('0' + bc.ltd_bus_class, 4)
      ,[veh]                 = eq.eq_equip_no
      ,[artic]               = case bc.atric when 1 then 'Y' else 'N' end
      ,[artic_veh]           = case bc.atric when 1 then 'Y' else 'N' end + '-' + right('0' + eq.eq_equip_no, 4)
      ,[the_year]            = cd.cost_year
      ,[the_month]           = cd.cost_month
      ,[sort_month]          = cast(cast(cost_month as char(2)) + '/01/' + cast(cost_year as char(4)) as datetime)
      ,[month_name]			 = datename(month, cast(cost_month as char(2)) + '/01/' + cast(cost_year as char(4)))
      ,[year_month]          = cast(cd.cost_year as char(4)) + '/' + right('0' + cast(cd.cost_month as varchar(2)), 2)
      ,[work_order_seq]      = count(work_order_no) over (partition by eq.eq_equip_no, cast(cd.cost_year as char(4)) + '/' + right('0' + cast(cd.cost_month as varchar(2)), 2) )
      ,[month_miles_adjusted]= floor(cd.meter_1_usage / dbo.iszero(count(work_order_no) over (partition by eq.eq_equip_no, cast(cd.cost_year as char(4)) + '/' + right('0' + cast(cd.cost_month as varchar(2)), 2) ), 1))
      ,[month_miles_meter_2] = cd.meter_2_usage 
      ,[road_call]           = case when rcs.work_order_no is not null and rcs.rc_category = 'mech' then 1 else 0 end
      ,rcs.[work_order_yr]       
      ,rcs.[work_order_no]        
      ,rcs.[wo_yr_no]            
      ,rcs.[eq_equip_no]          
      ,rcs.[ltd_bus_class]       
      ,rcs.[atric]               
      ,bc.[emx_bus]		                 
      ,rcs.[active]              
      ,rcs.[datetime_out_service] 
      ,rcs.[meter_1_life_total]   
      ,rcs.[description_lc]       
      ,rcs.[rc_category]         
      ,rcs.[task_code]			  
      ,rcs.[task_description]      
      ,rcs.[hours]			      
      ,rcs.[cost]					 
  from      [LTD-EAM].proto.emsdba.eq_main					eq
 inner join [LTD-EAM].proto.emsdba.eq_cost_data				cd	on cd.eq_equip_no = eq.eq_equip_no
 inner join [LTD-EAM].ltd_db.dbo.bus_classes							bc	on bc.eq_equip_no = eq.eq_equip_no
 left join  [ltd_dw.dbo.[road_call_work_orders]   rcs on rcs.eq_equip_no = eq.eq_equip_no and rcs.work_order_yr = cd.cost_year and rcs.the_month = cd.cost_month
 where 1 = 1
 and bc.ltd_bus_class <> 'unknown' 
 and cd.cost_year > 2016
 and bc.ltd_bus_class not in('260','700','760','')

END

GO
