SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE   PROCEDURE [sbp].[get_passenger_count_by_mode]
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



SELECT * 
INTO ##tempPassenger
FROM OPENQUERY([ltd-tmdata],
 'SELECT calendar_id,
  CASE WHEN route_abbr LIKE ''10[0-9]'' THEN ''EmX'' ELSE ''Fixed Route'' END Mode, SUM(board) board
  FROM tmdatamart.dbo.passenger_count p
  JOIN tmdatamart.dbo.[route] r ON r.route_id = p.route_id
  WHERE p.CALENDAR_ID > 120120101 
  AND (ISNULL( board,0) <> 0 )
  GROUP BY calendar_id, CASE WHEN route_abbr LIKE ''10[0-9]'' THEN ''EmX'' ELSE ''Fixed Route'' End')


  
INSERT -- truncate table 
sbp.passenger_count_by_mode
([calendar_id]
,[Mode]
,[board])
 SELECT * FROM ##tempPassenger p
 WHERE NOT EXISTS (SELECT 1 FROM sbp.passenger_count_by_mode m
		WHERE p.CALENDAR_ID = m.calendar_id
		AND m.mode = p.mode)

DROP TABLE ##tempPassenger

END TRY	  

BEGIN CATCH

       DECLARE @profile VARCHAR(255) = 'SQLData'
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
             ,@recipients = 'servicedesk@ltd.org'
             ,@subject = @sub
             ,@body = @errormsg;

       RAISERROR (
                    @errormsg
                    ,@errsev
                    ,1
                    )
END CATCH
GO
