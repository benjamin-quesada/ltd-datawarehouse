SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [process].[FA_Service_Request_Alert] 
 
@currentUser VARCHAR(42), @fasrkeynumber INT
AS

/*
=================LTD_GLOSSARY================
CREATED BY : B. Eichberger
CREATED DATE : 20240423
PURPOSE : Process FA Service Request into Alerts
EXEC [process].[FA_Service_Request_Alert] 'LTD\Marcus Hecker',1740145324
 
UPDATED BY: Sopheap Suy
UPDATED DT:  10/31/2024
purpose :  Add object activities on who, what, when call this object
write this data to aud.object_activity table everytime it's called 

UPDATED BY:	Ben Quesada
UPDATED DT:  10/09/2025
purpose	 :  removed old send email & text steps, added parameter prep & storing logic for powershell script.
sql agent job used to run powershell that calls govdelivery api to post bulletin that sends email & text to subscribers.
data@ltd now used for error notifications

=============================================			
*/



 
SET NOCOUNT ON
 
DECLARE @SPROC VARCHAR(100)
SET @SPROC = OBJECT_SCHEMA_NAME(@@PROCID) + '.' + OBJECT_NAME(@@PROCID)
 
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
 
------TEST OPTIONS 
--DECLARE @currentUser VARCHAR(42) = 'LTD\Jason Lundin'
--DECLARE @fasrkeynumber INT = 1739958803
------TEST OPTIONS
 
 
DECLARE @sqlcleanup1 NVARCHAR(MAX) = '
DROP TABLE IF EXISTS process.temp_sendFA'+CAST( @fasrkeynumber AS VARCHAR(60))
EXEC sp_executesql @sqlcleanup1
 
