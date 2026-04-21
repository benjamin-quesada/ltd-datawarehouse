CREATE TABLE [apc].[trip_count_candidates]
(
[trip_count_key] [int] NOT NULL IDENTITY(1, 1),
[CALENDAR_ID] [numeric] (10, 0) NOT NULL,
[BLOCK_ID] [numeric] (10, 0) NULL,
[TIME_TABLE_VERSION_ID] [numeric] (5, 0) NULL,
[ROUTE_ID] [int] NULL,
[ROUTE_DIRECTION_ID] [int] NULL,
[CALENDAR_DATE] [date] NULL,
[PROPERTY_TAG] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[GEO_NODE_ID] [int] NULL,
[GEO_NODE_ABBR] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[GEO_NODE_NAME] [varchar] (75) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TRIP_ID] [numeric] (10, 0) NULL,
[TRIP_END_TIME] [numeric] (9, 0) NULL,
[TRIP_END_HHMM] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[BOARD] [smallint] NULL,
[ALIGHT] [smallint] NULL,
[PC_COUNT_TIME] [int] NULL,
[PC_COUNT_HHMM] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[BADGE] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[LAST_NAME] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[FIRST_NAME] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[record_created_date] [datetime2] NOT NULL CONSTRAINT [DF__trip_coun__recor__7D45C29A] DEFAULT (sysdatetime())
) ON [PRIMARY]
GO
