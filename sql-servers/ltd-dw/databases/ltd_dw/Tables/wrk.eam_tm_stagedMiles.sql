CREATE TABLE [wrk].[eam_tm_stagedMiles]
(
[calendar_id] [int] NOT NULL,
[bus] [varchar] (9) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tm_miles] [numeric] (9, 2) NOT NULL,
[eam_miles] [numeric] (9, 2) NOT NULL,
[last_block] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[miles_total_est] [numeric] (9, 2) NOT NULL,
[pull_in] [char] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[at_ltd] [smallint] NOT NULL,
[life_total_meter_1] [numeric] (9, 2) NOT NULL,
[last_fuel_date] [datetime] NOT NULL,
[last_fuel_qty] [numeric] (9, 2) NOT NULL
) ON [PRIMARY]
GO
