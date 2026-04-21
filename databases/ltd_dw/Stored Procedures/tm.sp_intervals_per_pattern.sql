SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   PROCEDURE [tm].[sp_intervals_per_pattern]
@p_rte NVARCHAR(32) ,
@p_ttv NVARCHAR(32) 
AS
/*
CREATED DT:		20220504
CREATED BY:		B. Eichberger
INFO	  :		RID-14683 Important bid related (Excel Report To Slow)

Replaces crystal report  (Query from tm v27 ltd_db1) with sproc call
GRANT EXECUTE ON tm.sp_intervals_per_pattern to public
exec tm.sp_intervals_per_pattern null,'11'

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



--DECLARE @p_ttv VARCHAR(90)= '' , @p_rte VARCHAR(90) = '11'
DECLARE @ttvSelect NVARCHAR(90) = (SELECT CASE WHEN @p_ttv = 'All' OR ISNULL(@p_ttv,'') = '' THEN '' ELSE ' AND ttv.time_table_version_name = ''' + @p_ttv +'''' END )
DECLARE @rteSelect NVARCHAR(90) = (SELECT CASE WHEN @p_rte = 'All' OR ISNULL(@p_rte,'') = '' THEN '' ELSE ' AND r.route_abbr = ''' + @p_rte +'''' END )

--PRINT @ttvSelect
--PRINT @rteSelect

DECLARE @sqlcmd NVARCHAR(MAX) = ''
SELECT @sqlcmd = @sqlcmd + '
SELECT p.ttv, p.route, p.rte_dir, p.pattern, p.pattern_abbr, p.interval_id, p.[sequence], p.interval_distance, 
	p.bread_crumb_distance, p.from_stop, p.from_stop_description, p.to_stop, p.to_stop_description,
    t.ACTIVATION_DATE, t.DEACTIVATION_DATE
FROM (
select [time_table_version_id] = ttv.time_table_version_id
      ,[ttv]                   = ttv.time_table_version_name
      ,[route]                 = r.route_abbr
      ,[rte_dir]               = left(rd.route_direction_name, 1) 
      ,[pattern]               = cast(p.pattern_abbr as int)
      ,[pattern_abbr]          = p.pattern_abbr
      ,[interval_id]           = gni.interval_id
      ,[pattern_id]            = p.pattern_id
      ,[sequence]              = pix.[sequence]
      ,[interval_distance]     = gni.interval_distance
      ,[bread_crumb_distance]  = gni.bread_crumb_distance
      ,[from_stop]             = gni.from_stop
      ,[from_stop_description] = gni.from_stop_description
      ,[to_stop]               = gni.to_stop
      ,[to_stop_description]   = gni.to_stop_description
from        [ltd-tmdata].tmmain.dbo.pattern                   p
 inner join [ltd-tmdata].tmmain.dbo.time_table_version        ttv on ttv.time_table_version_id = p.time_table_version_id
 inner join [ltd-tmdata].tmmain.dbo.[route]                   r   on p.route_id                = r.route_id
 inner join [ltd-tmdata].tmmain.dbo.route_direction           rd  on rd.route_direction_id     = p.route_direction_id
 inner join [ltd-tmdata].tmmain.dbo.pattern_geo_interval_xref pix on pix.time_table_version_id = ttv.time_table_version_id and pix.pattern_id = p.pattern_id 
 inner join [ltd-tmdata].ltd_db.dbo.ltd_geo_node_intervals_from_tmmain    gni on gni.interval_id           = pix.geo_node_interval_id
 where p.time_table_version_id >= 49
   '+@ttvSelect+'
   '+@rteSelect+'
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
ORDER BY p.TIME_TABLE_VERSION_ID desc '
PRINT @sqlcmd
EXECUTE sp_executesql @sqlcmd 
GO
GRANT EXECUTE ON  [tm].[sp_intervals_per_pattern] TO [public]
GO
