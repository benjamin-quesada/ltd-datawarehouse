CREATE TABLE [tm].[z_apc_survey_data_entry_raw]
(
[survey_date] [date] NULL,
[rte_dir] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[trip_end] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[bus] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[surveyor_badge_f] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[surveyor_badge_m] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[surveyor_badge_r] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[initial_count] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[stop] [varchar] (90) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[stop_seq] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[time_f] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ons_f] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[offs_f] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[notes_f] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[time_m] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ons_m] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[offs_m] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[notes_m] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[time_r] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ons_r] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[offs_r] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[notes_r] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[filesource] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
