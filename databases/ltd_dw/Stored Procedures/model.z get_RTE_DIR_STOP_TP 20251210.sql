SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [model].[z get_RTE_DIR_STOP_TP 20251210]
as
BEGIN TRY

set nocount on;


/*---------------------------------------
Tabular Model Source Data

CREATED		20221025
AUTHOR		B EICHBERGER
PURPOSE		set up a model source and disaster recovery backup of rte dir stop and timepoint activity
		    feeds tm_model

-- exec model.get_RTE_DIR_STOP_TP

 GRANT SELECT on model.ROUTE_DIR_STOP_TP to rpt_reader
 GRANT SELECT on model.ROUTE_DIR_STOP_TP to "LTD\sql_dw"
 GRANT EXECUTE on model.get_RTE_DIR_STOP_TP to "LTD\sql_dw" 
-- 
----------------------------------------*/


DECLARE @SPROC VARCHAR(100)
SET @SPROC = OBJECT_SCHEMA_NAME(@@PROCID) + '.' + OBJECT_NAME(@@PROCID)

 
insert model.ROUTE_DIR_STOP_TP ([ROUTE_ID]
,[ROUTE_DIRECTION_ID]
,[GEO_NODE_ID]
,[ROUTE_ABBR]
,[ROUTE_NAME]
,[STOP_ABBR]
,[ROUTE_DIRECTION_ABBR]
,[ROUTE_DIRECTION_NAME]
,[ROUTE_DIR]
,[STOP_NAME]
,[RTE_DIR_STOP_KEY]
,[STOP_LATITUDE]
,[STOP_LONGITUDE]
,[TIME_POINT_ABBR]
,[TIME_PT_NAME]
,[significant_tp]
)
select [ROUTE_ID]
,[ROUTE_DIRECTION_ID]
,[GEO_NODE_ID]
,[ROUTE_ABBR]
,[ROUTE_NAME]
,[STOP_ABBR]
,[ROUTE_DIRECTION_ABBR]
,[ROUTE_DIRECTION_NAME]
,[ROUTE_DIR]
,[STOP_NAME]
,[RTE_DIR_STOP_KEY]
,[STOP_LATITUDE]
,[STOP_LONGITUDE]
,[TIME_POINT_ABBR]
,[TIME_PT_NAME]
,[significant_tp]
from [ltd-tmdata].ltd_db.dbo.[ROUTE_DIR_STOP_TP_Model_Stage] s
where not exists (select 1 from model.ROUTE_DIR_STOP_TP where [RTE_DIR_STOP_KEY] = s.[RTE_DIR_STOP_KEY])

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
