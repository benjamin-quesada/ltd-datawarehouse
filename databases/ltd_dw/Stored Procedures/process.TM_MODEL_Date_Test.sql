SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [process].[TM_MODEL_Date_Test]
--WITH RECOMPILE
AS

/************************************************
CREATED BY  : B Eichberger
CREATED FOR : test tm calendar and reprocess if missing
CREATED DT  : 20221202
UPDATED DT  : 20230530 -- adapt process for better non process handling.


exec process.TM_MODEL_Date_Test
*************************************************

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

	
	DROP TABLE IF EXISTS ##countDates
	CREATE TABLE ##countDates (countDates Date)

		DECLARE @sqlcmd NVARCHAR(MAX) = '
		INSERT ##countDates (countDates)
		SELECT datecount  
		 FROM (
			SELECT TOP(5) CAST("[DW CALENDAR].[Calendar_Date].[Calendar_Date].[MEMBER_CAPTION]" AS VARCHAR(32)) dateCount
			FROM openquery([TM_ANALYSIS], '' SELECT NON EMPTY { [Measures].[Count Days] } ON COLUMNS, 
			NON EMPTY { ([DW CALENDAR].[Calendar_Date].[Calendar_Date].ALLMEMBERS ) } DIMENSION PROPERTIES MEMBER_CAPTION
			, MEMBER_UNIQUE_NAME ON ROWS FROM ( SELECT ( { [DW CALENDAR].[Last 30 Days].&[True] } ) ON COLUMNS FROM [Model]) WHERE ( [DW CALENDAR].[Last 30 Days].&[True] )'')
			) y 
		'
	--PRINT @sqlcmd
	EXEC sp_executesql @sqlcmd;
	
	IF (SELECT MAX(countDates) FROM ##countDates) < CAST(GETDATE()-1 AS date)
	BEGIN
	  -- tabular is not processed
		EXEC msdb.dbo.sp_start_job @job_name = N'Tabular Maintenance - Scripted - Reprocess Bad Date TM Model'

		declare @subj varchar(120) = 'Error: TM Model Calendar'
		declare @msgj varchar(max) = 'An attempt to refresh the calendar data for TM Model will be started now.

		A message will be sent when the process is complete.

		For further assistance please forward this notice to support@ltd.org'

		EXEC msdb.dbo.sp_send_dbmail
			@profile_name = 'SQLData',
			@recipients = 'barb.eichberger@ltd.org;',--;jeramy.card@ltd.org
			@subject = @subj,
			@body = @msgj ;


	--EXEC msdb.dbo.sp_start_job @job_name = N'Tabular Maintenance - Scripted - Reprocess Bad Date TM Model'

	DROP TABLE IF EXISTS ##countDates


	END

END TRY
BEGIN CATCH

--EXEC msdb.dbo.sp_start_job @job_name = N'Tabular Maintenance - Scripted - Backup and Reprocess TM Model'


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
                                 @recipients = 'barb.eichberger@ltd.org;',
                                 @subject = @sub,
                                 @body = @errormsg;

    RAISERROR(@errormsg, @errsev, 1);
END CATCH

GO
