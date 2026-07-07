CREATE TABLE [rpt].[VOMS_DAILY_HOURLY_UNFILTERED]
(
[VOMS_hourly_uf_key] [int] NOT NULL IDENTITY(1, 1),
[ldate] [int] NULL,
[HH] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[current_runs] [int] NULL,
[record_create_date] [datetime2] NULL CONSTRAINT [DF_VOMS_DAILY_HOURLY_uf_record_create_date] DEFAULT (sysdatetime()),
[record_update_date] [datetime2] NULL
)
GO
ALTER TABLE [rpt].[VOMS_DAILY_HOURLY_UNFILTERED] ADD CONSTRAINT [PK_VOMS_DAILY_HOURLY_UNFILTERED] PRIMARY KEY CLUSTERED ([VOMS_hourly_uf_key])
GO
