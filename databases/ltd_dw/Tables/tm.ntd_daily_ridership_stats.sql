CREATE TABLE [tm].[ntd_daily_ridership_stats]
(
[ntd_daily_ridership_stat_ID] [int] NOT NULL IDENTITY(1, 1),
[calendar_id] [int] NOT NULL,
[service_type] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[boardings] [int] NULL,
[passenger_miles] [int] NULL,
[mobility_assisted_boardings] [int] NULL,
[special_event_boardings] [int] NULL,
[sched_rev_hours] [int] NULL,
[actual_rev_hours] [int] NULL,
[sched_rev_miles] [int] NULL,
[sched_total_miles] [int] NULL,
[actual_rev_miles] [int] NULL,
[sched_in_service_hours] [int] NULL,
[sched_total_hours] [int] NULL,
[actual_in_service_hours] [int] NULL,
[actual_total_hours] [int] NULL,
[record_create_date] [datetime] NULL CONSTRAINT [DF__ntd_daily__recor__57A801BA] DEFAULT (sysdatetime()),
[record_update_date] [datetime] NULL
) ON [PRIMARY]
GO
