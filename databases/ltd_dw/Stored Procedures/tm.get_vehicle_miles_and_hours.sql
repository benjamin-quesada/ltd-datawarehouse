SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   PROCEDURE [tm].[get_vehicle_miles_and_hours]
AS

/***********************************
CREATED ON	: 20220121
CREATED BY	: B. Eichberger (based on work by L. Storm)
PURPOSE		: A daily running total of all hours and all miles whether 
			  revenue, deadhead or layover. Does not distinguish.

USAGE		: used by EAM_MODEL to help calculate probable
			  miles per gallon so includes all miles.

CHANGED ON	: 20240710
CHANGED BY	: B. Eichberger
CHANGE RSN	: pointing at ltd_dw adh view instead of tm view.

**********************************/


/*------------------LTD_GLOSSARY---------------
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


DECLARE @lastCal INT = (SELECT MAX(calendar_id) FROM [tm].[vehicle_miles_and_hours])

INSERT INTO [tm].[vehicle_miles_and_hours]
           ([calendar_id]
           ,[vehicle_number]
           ,[miles]
           ,[hours])
SELECT calendar_id,
	   the_bus,
	   MAX(odometer)-MIN(odometer) AS miles,
	   --- this could be incorrect at the day granularity if 
	   --- a bus resets odometer more than one time a day
	   --- as a block or at the trip level, because odometers reset
	   SUM(CASE WHEN v.[actual_departure_spm] - v.[actual_arrival_spm] <= 0 THEN 0 ELSE 
				v.[actual_departure_spm] - v.[actual_arrival_spm] end)/3600.0 hours
FROM ltd_dw.tm.VIEW_STORE_ADH_v v
WHERE v.calendar_id >= @lastCal
 AND ISNUMERIC(the_bus) = 1
 AND NOT EXISTS (SELECT 1 FROM [tm].[vehicle_miles_and_hours] WHERE calendar_id = v.calendar_id AND vehicle_number = v.the_bus)
  GROUP BY calendar_id,the_bus 


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
END CATCH

GO
