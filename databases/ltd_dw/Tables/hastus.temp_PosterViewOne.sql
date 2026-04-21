CREATE TABLE [hastus].[temp_PosterViewOne]
(
[booking_id] [varchar] (10) COLLATE SQL_Latin1_General_CP850_CI_AS NOT NULL,
[trip_no] [int] NULL,
[stop position in trip] [smallint] NULL,
[stop_id_1] [nvarchar] (9) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[stop_no] [int] NOT NULL,
[stop_description] [varchar] (100) COLLATE SQL_Latin1_General_CP850_CI_AS NULL,
[day] [int] NOT NULL,
[vscver_id] [int] NULL,
[time] [nvarchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[route_destination] [varchar] (40) COLLATE SQL_Latin1_General_CP850_CI_AS NULL,
[drop_off_only] [int] NOT NULL,
[route_id_1] [varchar] (5) COLLATE SQL_Latin1_General_CP850_CI_AS NULL,
[direction] [int] NULL,
[dir] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rte] [varchar] (5) COLLATE SQL_Latin1_General_CP850_CI_AS NULL,
[rte_and_dir] [varchar] (7) COLLATE SQL_Latin1_General_CP850_CI_AS NULL,
[rte_dir_destination] [varchar] (48) COLLATE SQL_Latin1_General_CP850_CI_AS NULL,
[rv_id] [varchar] (8) COLLATE SQL_Latin1_General_CP850_CI_AS NOT NULL,
[tpattern_id] [int] NULL,
[trip_note_id] [varchar] (8) COLLATE SQL_Latin1_General_CP850_CI_AS NULL,
[stop position of last stop in trip] [int] NULL,
[place of last stop in trip] [varchar] (100) COLLATE SQL_Latin1_General_CP850_CI_AS NULL,
[stp_position of previous tp] [int] NULL,
[time_factor] [real] NULL
) ON [PRIMARY]
GO
