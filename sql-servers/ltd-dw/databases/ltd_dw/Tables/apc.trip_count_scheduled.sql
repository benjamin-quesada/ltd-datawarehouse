CREATE TABLE [apc].[trip_count_scheduled]
(
[trip_sched_key] [int] NOT NULL IDENTITY(1, 1),
[SCHEDULE_ID] [bigint] NOT NULL,
[CALENDAR_ID] [numeric] (10, 0) NOT NULL,
[TIME_TABLE_VERSION_ID] [numeric] (5, 0) NOT NULL,
[ROUTE_ID] [int] NULL,
[ROUTE_DIRECTION_ID] [int] NULL,
[GEO_NODE_ID] [numeric] (10, 0) NULL,
[VEHICLE_ID] [numeric] (10, 0) NULL,
[PROPERTY_TAG] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[BLOCK_ID] [numeric] (10, 0) NULL,
[TRIP_ID] [numeric] (10, 0) NULL,
[TIME_POINT_ID] [numeric] (5, 0) NULL,
[BLOCK_STOP_ORDER] [int] NOT NULL,
[SCHEDULED_TIME] [numeric] (10, 0) NULL,
[SCHEDULED_HHMM] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[record_created_date] [datetime2] NOT NULL CONSTRAINT [DF__trip_coun__recor__7F2E0B0C] DEFAULT (sysdatetime())
) ON [PRIMARY]
GO
