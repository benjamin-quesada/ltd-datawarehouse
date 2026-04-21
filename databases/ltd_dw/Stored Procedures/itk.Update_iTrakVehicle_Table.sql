SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [itk].[Update_iTrakVehicle_Table]
as


/*
CREATED:   20210406
AUTHOR :   B EICHBERGER
PURPOSE:   To keep ltd vehicle table up to date in iTRAK.
CHANGEDON: 
 CHANGEBY: 
   CHANGE: 

EXEC EXAMPLE: exec itk.Update_iTrakVehicle_Table

------------------LTD_GLOSSARY---------------
UPDATED BY:	Sopheap Suy
UPDATED DT:  10/31/2024
purpose	 :  Add object activities on who, what, when call this object
			write this data to aud.object_activity table everytime it's called
			
			Job that used this is no longer operational because buses were 
			being entered with placeholder VIN numbers

			*/

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

BEGIN TRY

/****************************************

CHANGED ON	: 20250807
CHANGED BY	: B EIchberger
PURPOSE		: 39434 EAM Classifications, Bus Dept Rework
			  Changed Dept_dept_code from 'BUSES' to 'REV'

*/

declare @workstartdt datetime = sysdatetime()

update ltd_dw.[process].[MergeLogs]
SET [recInsert] = 0
,recDelete = 0
,recUpdate = 0 
,MergeEndDatetime = @workstartdt
where [MergeBeginDatetime] is not null 
and MergeEndDatetime is null 
and MergeCode = 'VEH'
and [ObjectSource] = 'ITRAK'
and [ObjectProgram] = 'itk.Update_iTrakVehicle_Table'
and [ObjectDestination] = '[ltd-itrak].ixdata.dbo.ltd_iTrak_vehicles_table'

SELECT eqm.EQ_equip_no
	,series = case when class_class_maint <> [ltd_bus_class] then class_class_maint +' '+ [ltd_bus_class] else class_class_maint end
	,[year]
	,manufacturer
	,model
	,dbo.removeNonASCII(
			replace(replace(replace(
			case when [description] like '%seating%' then substring([description],1, patindex('% SEATING CAPACITY%',[description]))
			else [description] end,'`','-FT'),'H-','H'),'FT.','FT')
				) [description]
	,[type] = DEPT_dept_code
	,license_no
	,VIN = serial_no
into #bussource -- select *  
FROM [LTD-EAM].proto.emsdba.eq_main eqm
LEFT JOIN [LTD-EAM].ltd_db.dbo.bus_classes b ON b.eq_equip_no = eqm.eq_equip_no
WHERE DEPT_dept_code = 'REV'
	AND b.[ltd_bus_class] <> 'unknown'
	
declare @i INT = (
SELECT count(*)
FROM #bussource eqm
WHERE NOT EXISTS (
		SELECT VIN
		FROM [ltd-itrak].ixdata.dbo.ltd_iTrak_vehicles_table
		WHERE eqm.VIN = VIN collate SQL_Latin1_General_CP1_CI_AS
		))

/*
-- MERGE		
--INSERT [iXData].[dbo].[Vehicle] (license, VIN, Make, Model, VehicleType, [Year], Note, datecreated, createdBy,OwnerDepartmentGUID)
select license_no,vin,manufacturer, model,year, description,series,getdate(),'SSIS_DBA',cast('CDC1D84B-A0B8-44A2-817D-30A407ADDE03' as uniqueidentifier)
from ltd_iTrak_vehicles v where not exists ( select vin FROM [iXData].[dbo].[Vehicle] 
					where vin = v.vin collate SQL_Latin1_General_CP850_CI_AS
	and ownerdepartmentguid = 'CDC1D84B-A0B8-44A2-817D-30A407ADDE03')
*/


INSERT [ltd-itrak].ixdata.dbo.ltd_iTrak_vehicles_table (
	[vehicle_number]
	,[series]
	,[year]
	,[manufacturer]
	,[model]
	,[description]
	,[type]
	,[license_no]
	,[VIN]
	)
SELECT eqm.EQ_equip_no
	,series 
	,[year]
	,manufacturer
	,model
	,[description]
	,[type] 
	,license_no
	,VIN 
FROM #bussource eqm
WHERE NOT EXISTS (
		SELECT VIN
		FROM [ltd-itrak].ixdata.dbo.ltd_iTrak_vehicles_table
		WHERE eqm.VIN = VIN collate SQL_Latin1_General_CP1_CI_AS
		)


declare @u int = (
select count(*)  
FROM #bussource b 
join [ltd-itrak].ixdata.dbo.ltd_iTrak_vehicles_table u on u.VIN collate SQL_Latin1_General_CP1_CI_AS = b.VIN collate SQL_Latin1_General_CP1_CI_AS
and isnull(b.license_no collate SQL_Latin1_General_CP1_CI_AS,'') <> isnull(u.license_no collate SQL_Latin1_General_CP1_CI_AS,''))


update u
SET u.license_no = b.license_no
FROM #bussource b 
join [ltd-itrak].ixdata.dbo.ltd_iTrak_vehicles_table u on u.VIN collate SQL_Latin1_General_CP1_CI_AS = b.VIN collate SQL_Latin1_General_CP1_CI_AS
and isnull(b.license_no collate SQL_Latin1_General_CP1_CI_AS,'') <> isnull(u.license_no collate SQL_Latin1_General_CP1_CI_AS,'')


		
insert ltd_dw.[process].[MergeLogs] (
	   [MergeCode]
      ,[ObjectDestination]
      ,[ObjectSource]
      ,[ObjectProgram]
      ,[recInsert]
      ,[recUpdate]
      ,[recDelete]
      ,[MergeBeginDatetime])
	  Values(
	  'VEH', '[ltd-itrak].ixdata.dbo.ltd_iTrak_vehicles_table','ITRAK','itk.Update_iTrakVehicle_Table',isnull(@i,0), isnull(@u,0), 0, @workstartdt)


		
END TRY	  

BEGIN CATCH

       DECLARE @profile VARCHAR(255) = (
                    SELECT NAME
                    FROM msdb.dbo.sysmail_profile
                    )
       DECLARE @errormsg VARCHAR(max)
             ,@error INT
             ,@message VARCHAR(max)
             ,@xstate INT
             ,@errsev INT
             ,@sub VARCHAR(255);

       SELECT @error = ERROR_NUMBER()
             ,@errsev = ERROR_SEVERITY()
             ,@message = ERROR_MESSAGE()
             ,@xstate = XACT_STATE();

       SELECT @errormsg = 'Error in ' + isnull(@SPROC, '') + ': ' + cast(isnull(@error, '') AS NVARCHAR(32)) + '|' + coalesce(@message, '') + '|' + cast(isnull(@xstate, '') AS NVARCHAR(32)) + '|' +cast(isnull(@errsev, '') AS NVARCHAR(32))

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
