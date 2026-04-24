CREATE TABLE [wrk].[temp_prepStat]
(
[wn] [bigint] NULL,
[yearWk] [varchar] (14) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[calendar_date] [date] NULL,
[rte_public] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rte_and_dir] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rte_dir] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[operator] [varchar] (23) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[trip_id] [numeric] (10, 0) NULL,
[trip_end] [char] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[hour_Trip_end] [int] NULL,
[min_Trip_end] [int] NULL,
[sa_tp] [int] NOT NULL,
[revenue_id] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[overload_id] [int] NULL,
[the_bus] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tp] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tp_name] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[early] [numeric] (5, 0) NULL,
[late] [numeric] (5, 0) NULL,
[missing] [numeric] (5, 0) NULL,
[ontime] [numeric] (5, 0) NULL,
[not_ontime] [numeric] (7, 0) NULL,
[adhere_min] [numeric] (9, 2) NULL,
[adhere_sec] [numeric] (11, 0) NULL
) ON [PRIMARY]
GO
