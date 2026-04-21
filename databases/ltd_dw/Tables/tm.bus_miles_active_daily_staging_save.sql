CREATE TABLE [tm].[bus_miles_active_daily_staging_save]
(
[rn] [int] NOT NULL IDENTITY(1, 1),
[calendar_id] [int] NOT NULL,
[bus] [varchar] (9) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tm_miles] [numeric] (9, 2) NULL,
[eam_miles] [numeric] (9, 2) NULL,
[last_block] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[miles_total_est] [numeric] (9, 2) NULL,
[pull_in] [char] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[at_ltd] [smallint] NULL,
[record_created_date] [datetime2] NOT NULL CONSTRAINT [DF__bus_miles__recor__286EBB3B] DEFAULT (sysdatetime())
) ON [PRIMARY]
GO
