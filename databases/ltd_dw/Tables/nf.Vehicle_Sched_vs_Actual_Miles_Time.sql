CREATE TABLE [nf].[Vehicle_Sched_vs_Actual_Miles_Time]
(
[schedVsActKey] [bigint] NOT NULL IDENTITY(1, 1),
[calendar_id] [numeric] (10, 0) NOT NULL,
[time_table_version_id] [numeric] (10, 0) NULL,
[vehicle_id] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[route_id] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[route_direction_id] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[pattern_id] [numeric] (10, 0) NULL,
[block_id] [numeric] (10, 0) NULL,
[trip_id] [numeric] (10, 0) NULL,
[trip_end_time] [numeric] (10, 0) NULL,
[trip_mins] [numeric] (10, 2) NULL,
[trip_miles] [numeric] (10, 2) NULL,
[trip_operator_id] [numeric] (10, 0) NULL,
[svc] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sched_rev_miles] [int] NULL,
[record_created_date] [datetime2] NULL CONSTRAINT [DF__Vehicle_S__recor__07C1F487] DEFAULT (sysdatetime()),
[record_updated_date] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [nf].[Vehicle_Sched_vs_Actual_Miles_Time] ADD CONSTRAINT [PK_Vehicle_Sched_vs_Actual_Miles_Time] PRIMARY KEY CLUSTERED ([schedVsActKey]) ON [PRIMARY]
GO
