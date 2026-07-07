SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- 
-- =============================================
-- Create date: 20221115
-- Description:	Process tripstpe output for xml
--						with @currentUser reference
--
-- =============================================
--


CREATE   PROCEDURE [process].[station_graphics_xml_dropfile] AS

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


DECLARE @sg_xml xml;
SET @sg_xml = (
SELECT [poster_no]   = poster.poster_no
      ,[poster_desc] = poster.poster_desc
      ,[stop_no]     = poster.stop_no
      ,[stop_desc]   = poster.stop_desc
      ,[valid_from]  = poster.valid_from
      ,[valid_thru]  = poster.valid_thru
      ,(SELECT [rte_dest] = route_destinations.rte_dest,
               (SELECT [fn_char] = footnote.fn_char, [fn_text] = footnote.fn_text
                  FROM [ltd-hastus2].hastus_ltd.dbo.sg_rte_dest_footnotes footnote
                 WHERE footnote.poster_no = poster.poster_no AND footnote.rte_dest = route_destinations.rte_dest
                    AND footnote.fn_public = 'y'
                  ORDER BY footnote.fn_rn
                    for xml auto, elements, type),
               (select [service] = service.service,
                       (select [am_pm] = am_pm.am_pm,
                               (select [time] = departures.time, [fn_char] = departures.fn_char, [time_24] = departures.departs
                                  from [ltd-hastus2].hastus_ltd.dbo.sg_rte_dest_service_am_pm_departs departures
                                 where departures.poster_no = poster.poster_no and departures.rte_dest = route_destinations.rte_dest and departures.service = service.service and departures.am_pm = am_pm.am_pm
                                 order by departures.departs
                                   for xml auto, elements, type)
                          from [ltd-hastus2].hastus_ltd.dbo.sg_rte_dest_service_am_pms am_pm
                         where am_pm.poster_no = poster.poster_no and am_pm.rte_dest = route_destinations.rte_dest and am_pm.service = service.service
                         order by am_pm
                           for xml auto, elements, type)
                  from [ltd-hastus2].hastus_ltd.dbo.sg_rte_dest_services service
                 where service.poster_no = poster.poster_no
                   and service.rte_dest = route_destinations.rte_dest
                 order by svc_sort
                   for xml auto, elements, type)
          from [ltd-hastus2].hastus_ltd.dbo.sg_rte_dests route_destinations
         where route_destinations.poster_no = poster.poster_no 
           for xml auto, elements, type)
  from [ltd-hastus2].hastus_ltd.dbo.sg_posters poster
 order by poster.poster_desc
   for xml auto
)

DROP TABLE IF EXISTS process.poster_xml

SELECT @sg_xml AS output_xml 
INTO process.poster_xml

EXEC sp_configure 'show advanced options', 1;    
RECONFIGURE;  
EXEC sp_configure 'xp_cmdshell', 1;    
RECONFIGURE;  

EXEC xp_cmdshell 'NET USE L: \\ad.ltd.org\dfs\hastus2\tripstpe'

DECLARE @sqlcmd VARCHAR(500)
--select @sqlcmd = 'bcp "select '+@sg_xml+'" queryout L:\station_graphics_hastus2.xml -S (local) -T -w -r'
select @sqlcmd = 'bcp "select output_xml from process.poster_xml" queryout L:\station_graphics_hastus2.xml -S (local) -T -w -r'
--EXEC master..xp_cmdshell 'BCP "SELECT @sg_xml" queryout L:\station_graphics_hastus2.xml -S LTD-DW -T -c >nul' 

EXEC xp_cmdshell @sqlcmd

EXEC xp_cmdshell 'NET USE L: /D'


EXEC sp_configure 'xp_cmdshell', 0;   
RECONFIGURE; 
EXEC sp_configure 'show advanced options', 0;    
RECONFIGURE;   




END TRY

BEGIN CATCH

       DECLARE @profile VARCHAR(255) = (
                    SELECT NAME
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
