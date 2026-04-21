CREATE TABLE [wrk].[eam_tm_prepbus]
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
[life_total_meter_1] [numeric] (9, 2) NULL,
[last_fuel_date] [datetime] NULL,
[last_fuel_qty] [numeric] (9, 2) NULL
) ON [PRIMARY]
GO
