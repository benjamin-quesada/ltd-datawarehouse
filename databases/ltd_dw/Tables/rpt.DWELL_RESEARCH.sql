CREATE TABLE [rpt].[DWELL_RESEARCH]
(
[dwellkey] [bigint] NOT NULL IDENTITY(1, 1),
[TIME_TABLE_VERSION_NAME] [varchar] (42) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ROUTE_DIRECTION_ABBR] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ROUTE_ABBR] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[STOP_ABBR] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[STOP_NAME] [varchar] (90) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[TRIP_ID] [bigint] NULL,
[SERVICE_ABBR] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Sched Vs Actual Arrive Time] [int] NULL,
[Actual Departure Minus Actual Arrive] [int] NULL,
[Actual Door Open to Close Time] [int] NULL,
[BOARD] [int] NULL,
[ALIGHT] [int] NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_RPT_DWELL_RESEARCH_VALUES_INCLUDES] ON [rpt].[DWELL_RESEARCH] ([Sched Vs Actual Arrive Time], [Actual Departure Minus Actual Arrive], [Actual Door Open to Close Time]) INCLUDE ([TIME_TABLE_VERSION_NAME], [ROUTE_DIRECTION_ABBR], [ROUTE_ABBR], [STOP_ABBR], [STOP_NAME], [TRIP_ID], [SERVICE_ABBR], [BOARD], [ALIGHT]) ON [PRIMARY]
GO
