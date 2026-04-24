SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [model].[dw_time]
as

/*
CREATED ON	: 20210226
CREATED BY	: B EICHBERGER
PURPOSE		: Collect set of seconds past midnight

exec model.dw_time

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

DROP TABLE IF EXISTS #dwTimes
SELECT DISTINCT spm INTO #dwTimes FROM ltd_dw.tm.DW_CALENDAR_SPM27 WHERE CALENDAR_ID = 120220901
TRUNCATE TABLE model.time_table

INSERT model.time_table (
 [Hour]
,[Minute]
,[Second]
,[MESSAGE_TIME]
,[HMSFMT]
,[HMFMTSMALL]
,[HMS]
,[HHMMSS]
,[H]
,[M]
,[S]
,[MU]
,[MU_FMT]
,[HHMM_TE]
,[HHMM_TE_FMT]
)
SELECT  [Hour] = x.H
,[Minute] = x.M
,[Second] = x.S
,x.MESSAGE_TIME, x.HMSFMT, x.HMFMTSMALL, x.HMS, x.HHMMSS
,H = RIGHT('00' + CAST( x.H AS VARCHAR(4)),2)
,M = RIGHT('00' + CAST( x.M AS VARCHAR(4)),2)
,S = RIGHT('00' + CAST( x.M AS VARCHAR(4)),2)
,x.MU
,MU_FMT = RIGHT('00' + CAST( x.MU AS VARCHAR(4)),2)
,HHMM_TE
,HHMM_TE_FMT = RIGHT('00' + CAST( x.H AS VARCHAR(4)),2) + ':'+ RIGHT('00' + CAST( x.MU AS VARCHAR(4)),2)
FROM (
SELECT i.MESSAGE_TIME, i.HMSFMT, i.HMFMTSMALL, i.HMS
,HHMMSS = REPLACE(i.HHMMSSS,'.000','') , i.H, i.M, i.MU
,[S] = CAST(RIGHT(i.HMS,2) AS SMALLINT)
,HHMM_TE = LEFT(i.HHMMSSS,2) + RIGHT('00' + CAST(i.MU AS varchar(8)),2)
 FROM (
	SELECT o.MESSAGE_TIME,
	 HMSFMT = CASE WHEN o.MESSAGE_TIME = 86400 THEN '24:00:00'
			ELSE [tm].[F_SEC_SINCE_MIDNITE_TO_HMSFMT](o.MESSAGE_TIME) END
	,HMFMTSMALL = CASE WHEN o.MESSAGE_TIME = 86400 THEN '24:00'
			ELSE LEFT([tm].[F_SEC_SINCE_MIDNITE_TO_HMSFMT](o.MESSAGE_TIME),5) END
	,HMS =  CASE WHEN o.MESSAGE_TIME = 86400 THEN '240000'
			ELSE [tm].[F_SEC_SINCE_MIDNITE_TO_HMS](o.MESSAGE_TIME,1) END   
	,HHMMSSS = CASE WHEN o.MESSAGE_TIME = 86400 THEN '24:00:00.000'
			ELSE [dbo].[ConvertTimeToHHMMSS](o.MESSAGE_TIME,'second') END
	,[H] = CASE WHEN o.MESSAGE_TIME = 86400 THEN 24
			ELSE CAST(LEFT([tm].[F_SEC_SINCE_MIDNITE_TO_HMS](o.MESSAGE_TIME,1), 2) AS SMALLINT) END 
	,[M] = CASE WHEN o.MESSAGE_TIME = 86400 THEN 24
			ELSE CAST(SUBSTRING([tm].[F_SEC_SINCE_MIDNITE_TO_HMS](o.MESSAGE_TIME,1),3, 2) AS SMALLINT) END
	,MU = CASE WHEN o.MESSAGE_TIME = 86400 THEN 24
			ELSE CAST(SUBSTRING([tm].[F_SEC_SINCE_MIDNITE_TO_HMS](o.MESSAGE_TIME,1),3, 2) AS SMALLINT) + 1 END
	FROM (	  
		SELECT spm as message_time FROM #dwTimes
	) o
  ) i 
) x
ORDER BY x.MESSAGE_TIME;

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
