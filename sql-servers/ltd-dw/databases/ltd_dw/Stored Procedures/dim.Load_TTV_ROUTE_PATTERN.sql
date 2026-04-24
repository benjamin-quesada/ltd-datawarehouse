SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE    PROCEDURE [dim].[Load_TTV_ROUTE_PATTERN]
as


/*---------------------------------------
With LTD standardized MERGE format for dimension SCD Type1

CREATED		20220510
AUTHOR		B EICHBERGER
PURPOSE		Collects and Loads Dimension for TTV Route and Pattern
			Used by Planning, possible future Model usage
REFERENCE	RID-14683 Bid Related Interval Crumbs Rpt Slow, In-Op
			Replace Crystal Report
-- 
--			exec dim.Load_TTV_ROUTE_PATTERN
			select * from dim.TTV_ROUTE_PATTERN 

CHANGED		20220622
CHANGE		Add maxdop, convert from tempdb to wrk table
CHANGEDBY	b eichberger
------------------------------------------

------------------LTD_GLOSSARY---------------
UPDATED BY:	Sopheap Suy
UPDATED DT:  10/31/2024
purpose	 :  Add object activities on who, what, when call this object
			write this data to aud.object_activity table everytime it's called
            
UPDATED BY:	Sopheap Suy
UPDATED DT:  04/02/2026
purpose	 :  change to truncate instead of drop and recreate for wrk.RPT_ttvSource
            
            */

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

--DROP TABLE IF EXISTS wrk.RPT_ttvSource
DROP TABLE IF EXISTS #RPT_ttvSource
/*
CREATE TABLE [wrk].[RPT_ttvSource](
	[ttv] [VARCHAR](12) NULL,
	[rte] [VARCHAR](8) NOT NULL,
	[rte_dir] [VARCHAR](1) NULL,
	[pattern] [INT] NULL,
	[pattern_abbr] [VARCHAR](10) NOT NULL,
	[interval_id] [INT] NOT NULL,
	[sequence] [NUMERIC](18, 0) NULL,
	[interval_distance] [NUMERIC](9, 0) NULL,
	[bread_crumb_distance] [NUMERIC](38, 0) NULL,
	[from_stop] [VARCHAR](8) NOT NULL,
	[from_stop_description] [VARCHAR](75) NOT NULL,
	[to_stop] [VARCHAR](8) NOT NULL,
	[to_stop_description] [VARCHAR](75) NOT NULL,
	[ACTIVATION_DATE] [DATETIME] NULL,
	[DEACTIVATION_DATE] [DATETIME] NULL,
	[time_table_version_id] [INT] NULL
) ON [PRIMARY]
*/
/*
INSERT wrk.[RPT_ttvSource] (
[ttv]
,[rte]
,[rte_dir]
,[pattern]
,[pattern_abbr]
,[interval_id]
,[sequence]
,[interval_distance]
,[bread_crumb_distance]
,[from_stop]
,[from_stop_description]
,[to_stop]
,[to_stop_description]
,[ACTIVATION_DATE]
,[DEACTIVATION_DATE]
,[time_table_version_id])
*/
SELECT cast(p.ttv as varchar(12)) as ttv, p.route as rte, p.rte_dir, p.pattern, p.pattern_abbr, p.interval_id, p.[sequence], p.interval_distance, 
	p.bread_crumb_distance, p.from_stop, p.from_stop_description, p.to_stop, p.to_stop_description,
    t.ACTIVATION_DATE, t.DEACTIVATION_DATE
