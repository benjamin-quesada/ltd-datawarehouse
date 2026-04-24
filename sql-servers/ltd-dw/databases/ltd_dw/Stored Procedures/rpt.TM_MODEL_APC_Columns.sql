SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   PROCEDURE [rpt].[TM_MODEL_APC_Columns]
AS

/************************************************
CREATED BY  : B Eichberger
CREATED FOR : get route and other detail for APC Certification Db
CREATED DT  : 29239623

GRANT EXECUTE on [rpt].[TM_MODEL_APC_Columns] to LTD\SQL_DW
GRANT EXECUTE on [rpt].[TM_MODEL_APC_Columns] to rpt_reader

exec [rpt].[TM_MODEL_APC_Columns]
*************************************************/

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

DECLARE @datetest INT = (
SELECT COUNT(CAST(datecount AS DATE)) countDt FROM (
	SELECT TOP(5) CAST("[DW CALENDAR].[Calendar_Date].[Calendar_Date].[MEMBER_CAPTION]" AS VARCHAR(32)) dateCount
	FROM openquery([TM_ANALYSIS], 'SELECT NON EMPTY { [Measures].[Total Passenger Board] } 
	ON COLUMNS, NON EMPTY { ([DW CALENDAR].[Calendar_Date].[Calendar_Date].ALLMEMBERS ) } 
	DIMENSION PROPERTIES MEMBER_CAPTION ON ROWS 
	FROM ( SELECT ( { [DW CALENDAR].[Last 30 Days].&[True] } ) ON COLUMNS 
	FROM [Model]) WHERE ( [DW CALENDAR].[Last 30 Days].&[True] ) CELL PROPERTIES VALUE
	, BACK_COLOR, FORE_COLOR, FORMATTED_VALUE, FORMAT_STRING, FONT_NAME, FONT_SIZE, FONT_FLAGS')
	) y
)
IF ISNULL(@datetest,0) = 0 
BEGIN

declare @subj varchar(120) = 'Error: TM Model Calendar'
declare @msgj varchar(max) = 'An attempt to refresh the calendar data for TM Model will be started now.

A message will be sent when the process is complete.

For further assistance please forward this notice to support@ltd.org'

EXEC msdb.dbo.sp_send_dbmail
    @profile_name = 'SQLData',
    @recipients = 'barb.eichberger@ltd.org',
    @subject = @subj,
	@body = @msgj ;


EXEC msdb.dbo.sp_start_job @job_name = N'MaintenancePlan - Scripted - Reprocess Bad Date TM Model'
END



END TRY
BEGIN CATCH

EXEC msdb.dbo.sp_start_job @job_name = N'MaintenancePlan - Scripted - Reprocess Bad Date TM Model'


    DECLARE @profile VARCHAR(255) = (SELECT [name] FROM msdb.dbo.sysmail_profile);
    DECLARE @errormsg VARCHAR(MAX),
            @error    INT,
            @message  VARCHAR(MAX),
            @xstate   INT,
            @errsev   INT,
            @sub      VARCHAR(255);

    SELECT @error = ERROR_NUMBER(),
           @errsev = ERROR_SEVERITY(),
           @message = ERROR_MESSAGE(),
           @xstate = XACT_STATE();

    SELECT @errormsg
        = 'Error in ' + ISNULL(@SPROC, '') + ': ' + CAST(ISNULL(@error, '') AS NVARCHAR(32)) + '|'
          + COALESCE(@message, '') + '|' + CAST(ISNULL(@xstate, '') AS NVARCHAR(32)) + '|'
          + CAST(ISNULL(@errsev, '') AS NVARCHAR(32));

    SELECT @sub = 'ERROR: ' + @SPROC;

    EXEC msdb.dbo.sp_send_dbmail @profile_name = @profile,
                                 @recipients = 'barb.eichberger@ltd.org',
                                 @subject = @sub,
                                 @body = @errormsg;

    RAISERROR(@errormsg, @errsev, 1);
END CATCH;

GO
