CREATE TABLE [wrk].[temp_pc_trips]
(
[CALENDAR_ID] [numeric] (10, 0) NOT NULL,
[BLOCK_ID] [numeric] (10, 0) NULL,
[CALENDAR_DATE] [date] NULL,
[PROPERTY_TAG] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[GEO_NODE_ID] [numeric] (10, 0) NULL,
[GEO_NODE_ABBR] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[GEO_NODE_NAME] [varchar] (75) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TRIP_ID] [numeric] (10, 0) NULL,
[TRIP_END_TIME] [numeric] (9, 0) NULL,
[TRIP_END_HHMM] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[BOARD] [int] NULL,
[ALIGHT] [int] NULL,
[pc_count_time] [int] NULL,
[PC_COUNT_HHMM] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[BADGE] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[LAST_NAME] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[FIRST_NAME] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
