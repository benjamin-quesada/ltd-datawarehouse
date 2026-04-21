CREATE TABLE [tm].[TripTimeTidy]
(
[tttId] [bigint] NOT NULL IDENTITY(1, 1),
[the_date] [datetime] NOT NULL,
[calendar_id] AS ((100000000)+CONVERT([int],CONVERT([varchar](32),[the_date],(112)),(0))),
[srv_gen] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rte_public] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[dir] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tod_cat] [varchar] (11) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trip_start_sched] [char] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rte_public_and_dir] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[trip_complete] [int] NOT NULL,
[trip_actual_len_mins] [numeric] (9, 2) NULL,
[trip_end_sched] [char] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[trip_sched_len_mins] [int] NULL,
[trip_len_pct_of_sched] [int] NULL,
[trip_start_hhmmss] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[trip_start_adhere_mins] [numeric] (9, 2) NULL,
[trip_end_hhmmss] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[trip_end_adhere_mins] [numeric] (9, 2) NULL,
[trip_start_tp] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[trip_end_tp] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[trip_adherence_delta] [numeric] (10, 2) NULL,
[trip_actual_mph] [numeric] (9, 1) NULL,
[record_created_date] [datetime2] NULL CONSTRAINT [DF__TripTimeT__recor__7BDB408F] DEFAULT (sysdatetime()),
[record_updated_date] [datetime2] NULL
) ON [PRIMARY]
GO
