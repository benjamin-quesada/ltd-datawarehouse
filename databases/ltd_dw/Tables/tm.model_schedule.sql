CREATE TABLE [tm].[model_schedule]
(
[model_schedule_key] [bigint] NOT NULL IDENTITY(1, 1),
[sched_spm_route_stop_key] [varchar] (42) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CALENDAR_ID] [numeric] (10, 0) NOT NULL,
[MODEL_PARTITION] [int] NOT NULL,
[OPERATOR_ID] [numeric] (5, 0) NULL,
[TRIP_ID] [int] NULL,
[TRIP_END_TIME] [numeric] (9, 0) NULL,
[VEHICLE_ID] [numeric] (5, 0) NULL,
[PROPERTY_TAG] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
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
[OPERATOR_NAME] [nvarchar] (768) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[record_created_date] [datetime2] NOT NULL CONSTRAINT [DF__model_sch__recor__6B3068A9] DEFAULT (sysdatetime()),
[record_updated_date] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [tm].[model_schedule] ADD CONSTRAINT [PK_model_schedule2] PRIMARY KEY CLUSTERED ([model_schedule_key]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_tm_model_schedule_CALENDAR_ID] ON [tm].[model_schedule] ([CALENDAR_ID]) INCLUDE ([sched_spm_route_stop_key], [OPERATOR_ID], [TRIP_END_TIME], [VEHICLE_ID], [SERVICE_ABBR], [REVENUE_ID], [ROUTE_DIRECTION]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_tm_model_schedule_MODEL_PARTITION_sched_spm_route_stop_key] ON [tm].[model_schedule] ([MODEL_PARTITION], [sched_spm_route_stop_key]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_model_schedule] ON [tm].[model_schedule] ([sched_spm_route_stop_key], [VEHICLE_ID], [OPERATOR_ID], [ROUTE_DIRECTION], [REVENUE_ID], [SERVICE_ABBR], [TRIP_END_TIME]) ON [PRIMARY]
GO
