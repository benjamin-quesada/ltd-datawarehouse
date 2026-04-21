SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [itk].[merge_vehicle_accidents]
AS
/*-----------LTD_GLOSSARY---------------
created by	:  b. eichberger
created dt	:  2024-02-23
purpose	:  merge DW itk].vehicle_accidents from ltd-itrak.ixData through DW view
use		:  exec itk.merge_vehicle_accidents

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
DECLARE @sdt DATETIME2 = SYSDATETIME()
DECLARE @outputTbl TABLE (actionNm VARCHAR(32));


MERGE ltd_dw.[itk].[vehicle_accidents] AS t
USING ltd_dw.[itk].[vehicle_accidents_v] AS s
ON (t.[FileNumber] = s.[FileNumber]
AND t.[CreatedBy] = s.[CreatedBy]
AND t.[Occured] = s.[Occured]
AND ISNULL(t.[EmployeeNumber],0) = ISNULL(s.[EmployeeNumber],0)
AND t.[specific] = s.[specific]
AND t.[category] = s.[category]
AND t.[Type] = s.[Type]
AND t.[BusNumber] = s.[BusNumber]
AND t.[RouteNumber] = s.[RouteNumber]
AND t.[Street] = s.[Street]
AND t.[CrossStreet] = s.[CrossStreet]
AND t.[BodilyInjury] = s.[BodilyInjury]
AND t.[SelectionText] = s.[SelectionText]
)
WHEN MATCHED AND ISNULL(t.Preventable,'') <> ISNULL(s.Preventable,'')
THEN UPDATE SET 
	 t.Preventable = s.Preventable
	,t.record_updated_date = SYSDATETIME()
WHEN NOT MATCHED BY TARGET THEN INSERT (
 FileNumber
,CreatedBy
,Occured
,EmployeeNumber
,specific
,category
,BusNumber
,RouteNumber
,Street
,CrossStreet
,BodilyInjury
,PropertyDamage
,Preventable
,SelectionText
,[Type]
)
VALUES
(s.FileNumber, s.CreatedBy, s.Occured, s.EmployeeNumber, s.specific, s.category, s.BusNumber, s.RouteNumber, s.Street, s.CrossStreet, s.BodilyInjury, s.PropertyDamage, s.Preventable, s.SelectionText, s.[Type])
WHEN NOT MATCHED BY SOURCE THEN DELETE
OUTPUT $action INTO @outputTbl;



DECLARE @ins INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'INSERT')
DECLARE @upd INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'UPDATE')
DECLARE @del INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'DELETE')
DECLARE @prg varchar(90) = @@SERVERNAME + '.ltd_dw.itk.merge_vehicle_accidents'

insert process.mergeLogs
(		[MergeCode]
           ,[ObjectDestination]
           ,[ObjectSource]
           ,[ObjectProgram]
           ,[recInsert]
           ,[recUpdate]
           ,[recDelete]
           ,[MergeBeginDatetime]
           ,[MergeEndDatetime])
select 'ITKV',
'ltd_dw.itk.vehicle_accidents',
'ITRAK',
@prg,
isnull(@ins,0) ,ISNULL(@upd,0),ISNULL(@del,0),
@sdt,
sysdatetime()



END TRY	  

BEGIN CATCH

       DECLARE @profile VARCHAR(255) = (
                    SELECT [NAME]
                    FROM msdb.dbo.sysmail_profile
                    )
       DECLARE @errormsg VARCHAR(MAX)
             ,@error INT
             ,@message VARCHAR(MAX)
             ,@xstate INT
             ,@errsev INT
             ,@sub VARCHAR(255);

       SELECT @error = ERROR_NUMBER()
             ,@errsev = ERROR_SEVERITY()
             ,@message = ERROR_MESSAGE()
             ,@xstate = XACT_STATE();

       SELECT @errormsg = 'Error in ' + ISNULL(@SPROC, '') + ': ' + CAST(ISNULL(@error, '') AS NVARCHAR(32)) + '|' + COALESCE(@message, '') + '|' + CAST(ISNULL(@xstate, '') AS NVARCHAR(32)) + '|' +CAST(ISNULL(@errsev, '') AS NVARCHAR(32))

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
