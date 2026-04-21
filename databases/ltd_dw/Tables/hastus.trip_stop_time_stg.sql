CREATE TABLE [hastus].[trip_stop_time_stg]
(
[route_version] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[route_id] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[route_description] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[trip_number] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[trip_note_id] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[trip_stop_place] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[stop_id] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[trip_stop_arrival_time] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[trip_stop_note_id] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[trip_stop_is_time_point] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[trip_point_place_description] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[trip_operating_days] [varchar] (7) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
