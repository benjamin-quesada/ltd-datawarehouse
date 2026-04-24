CREATE TABLE [tm].[z_apc_survey_trips]
(
[inserted_datetime] [datetime] NULL CONSTRAINT [DF_apc_survey_trips_inserted_datetime_1x] DEFAULT (sysdatetime()),
[survey_date] [date] NULL,
[rte_dir] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[trip_end] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[bus] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[initial_count] [smallint] NULL,
[surveyor_badge_f] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[surveyor_badge_m] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[surveyor_badge_r] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[fileSource] [varchar] (90) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[calendar_id] [int] NULL,
[exclude] [bit] NOT NULL CONSTRAINT [DF__apc_surve__exclu__75A278F5] DEFAULT ((0)),
[exclude_notes] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[initial_count_as_mpc_ons_at_1st_stop] [bit] NULL,
[initial_count_as_mpc_ons_at_1st_stop_notes] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
