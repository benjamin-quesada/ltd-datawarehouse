CREATE TABLE [tm].[apc_block_trip_stop_detail]
(
[BLOCK_ID] [numeric] (10, 0) NULL,
[TRIP_ID] [numeric] (10, 0) NULL,
[TIME_TABLE_VERSION_ID] [numeric] (5, 0) NULL,
[PATTERN_ID] [numeric] (10, 0) NULL,
[STOP_ABBR] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[STOP_NAME] [varchar] (75) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[PATTERN_GEO_NODE_SEQ] [numeric] (7, 0) NULL,
[TRIP_PATTERN_SEQ] [numeric] (7, 0) NULL,
[CROSSING_TIME] [char] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CROSSING_TYPE_TEXT] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[IS_LAYOVER] [bit] NULL,
[ROUTE_ABBR] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ROUTE_DIRECTION_ABBR] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[IsRevenue] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CALENDAR_ID] [numeric] (10, 0) NOT NULL,
[BADGE] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[LAST_NAME] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[BOARD] [int] NOT NULL
) ON [PRIMARY]
GO
GRANT SELECT ON  [tm].[apc_block_trip_stop_detail] TO [public]
GO
