CREATE TABLE [wrk].[taxi_block]
(
[booking] [int] NOT NULL,
[schedule_type] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[block_route] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[block_number] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[block_sequence] [smallint] NULL,
[duty_operationg_days] [varchar] (7) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[run_exception] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[block_time_start_in_duration] [int] NULL,
[block_place_Start] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[block_time_end_in_duration] [int] NULL,
[block_place_end] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[block_tenth_mile_distance] [int] NULL,
[block_vehicle_group] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[block_vehicle_id_scheduling] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[emptyitem] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
