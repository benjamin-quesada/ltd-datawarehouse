CREATE TABLE [wrk].[schedprep_ss2]
(
[sched_spm_route_stop_key] [varchar] (42) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CALENDAR_ID] [numeric] (10, 0) NOT NULL,
[OPERATOR_ID] [numeric] (5, 0) NULL,
[TRIP_ID] [numeric] (10, 0) NULL,
[TRIP_END_TIME] [numeric] (9, 0) NULL,
[MODEL_PARTITION] [int] NULL,
[VEHICLE_ID] [numeric] (5, 0) NOT NULL,
[PROPERTY_TAG] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[SERVICE_ABBR] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[SERVICE_TYPE_TEXT] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[TIME_POINT_ID] [numeric] (5, 0) NULL,
[IsTimepoint] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[REVENUE_ID] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ROUTE_ABBR] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ROUTE_NAME] [varchar] (75) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ROUTE_DIRECTION] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ROUTE_DIRECTION_NAME] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[GEO_NODE_ABBR] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[GEO_NODE_NAME] [varchar] (75) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[OPERATOR_NAME] [nvarchar] (768) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
