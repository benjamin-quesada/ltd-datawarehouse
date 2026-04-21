SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [tm].[model_source_ons_by_tripid_3_yrs]

AS


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

DECLARE @startDate NVARCHAR(32) = (SELECT LEFT(MIN(calendar_id),5)+'0101' FROM tm.DW_CALENDAR 
									WHERE CALENDAR_DATE >= DATEADD(DAY,1,EOMONTH(DATEADD(YEAR,-3,GETDATE()))))
DECLARE @sqlcmd NVARCHAR(MAX) = ''
SELECT @sqlcmd = @sqlcmd + '
SELECT 
CAST(CAST("[DW CALENDAR].[Calendar_ID].[Calendar_ID].[MEMBER_CAPTION]" AS VARCHAR(32)) AS INT) AS CALENDAR_ID
,CAST(CAST("[TRIP].[TRIP_ID].[TRIP_ID].[MEMBER_CAPTION]" AS VARCHAR(32)) AS BIGINT) as TRIP_ID
,CAST("[TRIP].[TRIP END TIME].[TRIP END TIME].[MEMBER_CAPTION]" as varchar(32)) as TRIP_END_TIME
,cast("[Measures].[Total Passenger Board]" as INT) as [Total Passenger Board]
FROM OPENQUERY([TM_ANALYSIS],
''SELECT NON EMPTY { [Measures].[Total Passenger Board] } ON COLUMNS
, NON EMPTY { ([DW CALENDAR].[Calendar_ID].[Calendar_ID].&['+ @startDate+']:NULL 
* [TRIP].[TRIP_ID].[TRIP_ID].ALLMEMBERS 
* [TRIP].[TRIP END TIME].[TRIP END TIME].ALLMEMBERS ) } DIMENSION PROPERTIES MEMBER_CAPTION ON ROWS 
FROM [Model]'') p
'

EXEC sp_executesql @sqlcmd
	
	
	
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
             ,@recipients = 'barb.eichberger@ltd.org'--;servicedesk@ltd.org' 
             ,@subject = @sub
             ,@body = @errormsg;

       RAISERROR (
                    @errormsg
                    ,@errsev
                    ,1
                    )
END CATCH
GO
GRANT EXECUTE ON  [tm].[model_source_ons_by_tripid_3_yrs] TO [public]
GO
