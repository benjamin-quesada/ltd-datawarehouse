SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   PROCEDURE [rpt].[TM_MODEL_APC_CERT_DETAIL]
AS

/************************************************
CREATED BY  : B Eichberger
CREATED FOR : test tm calendar and reprocess if missing
CREATED DT  : 20221202

GRANT EXECUTE ON [rpt].[TM_MODEL_APC_CERT_DETAIL] to "LTD\SQL_DW"
GRANT EXECUTE ON [rpt].[TM_MODEL_APC_CERT_DETAIL] to rpt_reader

exec [rpt].[TM_MODEL_APC_CERT_DETAIL]
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

DECLARE @currYr NVARCHAR(32) = (select YEAR(GETDATE()))
DECLARE	@lastYr NVARCHAR(32) =  (select YEAR(GETDATE())-1)

DECLARE @mdxcmd NVARCHAR(MAX) = ''
select @mdxcmd = @mdxcmd + '
SELECT * FROM openquery([TM_ANALYSIS], ''SELECT { [Measures].[Total Passenger Board] } ON COLUMNS, {
	([VEHICLE].[PROPERTY_TAG].[PROPERTY_TAG].ALLMEMBERS 
	* [VEHICLE].[VEHICLE DESC].[VEHICLE DESC].ALLMEMBERS 
	* [VEHICLE].[EMX BUS].[EMX BUS].ALLMEMBERS 
	* [VEHICLE].[SEATING_CAPACITY].[SEATING_CAPACITY].ALLMEMBERS 
	* [ROUTE DIR STOP and TP].[ROUTE_NAME].[ROUTE_NAME].ALLMEMBERS 
	* [ROUTE DIR STOP and TP].[ROUTE_ABBR].[ROUTE_ABBR].ALLMEMBERS 
	* [ROUTE DIR STOP and TP].[ROUTE_DIR].[ROUTE_DIR].ALLMEMBERS 
	* [ROUTE DIR STOP and TP].[ROUTE_DIRECTION_ABBR].[ROUTE_DIRECTION_ABBR].ALLMEMBERS 
	* [ROUTE DIR STOP and TP].[STOP_NAME].[STOP_NAME].ALLMEMBERS ) } 
	DIMENSION PROPERTIES MEMBER_CAPTION, MEMBER_UNIQUE_NAME ON ROWS 
	FROM ( SELECT ( [DW CALENDAR].[Year].&['+@lastYr+'] : [DW CALENDAR].[Year].&['+@currYr+'] ) 
	ON COLUMNS FROM [Model]) 
	CELL PROPERTIES VALUE, BACK_COLOR, FORE_COLOR, FORMATTED_VALUE, FORMAT_STRING, FONT_NAME, FONT_SIZE, FONT_FLAGS''
	) y '

	PRINT @mdxcmd


END TRY
BEGIN CATCH

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
