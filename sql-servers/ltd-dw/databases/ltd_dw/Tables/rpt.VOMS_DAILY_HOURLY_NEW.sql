CREATE TABLE [rpt].[VOMS_DAILY_HOURLY_NEW]
(
[VOMS_NEW_hourly_key] [int] NOT NULL IDENTITY(1, 1),
[ldate] [int] NULL,
[HH] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[current_runs] [int] NULL,
[record_create_date] [datetime2] NULL CONSTRAINT [DF_VOMS_DAILY_HOURLY_NEW_record_create_date] DEFAULT (sysdatetime()),
[record_update_date] [datetime2] NULL
)
GO
ALTER TABLE [rpt].[VOMS_DAILY_HOURLY_NEW] ADD CONSTRAINT [PK_VOMS_DAILY_HOURLY_NEW] PRIMARY KEY CLUSTERED ([VOMS_NEW_hourly_key])
GO
