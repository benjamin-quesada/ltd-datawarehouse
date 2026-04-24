CREATE TABLE [aud].[adherence_with_interval_LTD]
(
[the_date] [datetime] NOT NULL,
[svc] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rte] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rte_dir] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[block] [varchar] (9) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trip_end] [char] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tp] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tp_name] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sched] [char] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[arrive] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[depart] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[dwell_min] [numeric] (9, 2) NULL,
[adhere_min] [numeric] (9, 2) NULL,
[sa_tp] [int] NOT NULL,
[ltd_status] [varchar] (7) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[late_waived_tp] [numeric] (5, 0) NULL,
[early_waived_tp] [numeric] (5, 0) NULL,
[missing_waived_tp] [numeric] (5, 0) NULL,
[white_line] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[drop_off_only] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
