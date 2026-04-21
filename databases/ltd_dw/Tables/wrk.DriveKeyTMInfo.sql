CREATE TABLE [wrk].[DriveKeyTMInfo]
(
[CAL_SPM_KEY] [bigint] NULL,
[drive_id] [bigint] NULL,
[license_number] [int] NULL,
[drive_license_key] [varchar] (38) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[trip_start_data] [varchar] (38) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[trip_end_date] [varchar] (38) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[calendar_id] [numeric] (10, 0) NULL,
[time_table_version_id] [int] NULL,
[veh] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[BLOCK_ID] [numeric] (10, 0) NULL,
[ROUTE_DIRECTION_ID] [numeric] (5, 0) NULL,
[ROUTE_ID] [int] NULL,
[RTE] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RTE_DIR] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[BLOCK_STOP_ORDER] [int] NULL,
[GEO_NODE_ABBR] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[OPERATOR_ID] [numeric] (5, 0) NULL,
[LATITUDE] [numeric] (12, 0) NULL,
[LONGITUDE] [numeric] (12, 0) NULL
) ON [PRIMARY]
GO
