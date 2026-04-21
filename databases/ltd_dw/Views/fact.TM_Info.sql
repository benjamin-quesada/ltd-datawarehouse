SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view [fact].[TM_Info]
as
/******************************************


PURPOSE	: specific to new flyer tabular model - which is on ice right now (as of 20250805 )
*/
select [cal_msgspm_key]
      ,[calendar_id]
      ,[time_table_version_id]
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
from [ltd_dw].[fact].[new_flyer_TM_Adh]
union
select [cal_msgspm_key]
      ,[calendar_id]
      ,[time_table_version_id]
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
from [ltd_dw].[fact].[new_flyer_TM_Pc]
GO
