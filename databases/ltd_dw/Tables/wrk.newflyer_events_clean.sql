CREATE TABLE [wrk].[newflyer_events_clean]
(
[drive_id] [bigint] NULL,
[trip_id] [bigint] NULL,
[event_id] [bigint] NULL,
[vehicle_id] [int] NULL,
[license_number] [int] NULL,
[event_time] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[event_type_id] [int] NULL,
[event_type_description] [varchar] (254) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[event_category] [int] NULL,
[event_category_description] [varchar] (90) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[latitude] [float] NULL,
[longitude] [float] NULL,
[end_time] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[end_latitude] [float] NULL,
[end_longitude] [float] NULL,
[Speed] [float] NULL,
[direction] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[driver_id] [int] NULL,
[driver_name] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[driver_code] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[worker_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
