CREATE TABLE [wrk].[tm_BusActiveToday_results]
(
[calendar_id] [int] NULL,
[bus] [varchar] (9) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[miles] [numeric] (9, 2) NULL,
[last_block] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[miles_total_est] [numeric] (9, 2) NULL,
[pull_in] [char] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[at_ltd] [smallint] NULL
) ON [PRIMARY]
GO
