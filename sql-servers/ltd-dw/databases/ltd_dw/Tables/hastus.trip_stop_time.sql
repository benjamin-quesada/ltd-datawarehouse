CREATE TABLE [hastus].[trip_stop_time]
(
[route_version] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[route_id] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[route_description] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[trip_number] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trip_note_id] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[trip_stop_place] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[stop_id] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trip_stop_arrival_time] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trip_stop_note_id] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[trip_stop_is_time_point] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[trip_point_place_description] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[trip_operating_days] [varchar] (7) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[record_create_date] [datetime] NULL CONSTRAINT [DF__trip_stop__recor__0662F0A3] DEFAULT (getdate())
) ON [PRIMARY]
GO
ALTER TABLE [hastus].[trip_stop_time] ADD CONSTRAINT [PK_trip_stop_time] PRIMARY KEY CLUSTERED ([route_version], [route_id], [trip_number], [stop_id], [trip_stop_arrival_time], [trip_operating_days]) ON [PRIMARY]
GO
