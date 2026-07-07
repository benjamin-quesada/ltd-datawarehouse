SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE view [eam].[qasset_status]
as
select [EquipmentID] collate SQL_Latin1_General_CP1_CI_AS                 [EquipmentID]
,q.DepartmentID
     , [EquipmentStatus] collate SQL_Latin1_General_CP1_CI_AS             [EquipmentStatus]
     , q.[LifeCycleStatusCodeID] collate SQL_Latin1_General_CP1_CI_AS     [LifeCycleStatusCodeID]
     , c.[Description] collate SQL_Latin1_General_CP1_CI_AS               LifecycleStatusDescription
     , c.StatusCategory collate SQL_Latin1_General_CP1_CI_AS              StatusCategory
     , c.CategoryDescription collate SQL_Latin1_General_CP1_CI_AS         CategoryDescription
     , c.DenotesThatUnitIsActive collate SQL_Latin1_General_CP1_CI_AS     DenotesThatUnitIsActive
     , [UnitAvailableForRepairOrPM] collate SQL_Latin1_General_CP1_CI_AS  [UnitAvailableForRepairOrPM]
     , [MotorPoolDispatchStatus] collate SQL_Latin1_General_CP1_CI_AS     [MotorPoolDispatchStatus]
     , [DailyDepreciation]
     , [DepreciationMethod] collate SQL_Latin1_General_CP1_CI_AS          [DepreciationMethod]
     , [LifeMonths]
     , [MonthsRemaining]
     , [ExcludeFromExceptionReports] collate SQL_Latin1_General_CP1_CI_AS [ExcludeFromExceptionReports]
     , [ExcludeFromInventoryLists] collate SQL_Latin1_General_CP1_CI_AS   [ExcludeFromInventoryLists]
     , [ExcludeFromReplAnalysis] collate SQL_Latin1_General_CP1_CI_AS     [ExcludeFromReplAnalysis]
     , [LastPerformedService] collate SQL_Latin1_General_CP1_CI_AS        [LastPerformedService]
     , [NextPMDueDate]
     , [ElectricAsset] collate SQL_Latin1_General_CP1_CI_AS               [ElectricAsset]
     , [PlannedDeliveryDate]
     , [ActualDeliveryDate]
     , [PlannedInServiceDate]
     , [ActualInServiceDate]
     , [OriginalCost]
     , [CapitalizedValue]
     , [DateCapitalized]
     , [LicenseNumber] collate SQL_Latin1_General_CP1_CI_AS               [LicenseNumber]
-- select * 
from [LTD-EAM].[ltd_db].[dbo].[LTD_QAsset]                q
    left join [LTD-EAM].[proto].emsdba.QLifeCycleStatus c
        on c.LifeCycleStatusCodeID = q.LifeCycleStatusCodeID
--where q.DepartmentID = 'BUSES';
----go


GO
