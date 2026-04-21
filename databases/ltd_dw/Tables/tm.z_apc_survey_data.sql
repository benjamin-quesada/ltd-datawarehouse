CREATE TABLE [tm].[z_apc_survey_data]
(
[inserted_datetime] [datetime] NOT NULL CONSTRAINT [DF_apc_survey_data_entry_raw_inserted_datetime_1] DEFAULT (getdate()),
[survey_date] [date] NULL,
[rte_dir] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[trip_end] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[stop_seq] [numeric] (7, 0) NULL,
[stop_no] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[stop_nm] [varchar] (90) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ons_f] [int] NULL,
[offs_f] [int] NULL,
[notes_f] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ons_m] [int] NULL,
[offs_m] [int] NULL,
[notes_m] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ons_r] [int] NULL,
[offs_r] [int] NULL,
[notes_r] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[time_f] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[time_m] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[time_r] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[fileSource] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_APC_SURVEY_DATAFilesource] ON [tm].[z_apc_survey_data] ([fileSource]) ON [PRIMARY]
GO
