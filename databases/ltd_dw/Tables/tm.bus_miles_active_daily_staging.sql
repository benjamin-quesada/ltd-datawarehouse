CREATE TABLE [tm].[bus_miles_active_daily_staging]
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
[record_created_date] [datetime2] NOT NULL CONSTRAINT [DF__bus_miles__recor__17442F39] DEFAULT (sysdatetime())
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_bus_miles_acrive_daily_staging_calendarId_LastBlock_Includes7] ON [tm].[bus_miles_active_daily_staging] ([calendar_id], [last_block]) INCLUDE ([rn], [bus], [tm_miles], [eam_miles], [miles_total_est], [pull_in], [at_ltd]) ON [PRIMARY]
GO
