CREATE TABLE [hastus].[layovers]
(
[booking_id] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sched_type_id] [smallint] NULL,
[place_id] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[depart_time] [char] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Layover] [char] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[route_id_1] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[duty_id_1] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[arrive_time] [char] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[departure_minutes] [smallint] NULL,
[arrival_minutes] [smallint] NULL,
[layover_minutes] [smallint] NULL
) ON [PRIMARY]
GO
