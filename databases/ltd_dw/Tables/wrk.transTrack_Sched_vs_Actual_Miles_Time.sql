CREATE TABLE [wrk].[transTrack_Sched_vs_Actual_Miles_Time]
(
[calendar_id] [numeric] (10, 0) NOT NULL,
[time_table_version_id] [numeric] (10, 0) NOT NULL,
[vehicle_id] [numeric] (10, 0) NULL,
[route_id] [numeric] (10, 0) NULL,
[route_direction_id] [numeric] (10, 0) NULL,
[pattern_id] [numeric] (10, 0) NULL,
[trip_id] [numeric] (10, 0) NULL,
[block_id] [numeric] (10, 0) NULL,
[trip_mins] [numeric] (9, 2) NULL,
[trip_miles] [numeric] (10, 2) NULL,
[trip_operator_id] [numeric] (10, 0) NULL,
[svc] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sched_rev_miles] [int] NULL
) ON [PRIMARY]
GO
