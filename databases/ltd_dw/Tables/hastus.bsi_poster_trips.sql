CREATE TABLE [hastus].[bsi_poster_trips]
(
[unique_id] [int] NOT NULL IDENTITY(1, 1),
[booking_id] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[poster_seq_no] [int] NOT NULL,
[poster_description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[stop_no] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[service] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[time_12hr] [char] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[time_ampm] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rte] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[dir] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rte_and_dir] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rte_destination] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rte_dir_destination] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[previous_tp_id] [varchar] (9) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[previous_tp] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[previous_tp_seq] [int] NULL,
[fn_char] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rn_within_svc] [int] NOT NULL,
[rn_max_within_svc] [int] NULL,
[fn_seq] [int] NULL,
[trip_no] [int] NOT NULL,
[trip_footnote_id] [varchar] (24) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[trip_footnote] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[time_24hr] [char] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[svc_sort] [int] NOT NULL,
[rpt_row] [int] NULL,
[rpt_col] [int] NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [bsi_trips_poster_seq_no_ndx] ON [hastus].[bsi_poster_trips] ([poster_seq_no]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [bsi_trips_stop_no_ndx] ON [hastus].[bsi_poster_trips] ([stop_no]) ON [PRIMARY]
GO