DECLARE @sqlcleanup2 NVARCHAR(MAX) = '
DROP TABLE IF EXISTS process.temp_textOUTPUT'+CAST( @fasrkeynumber AS VARCHAR(60))
EXEC sp_executesql @sqlcleanup2
 
 
DECLARE @sqlcleanup3 NVARCHAR(MAX) = '
DROP TABLE IF EXISTS process.alert_textOUTPUT'+CAST( @fasrkeynumber AS VARCHAR(60))
EXEC sp_executesql @sqlcleanup3
 
 
DECLARE @sqlcmd NVARCHAR(MAX) = '
SELECT FASR_Key [FA SR Number],veh as [Vehicle Number],reason as [Service Required Category],busExchanged [Bus Exchanged With]
,describeService as [Description of the Issue/Situation/Problem],VariableValue as [Sent By]
,convert(varchar(60),VariableValDate,120) [Sent Datetime]
INTO process.temp_sendFA'+CAST( @fasrkeynumber AS VARCHAR(60))+'
FROM process.JobStepDataFAServiceReq WHERE FASR_Key = '+CAST( @fasrkeynumber AS VARCHAR(60)) + ' AND VariableValue = ''' + @currentUser+''''
EXEC sp_executesql @sqlcmd
DECLARE @qry VARCHAR(MAX) = N'select [FA SR Number] as [SR Number],[Vehicle Number],[Service Required Category],[Bus Exchanged With],[Description of the Issue/Situation/Problem],[Sent By],[Sent Datetime] from process.temp_sendFA'+CAST( @fasrkeynumber AS VARCHAR(60))
 
 
DECLARE @html varchar(MAX);
EXEC process.spQueryToHtmlTable @html = @html OUTPUT
, @query = @qry
, @orderBy = N' ORDER BY 1'
, @header = N'Alert: Service Request'
 

 
SELECT @sqlcmd = N'
select 1 ord, ''FASR Nbr: '' + CAST([FA SR Number] as varchar(90)) LTD_Alert
into process.temp_textOUTPUT'+CAST( @fasrkeynumber AS VARCHAR(60))+'
from process.temp_sendFA'+CAST( @fasrkeynumber AS VARCHAR(60))+'
WHERE [FA SR Number] = '+CAST( @fasrkeynumber AS VARCHAR(60)) + ' AND [Sent By] = ''' + @currentUser+'''
UNION
select 2, ''Veh: '' + CAST([Vehicle Number] as varchar(42)) from process.temp_sendFA'+CAST( @fasrkeynumber AS VARCHAR(60))+'
WHERE [FA SR Number] = '+CAST( @fasrkeynumber AS VARCHAR(60)) + ' AND [Sent By] = ''' + @currentUser+'''
UNION
select 3, ''Rsn: '' +CAST([Service Required Category] as varchar(42)) from process.temp_sendFA'+CAST( @fasrkeynumber AS VARCHAR(60))+'
WHERE [FA SR Number] = '+CAST( @fasrkeynumber AS VARCHAR(60)) + ' AND [Sent By] = ''' + @currentUser+'''
UNION
select 4, ''Exch: ''+CAST([Bus Exchanged With] as varchar(42)) from process.temp_sendFA'+CAST( @fasrkeynumber AS VARCHAR(60))+'
WHERE [FA SR Number] = '+CAST( @fasrkeynumber AS VARCHAR(60)) + ' AND [Sent By] = ''' + @currentUser+'''
UNION
select 5, ''Desc: '' + [Description of the Issue/Situation/Problem] from process.temp_sendFA'+CAST( @fasrkeynumber AS VARCHAR(60))+'
WHERE [FA SR Number] = '+CAST( @fasrkeynumber AS VARCHAR(60)) + ' AND [Sent By] = ''' + @currentUser+'''
UNION
select 6, ''By: '' + CAST(left([Sent By],90) as varchar(90)) from process.temp_sendFA'+CAST( @fasrkeynumber AS VARCHAR(60))+'
WHERE [FA SR Number] = '+CAST( @fasrkeynumber AS VARCHAR(60)) + ' AND [Sent By] = ''' + @currentUser+'''
UNION
select 7, [Sent Datetime] from process.temp_sendFA'+CAST( @fasrkeynumber AS VARCHAR(60))+'
WHERE [FA SR Number] = '+CAST( @fasrkeynumber AS VARCHAR(60)) + ' AND [Sent By] = ''' + @currentUser+'''
'
EXEC sp_executesql @sqlcmd
 
 
SELECT @sqlcmd = '
SELECT TOP(1) LTD
into process.alert_textOUTPUT'+CAST( @fasrkeynumber AS VARCHAR(60))+ ' FROM (
SELECT ''LTD_ALERT'' a,STUFF((SELECT ''; '' + v.LTD_Alert
FROM process.temp_textOUTPUT'+CAST( @fasrkeynumber AS VARCHAR(60))+' v
WHERE v.LTD_Alert NOT LIKE ''%FASR%'' AND v.LTD_Alert NOT like ''%By%''
FOR XML PATH('''')), 1 , 1, '''') LTD
FROM process.temp_textOUTPUT'+CAST( @fasrkeynumber AS VARCHAR(60))+'
) q '
EXEC sp_executesql @sqlcmd
 
DECLARE @qryFinal NVARCHAR(MAX) = 'SELECT top(1) * FROM process.alert_textOUTPUT'+CAST( @fasrkeynumber AS VARCHAR(60))
 

--grab full message without html
DECLARE @full_message NVARCHAR(MAX);

DECLARE @sql NVARCHAR(MAX) =
    N'SELECT TOP (1)
         @out =
           ''SR Number: '' + CAST([FA SR Number] AS NVARCHAR(90)) + CHAR(13)+CHAR(10) +
           ''Vehicle Number: '' + CAST([Vehicle Number] AS NVARCHAR(90)) + CHAR(13)+CHAR(10) +
           ''Service Required Category: '' + CAST([Service Required Category] AS NVARCHAR(4000)) + CHAR(13)+CHAR(10) +
           ''Bus Exchanged With: '' + CAST([Bus Exchanged With] AS NVARCHAR(90)) + CHAR(13)+CHAR(10) +
           ''Description of the Issue/Situation/Problem: '' + ISNULL([Description of the Issue/Situation/Problem],'''') + CHAR(13)+CHAR(10) +
           ''Sent By: '' + CAST([Sent By] AS NVARCHAR(256)) + CHAR(13)+CHAR(10) +
           ''Sent Datetime: '' + CAST([Sent Datetime] AS NVARCHAR(60))
      FROM ' + QUOTENAME('process') + N'.' + QUOTENAME('temp_sendFA' + CAST(@fasrkeynumber AS VARCHAR(60))) + N';';

EXEC sys.sp_executesql
    @sql,
    N'@out NVARCHAR(MAX) OUTPUT',
    @out = @full_message OUTPUT;




--need to pull out text message 
DECLARE @text_message varchar(MAX);
DECLARE @sql_for_text_output NVARCHAR(MAX) =
    N'SELECT TOP (1) @out = LTD
      FROM ' + QUOTENAME('process') + N'.' + QUOTENAME('alert_textOUTPUT' + CAST(@fasrkeynumber AS VARCHAR(60))) + 
    N' ORDER BY 1;';

EXEC sys.sp_executesql
    @sql_for_text_output,
    N'@out NVARCHAR(MAX) OUTPUT',
    @out = @text_message OUTPUT;

--just in case text message is too big, trimming charaters
SET @text_message = CAST(LEFT(@text_message,150) AS VARCHAR(160))

INSERT INTO [process].[bulletin]
(
    [topic_code],
    [subject],
    [message],
    [message_html],
    [message_text],
    [sent],
    [sent_time]
)
VALUES
(   N'ORTRANLTD_68',     -- topic_code - nvarchar(50)
    N'Alert: Service Request',     -- subject - nvarchar(255)
    @full_message,     -- message - nvarchar(max)
    @html,     -- message_html - nvarchar(max)
    @text_message,    -- message_text - varchar(160)
    0, -- sent - bit
    NULL     -- sent_time - datetime2(7)
    );
 


INSERT INTO [process].[bulletin_fasr]
(
    [bulletin_id],
    [FASR_Key]
)
VALUES
(   scope_identity(), -- bulletin_id - int
    @fasrkeynumber  -- FASR_Key - bigint
    )


EXEC sp_executesql @sqlcleanup1
EXEC sp_executesql @sqlcleanup2
EXEC sp_executesql @sqlcleanup3
 

--table now has data, we can run the powershell code that reads the table and sends the message.
EXEC msdb.dbo.sp_start_job @job_name = N'Notify - Service Request Alert';

--• Lead – 5412281990@vtext.com
--• David – 5412281991@vtext.com
--• Eric – 5417312321@vtext.com
--• Allen – 5412857354 @vtext.com
--• Riley 5418449161@vtext.com
--• Andy 5039701137@vtext.com
 
END TRY
 
BEGIN CATCH
 
       DECLARE @profile VARCHAR(255) = (
                    SELECT NAME
                    FROM msdb.dbo.sysmail_profile
                    )
       DECLARE @errormsg VARCHAR(MAX)
             ,@error INT
             ,@message VARCHAR(MAX)
             ,@xstate INT
             ,@errsev INT
             ,@sub VARCHAR(255);
 
       SELECT @error = ERROR_NUMBER()
             ,@errsev = ERROR_SEVERITY()
             ,@message = ERROR_MESSAGE()
             ,@xstate = XACT_STATE();
 
       SELECT @errormsg = 'Error in ' + ISNULL(@SPROC, '') + ': ' + CAST(ISNULL(@error, '') AS NVARCHAR(32)) + '|' + COALESCE(@message, '') + '|' + CAST(ISNULL(@xstate, '') AS NVARCHAR(32)) + '|' +CAST(ISNULL(@errsev, '') AS NVARCHAR(32))
 
       SELECT @sub = 'ERROR: ' + @SPROC
 
       EXEC msdb.dbo.sp_send_dbmail @profile_name = @profile
             ,@recipients = 'data@ltd.org' 
             ,@subject = @sub
             ,@body = @errormsg;
 
       RAISERROR (
                    @errormsg
                    ,@errsev
                    ,1
                    )
END CATCH
 
  
GO
