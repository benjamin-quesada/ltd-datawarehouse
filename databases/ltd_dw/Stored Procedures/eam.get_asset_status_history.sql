SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [eam].[get_asset_status_history]
as

/*

PURPOSE		:	TO MAINTAIN an ongoing record of bus status changes in DW
CREATED BY	:	B. Eichberger
CREATED ON	:	20221019

EXAMPLE		:	exec eam.get_asset_status_history

------------------LTD_GLOSSARY---------------
UPDATED BY:	Sopheap Suy
UPDATED DT:  10/31/2024
purpose	 :  Add object activities on who, what, when call this object
			write this data to aud.object_activity table everytime it's called */

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

insert into [eam].[qasset_status_history]
           ([EquipmentID]
           ,[EquipmentStatus]
           ,[LifeCycleStatusCodeID]
           ,[LifecycleStatusDescription]
           ,[StatusCategory]
           ,[CategoryDescription]
           ,[DenotesThatUnitIsActive]
           ,[UnitAvailableForRepairOrPM]
           ,[MotorPoolDispatchStatus]
           ,[DailyDepreciation]
           ,[DepreciationMethod]
           ,[LifeMonths]
           ,[MonthsRemaining]
           ,[ExcludeFromExceptionReports]
           ,[ExcludeFromInventoryLists]
           ,[ExcludeFromReplAnalysis]
           ,[LastPerformedService]
           ,[NextPMDueDate]
           ,[ElectricAsset]
           ,[PlannedDeliveryDate]
           ,[ActualDeliveryDate]
           ,[PlannedInServiceDate]
           ,[ActualInServiceDate]
           ,[OriginalCost]
           ,[CapitalizedValue]
           ,[DateCapitalized]
           ,[LicenseNumber])
select [EquipmentID]
           ,[EquipmentStatus]
           ,[LifeCycleStatusCodeID]
           ,[LifecycleStatusDescription]
           ,[StatusCategory]
           ,[CategoryDescription]
           ,[DenotesThatUnitIsActive]
           ,[UnitAvailableForRepairOrPM]
           ,[MotorPoolDispatchStatus]
           ,[DailyDepreciation]
           ,[DepreciationMethod]
           ,[LifeMonths]
           ,[MonthsRemaining]
           ,[ExcludeFromExceptionReports]
           ,[ExcludeFromInventoryLists]
           ,[ExcludeFromReplAnalysis]
           ,[LastPerformedService]
           ,[NextPMDueDate]
           ,[ElectricAsset]
           ,[PlannedDeliveryDate]
           ,[ActualDeliveryDate]
           ,[PlannedInServiceDate]
           ,[ActualInServiceDate]
           ,[OriginalCost]
           ,[CapitalizedValue]
           ,[DateCapitalized]
           ,[LicenseNumber]
		   from eam.qasset_status s
where not exists (select 1 from [eam].[qasset_status_history] where [EquipmentID] = s.[EquipmentID] and cast(record_created_date as date) = cast(getdate() as date))



END TRY	  

BEGIN CATCH

       DECLARE @profile VARCHAR(255) = (
                    SELECT [NAME]
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
END catch
GO
