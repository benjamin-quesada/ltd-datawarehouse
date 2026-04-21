SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   PROCEDURE [tm].[apc_block_trip_stop_operator]
AS


/*---------------------------------------

CREATED		20230627
AUTHOR		B EICHBERGER
PURPOSE		Prepares data for use by the APC Certification App (MS ACCESS)

-- exec tm.apc_block_trip_stop_operator

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


TRUNCATE TABLE tm.apc_block_trip_stop_detail -- grant select on tm.apc_block_trip_stop_detail to public

DECLARE @ttv TABLE (rn INT IDENTITY(1,1) NOT NULL,ttversion INT NOT NULL)
INSERT @ttv (ttversion)
SELECT TOP(2) TIME_TABLE_VERSION_ID as ttversion
	FROM [LTD-TMDATA].[tmdatamart].[dbo].[TIME_TABLE_VERSION]
	ORDER BY TIME_TABLE_VERSION_ID desc

DECLARE @i INT = 1
DECLARE @r INT = 2
DECLARE @currTTV INT

WHILE @i <= @r
BEGIN

SELECT @currttv = (SELECT ttversion FROM @ttv WHERE rn = @i)
INSERT INTO [tm].[apc_block_trip_stop_detail]
           ([BLOCK_ID]
           ,[TRIP_ID]
           ,[TIME_TABLE_VERSION_ID]
           ,[PATTERN_ID]
           ,[STOP_ABBR]
           ,[STOP_NAME]
           ,[PATTERN_GEO_NODE_SEQ]
           ,[TRIP_PATTERN_SEQ]
           ,[CROSSING_TIME]
           ,[CROSSING_TYPE_TEXT]
           ,[IS_LAYOVER]
           ,[ROUTE_ABBR]
           ,[ROUTE_DIRECTION_ABBR]
           ,[IsRevenue]
           ,[CALENDAR_ID]
           ,[BADGE]
           ,[LAST_NAME]
           ,[BOARD])
SELECT h.BLOCK_ID
	  ,h.TRIP_ID
	  ,h.TIME_TABLE_VERSION_ID
	  ,h.PATTERN_ID
	  ,h.STOP_ABBR
	  ,h.STOP_NAME
	  ,h.PATTERN_GEO_NODE_SEQ
	  ,h.TRIP_PATTERN_SEQ
	  ,tm.[convert_passing_time](CROSSING_TIME) CROSSING_TIME
	  ,h.CROSSING_TYPE_TEXT
	  ,h.IS_LAYOVER
	  ,h.ROUTE_ABBR
	  ,h.ROUTE_DIRECTION_ABBR
	  ,h.IsRevenue
	  ,h.CALENDAR_ID
	  ,h.BADGE
	  ,h.LAST_NAME
	  ,h.BOARD 
	  FROM (
SELECT x.[BLOCK_ID]
      ,x.[TRIP_ID]
      ,x.[TIME_TABLE_VERSION_ID]
      ,x.[PATTERN_ID]
      ,g.GEO_NODE_ABBR STOP_ABBR
	  ,g.GEO_NODE_NAME STOP_NAME
      ,x.[PATTERN_GEO_NODE_SEQ]
      ,x.[TRIP_PATTERN_SEQ]
      ,x.[CROSSING_TIME]
	  ,c.CROSSING_TYPE_TEXT
      ,x.[IS_LAYOVER]
       ,r.[ROUTE_ABBR]
	  ,LEFT(rd.[ROUTE_DIRECTION_ABBR],1) [ROUTE_DIRECTION_ABBR]
      ,x.[IsRevenue]
      ,p.CALENDAR_ID
	  ,o.BADGE
	  ,o.LAST_NAME
	  ,ISNULL(p.BOARD,0) BOARD
  FROM [LTD-TMDATA].[tmmain].[dbo].[TRIP_GEO_NODE_XREF] x WITH (NOLOCK)
  JOIN [LTD-TMDATA].tmdatamart.dbo.GEO_NODE g ON g.GEO_NODE_ID = x.GEO_NODE_ID 
  JOIN [LTD-TMDATA].tmdatamart.dbo.ROUTE r ON r.ROUTE_ID = x.ROUTE_ID
  JOIN [LTD-TMDATA].tmdatamart.dbo.ROUTE_DIRECTION rd ON rd.ROUTE_DIRECTION_ID = x.ROUTE_DIRECTION_ID
  JOIN [LTD-TMDATA].tmdatamart.[dbo].[CROSSING_TYPE] c ON c.CROSSING_TYPE_ID = x.CROSSING_TYPE_ID
  LEFT JOIN [LTD-TMDATA].tmdatamart.dbo.PASSENGER_COUNT p ON p.block_id = x.BLOCK_ID 
		AND p.TIME_TABLE_VERSION_ID = x.TIME_TABLE_VERSION_ID
		AND p.ROUTE_DIRECTION_ID = x.ROUTE_DIRECTION_ID
		AND p.ROUTE_ID = x.ROUTE_ID
		AND p.GEO_NODE_ID = x.GEO_NODE_ID
		AND p.TRIP_ID = x.TRIP_ID
		AND p.PATTERN_ID = x.PATTERN_ID
   LEFT JOIN [LTD-TMDATA].tmdatamart.dbo.OPERATOR o ON o.OPERATOR_ID = p.OPERATOR_ID
  WHERE  x.TIME_TABLE_VERSION_ID = @currTTV AND p.CALENDAR_ID IS NOT NULL
  ) h

SELECT @i = @i + 1

IF @i > @r
BREAK
	ELSE CONTINUE	

END
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