,cast(p.time_table_version_id as int) time_table_version_id
INTO #RPT_ttvSource
FROM (
select [time_table_version_id] = ttv.time_table_version_id
      ,[ttv] = ttv.time_table_version_name
      ,[route] = r.route_abbr
      ,[rte_dir] = left(rd.route_direction_name, 1) 
      ,[pattern] = cast(p.pattern_abbr as int)
      ,[pattern_abbr] = p.pattern_abbr
      ,[interval_id] = gni.interval_id
      ,[pattern_id] = p.pattern_id
      ,[sequence] = pix.[sequence]
      ,[interval_distance] = gni.interval_distance
      ,[bread_crumb_distance] = gni.bread_crumb_distance
      ,[from_stop] = gni.from_stop
      ,[from_stop_description] = gni.from_stop_description
      ,[to_stop] = gni.to_stop
      ,[to_stop_description] = gni.to_stop_description
from        [ltd-tmdata].tmmain.dbo.pattern p WITH (NOLOCK)
 inner join [ltd-tmdata].tmmain.dbo.time_table_version ttv WITH (NOLOCK) on ttv.time_table_version_id = p.time_table_version_id
 inner join [ltd-tmdata].tmmain.dbo.[route] r WITH (NOLOCK) on p.route_id = r.route_id
 inner join [ltd-tmdata].tmmain.dbo.route_direction  rd WITH (NOLOCK)  on rd.route_direction_id = p.route_direction_id
 inner join [ltd-tmdata].tmmain.dbo.pattern_geo_interval_xref pix on pix.time_table_version_id = ttv.time_table_version_id and pix.pattern_id = p.pattern_id 
 inner join [ltd-tmdata].ltd_db.dbo.ltd_geo_node_intervals_from_tmmain gni on gni.interval_id = pix.geo_node_interval_id
 where p.time_table_version_id >= 49
 GROUP BY 
 ttv.time_table_version_id
,ttv.time_table_version_name
,r.route_abbr
,left(rd.route_direction_name, 1) 
,cast(p.pattern_abbr as int)
,p.pattern_abbr
,gni.interval_id
,p.pattern_id
,pix.[sequence]
,gni.interval_distance
,gni.bread_crumb_distance
,gni.from_stop
,gni.from_stop_description
,gni.to_stop
,gni.to_stop_description
) p
left JOIN [ltd-tmdata].tmmain.dbo.TIME_TABLE_VERSION t WITH (NOLOCK) ON
    p.time_table_version_id = t.TIME_TABLE_VERSION_ID
--ORDER BY p.TIME_TABLE_VERSION_ID DESC
 OPTION (MAXDOP 3);

MERGE ltd_dw.dim.TTV_ROUTE_PATTERN AS t
USING #RPT_ttvSource AS s
   ON (t.ttv = s.ttv
   AND t.time_table_version_id = s.time_table_version_id
   AND t.rte = s.rte
   AND t.pattern = s.pattern
   AND t.pattern_abbr = s.pattern_abbr
   AND t.interval_id = s.interval_id )
 WHEN MATCHED AND EXISTS (   SELECT s.ttv,
                                    s.time_table_version_id,
                                    s.rte,
                                    s.rte_dir,
                                    s.pattern,
                                    s.pattern_abbr,
                                    s.interval_id,
                                    s.sequence,
                                    s.interval_distance,
                                    s.bread_crumb_distance,
                                    s.from_stop,
                                    s.from_stop_description,
                                    s.to_stop,
                                    s.to_stop_description,
                                    s.activation_date,
                                    s.deactivation_date
                             EXCEPT
                             SELECT t.ttv,
                                    t.time_table_version_id,
                                    t.rte,
                                    t.rte_dir,
                                    t.pattern,
                                    t.pattern_abbr,
                                    t.interval_id,
                                    t.sequence,
                                    t.interval_distance,
                                    t.bread_crumb_distance,
                                    t.from_stop,
                                    t.from_stop_description,
                                    t.to_stop,
                                    t.to_stop_description,
                                    t.activation_date,
                                    t.deactivation_date) THEN
    UPDATE SET interval_distance = s.interval_distance,
               bread_crumb_distance = s.bread_crumb_distance,
               from_stop = s.from_stop,
               from_stop_description = s.from_stop_description,
               to_stop = s.to_stop,
               to_stop_description = s.to_stop_description,
               activation_date = s.activation_date,
               deactivation_date = s.deactivation_date,
               record_updated_date = SYSDATETIME()
 WHEN NOT MATCHED BY TARGET THEN
    INSERT (ttv,
            time_table_version_id,
            rte,
            rte_dir,
            pattern,
            pattern_abbr,
            interval_id,
            [sequence],
            interval_distance,
            bread_crumb_distance,
            from_stop,
            from_stop_description,
            to_stop,
            to_stop_description,
            activation_date,
            deactivation_date,
            record_created_date)
    VALUES (s.ttv, s.time_table_version_id, s.rte, s.rte_dir, s.pattern, s.pattern_abbr,
            s.interval_id, s.[sequence], s.interval_distance, s.bread_crumb_distance, s.from_stop,
            s.from_stop_description, s.to_stop, s.to_stop_description, s.activation_date, s.deactivation_date,
            SYSDATETIME())
 --WHEN NOT MATCHED BY SOURCE THEN DELETE;
 OPTION (MAXDOP 3);
 

--DROP TABLE IF EXISTS wrk.RPT_ttvSource
DROP TABLE IF EXISTS #RPT_ttvSource

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
            -- ,@recipients = 'barb.eichberger@ltd.org'--;servicedesk@ltd.org' 
               ,@recipients = 'sopheap.suy@ltd.org; barb.eichberger@ltd.org; data@ltd.org'
             ,@subject = @sub
             ,@body = @errormsg;

       RAISERROR (
                    @errormsg
                    ,@errsev
                    ,1
                    )
END CATCH
GO
