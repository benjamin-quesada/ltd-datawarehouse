CREATE TABLE [wrk].[apc_loss_setup_counts]
(
[CALENDAR_ID] [numeric] (10, 0) NOT NULL,
[TIME_TABLE_VERSION_ID] [numeric] (5, 0) NOT NULL,
[BLOCK_ID] [numeric] (10, 0) NULL,
[ROUTE_ID] [int] NULL,
[ROUTE_DIRECTION_ID] [numeric] (5, 0) NULL,
[GEO_NODE_ID] [numeric] (10, 0) NULL,
[MESSAGE_TIME] [int] NULL,
[TRIP_ID] [int] NOT NULL,
[HH] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MM] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SS] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[BOARD] [int] NULL,
[ALIGHT] [int] NULL,
[DEPARTURE_LOAD] [int] NULL,
[calendar_date] [datetime] NULL
)
GO
