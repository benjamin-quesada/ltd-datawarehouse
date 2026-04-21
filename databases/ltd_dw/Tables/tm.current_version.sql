CREATE TABLE [tm].[current_version]
(
[rn] [int] NOT NULL IDENTITY(1, 1),
[BLOCK_ID] [numeric] (10, 0) NULL,
[BLOCK_ABBR] [varchar] (9) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[TIME_TABLE_VERSION_ID] [numeric] (5, 0) NULL,
[TIME_TABLE_VERSION_NAME] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[CALENDAR_ID] [numeric] (10, 0) NOT NULL,
[ACTUAL_PULLIN_TIME] [numeric] (10, 0) NULL,
[PULL_IN_ACTUAL_HHMMSS] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PULL_IN_ACTUAL_HHMM] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SCHEDULED_PULLIN_TIME] [numeric] (10, 0) NULL,
[PULL_IN_SCHED_HHMMSS] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PULL_IN_SCHED_HHMM] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PULLIN_VEHICLE_ID] [numeric] (5, 0) NULL,
[BUS] [int] NOT NULL,
[record_created_date] [datetime2] NULL CONSTRAINT [DF__current_v__recor__25924E90] DEFAULT (sysdatetime())
) ON [PRIMARY]
GO
