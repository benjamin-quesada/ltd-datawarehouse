SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [tm].[view_store_adh_exception]

AS
/*
------------------LTD_GLOSSARY---------------
UPDATED BY:	Sopheap Suy
UPDATED DT:  07/07/2025
purpose	 :  Add object activities on who, what, when call this object
			write this data to aud.object_activity table everytime it's called 
			
			look for missing data gap in tm.view_store_pass table 

			exec tm.view_store_adh_exception

			*/

			
SET NOCOUNT ON

DECLARE @SPROC VARCHAR(100)
SET @SPROC = OBJECT_SCHEMA_NAME(@@PROCID) + '.' + OBJECT_NAME(@@PROCID)

INSERT INTO dba.[aud].[Object_Activity]
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
into ##viewstoreadhx
FROM (
	SELECT   --0 cnt,
	DATEPART(YEAR, c.CALENDAR_DATE) AS [year]
		,DATEPART(MONTH, c.CALENDAR_DATE) AS [month]
		, DATEPART(DAY, c.CALENDAR_DATE) AS [day]
	FROM  tm.DW_CALENDAR c
	WHERE c.CALENDAR_ID >= 120190101 AND c.CALENDAR_DATE < CAST(GETDATE() AS DATE)
	--WHERE c.CALENDAR_ID BETWEEN 120070101 AND  120190101
	GROUP BY DATEPART(YEAR, c.CALENDAR_DATE) 
		,DATEPART(MONTH, c.CALENDAR_DATE)
		, DATEPART(DAY, c.CALENDAR_DATE)
	) d
EXCEPT 
	(
	SELECT -- COUNT(*) AS cnt,
	 DATEPART(YEAR, c.CALENDAR_DATE) AS y
	, DATEPART(MONTH, c.CALENDAR_DATE) AS m
	,  DATEPART(DAY, c.CALENDAR_DATE) AS d
	FROM [tm].[VIEW_STORE_ADH] vsp
	--FROM [tm].[VIEW_STORE_PASS_archive] vsp
	INNER JOIN tm.DW_CALENDAR c
		ON c.CALENDAR_ID = vsp.calendar_id
	GROUP BY DATEPART(YEAR, c.CALENDAR_DATE) 
		,DATEPART(MONTH, c.CALENDAR_DATE)
		, DATEPART(DAY, c.CALENDAR_DATE)
	) 


IF (SELECT COUNT(*) FROM ##viewstoreadhx) > 0
BEGIN
DECLARE @profile VARCHAR(255) = (
                    SELECT top 1 NAME
                    FROM msdb.dbo.sysmail_profile
                    )
  EXEC msdb.dbo.sp_send_dbmail @profile_name = @profile
             ,@recipients = 'barb.eichberger@ltd.org;Sopheap.suy@ltd.org' 
             ,@subject = 'review: Possible missing data for VIEW_STORE_ADH count: Attachment'
			 ,@query = 'select * from ##viewstoreadhx ORDER BY 1,2,3'
			 ,@attach_query_result_as_file = 1
             ,@body = 'review: Possible missing data for VIEW_STORE_ADH count. Attachment(1)


'
END

IF (SELECT COUNT(*) FROM tempdb.sys.tables WHERE name LIKE '%viewstoreadhx%') > 0
BEGIN
	DROP TABLE ##viewstoreadhx
END


END TRY	  

BEGIN CATCH

       DECLARE @profile2 VARCHAR(255) = (
                    SELECT TOP 1 NAME
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

       EXEC msdb.dbo.sp_send_dbmail @profile_name = @profile2
             ,@recipients = 'data@ltd.org' 
             ,@subject = @sub
             ,@body = @errormsg;

       RAISERROR (
                    @errormsg
                    ,@errsev
                    ,1
                    )
END CATCH
GO
