SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [fact].[new_flyer_tm_info]
@calin int
as

/*
CREATED BY	: B Eichberger
CREATED DT	: 20210824
PURPOSE		: Return data to tabular model for new flyer bus
EXAMPLE		: exec fact.new_flyer_tm_info 120210707

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

delete from [fact].[new_flyer_TM_Adh] where calendar_id = @calin

insert [fact].[new_flyer_TM_Adh] ( 
[cal_msgspm_key]
      ,[calendar_id]
	  ,time_table_version_id
	  ,[veh]
      ,[BLOCK_ID]
      ,[ROUTE_DIRECTION_ID]
      ,[ROUTE_ID]
      ,[RTE]
      ,[RTE_DIR]
      ,[BLOCK_STOP_ORDER]
      ,[GEO_NODE_ABBR]
      ,[OPERATOR_ID]
      ,[LATITUDE]
      ,[LONGITUDE]
      ,[ADHERENCE])

select CAST(calendar_id AS VARCHAR(32)) + RIGHT('000000'+ CAST(MESSAGE_TIME AS VARCHAR(32)),6) cal_msgspm_key
	,a.calendar_id
	,a.time_table_version_id
	,i.EQ_equip_no AS veh, a.BLOCK_ID, a.ROUTE_DIRECTION_ID, a.ROUTE_ID, r.ROUTE_ABBR RTE, left(upper(rd.ROUTE_DIRECTION_ABBR),1) RTE_DIR
, a.BLOCK_STOP_ORDER,g.GEO_NODE_ABBR, OPERATOR_ID, g.LATITUDE, g.LONGITUDE, ADHERENCE
from  [ltd-tmdata].tmdatamart.dbo.ADHERENCE a WITH (NOLOCK)
JOIN [ltd-tmdata].tmdatamart.dbo.VEHICLE e ON e.VEHICLE_ID = a.VEHICLE_ID
join  model.Vehicle i WITH (NOLOCK) on i.EQ_equip_no = e.property_tag
join  [ltd-tmdata].tmdatamart.dbo.GEO_NODE g WITH (NOLOCK) on g.GEO_NODE_ID = a.GEO_NODE_ID
join  [ltd-tmdata].tmdatamart.dbo.[ROUTE] r WITH (NOLOCK) on r.ROUTE_ID = a.ROUTE_ID
join  [ltd-tmdata].tmdatamart.dbo.ROUTE_DIRECTION rd WITH (NOLOCK) on rd.ROUTE_DIRECTION_ID = a.ROUTE_DIRECTION_ID
where i.electric = 1 
and a.CALENDAR_ID = @calin
and MESSAGE_TIME is not null
OPTION (MAXDOP 2)


delete from [fact].[new_flyer_TM_Pc] where calendar_id = @calin 

insert [fact].[new_flyer_TM_Pc] ( 
	   [cal_msgspm_key]
      ,[calendar_id]
	  ,time_table_version_id
	  ,[veh]
      ,[BLOCK_ID]
      ,[ROUTE_DIRECTION_ID]
      ,[ROUTE_ID]
      ,[RTE]
      ,[RTE_DIR]
      ,[BLOCK_STOP_ORDER]
      ,[GEO_NODE_ABBR]
      ,[OPERATOR_ID]
      ,[LATITUDE]
      ,[LONGITUDE]
      ,[BOARD]
      ,[ALIGHT])
select [cal_msgspm_key]
      ,[calendar_id]
	  ,time_table_version_id
	  ,[veh]
      ,[BLOCK_ID]
      ,[ROUTE_DIRECTION_ID]
      ,[ROUTE_ID]
      ,[RTE]
      ,[RTE_DIR]
      ,[BLOCK_STOP_ORDER]
      ,[GEO_NODE_ABBR]
      ,[OPERATOR_ID]
      ,[LATITUDE]
      ,[LONGITUDE]
      ,sum([BOARD]) [BOARD]
      ,sum([ALIGHT]) [ALIGHT] from
	  (
select CAST(calendar_id AS VARCHAR(32)) + RIGHT('000000'+ CAST(MESSAGE_TIME AS VARCHAR(32)),6) cal_msgspm_key
,a.calendar_id, a.time_table_version_id,i.EQ_equip_no AS veh, a.BLOCK_ID, a.ROUTE_DIRECTION_ID, a.ROUTE_ID, r.ROUTE_ABBR RTE, left(upper(rd.ROUTE_DIRECTION_ABBR),1) RTE_DIR
, a.BLOCK_STOP_ORDER,g.GEO_NODE_ABBR, OPERATOR_ID, g.LATITUDE, g.LONGITUDE, BOARD, ALIGHT
from  [ltd-tmdata].tmdatamart.dbo.PASSENGER_COUNT a WITH (NOLOCK)
JOIN [ltd-tmdata].tmdatamart.dbo.VEHICLE e ON e.VEHICLE_ID = a.VEHICLE_ID
join  model.Vehicle i WITH (NOLOCK) on i.EQ_equip_no = e.property_tag
join  [ltd-tmdata].tmdatamart.dbo.GEO_NODE g WITH (NOLOCK) on g.GEO_NODE_ID = a.GEO_NODE_ID
join  [ltd-tmdata].tmdatamart.dbo.[ROUTE] r WITH (NOLOCK) on r.ROUTE_ID = a.ROUTE_ID
join  [ltd-tmdata].tmdatamart.dbo.ROUTE_DIRECTION rd WITH (NOLOCK) on rd.ROUTE_DIRECTION_ID = a.ROUTE_DIRECTION_ID
where i.electric = 1 
and a.CALENDAR_ID = @calin
and MESSAGE_TIME is not null
) q
group by 
[cal_msgspm_key]
      ,[calendar_id]
	  ,time_table_version_id
	  ,[veh]
      ,[BLOCK_ID]
      ,[ROUTE_DIRECTION_ID]
      ,[ROUTE_ID]
      ,[RTE]
      ,[RTE_DIR]
      ,[BLOCK_STOP_ORDER]
      ,[GEO_NODE_ABBR]
      ,[OPERATOR_ID]
      ,[LATITUDE]
      ,[LONGITUDE]
OPTION (MAXDOP 2)

END TRY

BEGIN CATCH

       DECLARE @profile VARCHAR(255) = (
                    SELECT [NAME]
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
