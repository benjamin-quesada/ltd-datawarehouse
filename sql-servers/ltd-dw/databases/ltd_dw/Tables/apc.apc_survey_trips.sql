CREATE TABLE [apc].[apc_survey_trips]
(
[apc_survey_key] [int] NOT NULL IDENTITY(1, 1),
[inserted_datetime] [datetime] NOT NULL CONSTRAINT [DF__apc_surve__inser__2CBE34E4] DEFAULT (sysdatetime()),
[survey_date] [date] NULL,
[rte_dir] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[trip_end] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[bus] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[initial_count] [smallint] NULL,
[surveyor_badge_f] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[surveyor_badge_m] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[surveyor_badge_r] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[fileSource] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[calendar_id] [int] NULL,
[exclude] [bit] NOT NULL CONSTRAINT [DF__apc_surve__exclu__2DB2591D] DEFAULT ((0)),
[exclude_notes] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[initial_count_as_mpc_ons_at_1st_stop] [bit] NULL,
[initial_count_as_mpc_ons_at_1st_stop_notes] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[record_updated_date] [datetime2] NULL
) ON [PRIMARY]
GO
