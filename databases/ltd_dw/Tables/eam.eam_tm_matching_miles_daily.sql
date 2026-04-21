CREATE TABLE [eam].[eam_tm_matching_miles_daily]
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
[life_total_meter_1] [int] NULL,
[last_fuel_date] [date] NULL,
[last_fuel_qty] [numeric] (12, 3) NULL,
[record_created_date] [datetime2] NOT NULL CONSTRAINT [DF__eam_tm_ma__recor__1EE55101] DEFAULT (sysdatetime())
) ON [PRIMARY]
GO
GRANT SELECT ON  [eam].[eam_tm_matching_miles_daily] TO [public]
GO
