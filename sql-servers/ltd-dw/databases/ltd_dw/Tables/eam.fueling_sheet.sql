CREATE TABLE [eam].[fueling_sheet]
(
[class] [int] NULL,
[bus] [varchar] (9) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[miles] [numeric] (9, 2) NULL,
[last_blk] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[miles_est] [numeric] (9, 2) NULL,
[pull_in] [char] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[at_ltd] [smallint] NULL,
[mf_fuel_dt] [datetime] NULL,
[mf_fuel_date] [date] NULL,
[mr_tm_date] [date] NULL,
[mr_tm_miles] [numeric] (38, 2) NULL,
[mr_fuel_qty] [numeric] (5, 1) NULL,
[comp_fuel_qty] [numeric] (5, 1) NULL,
[artic] [int] NOT NULL,
[rpt_group] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rpt_order_by_bus] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rpt_order_by_at_ltd_and_pullin] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rpt_order_by_block] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
