CREATE TABLE [wrk].[tm_match_step1]
(
[min_cal_msgspm_key] [varchar] (38) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[max_cal_msgspm_key] [varchar] (38) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[calendar_id] [numeric] (10, 0) NOT NULL,
[veh] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[BLOCK_ABBR] [varchar] (9) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ROUTE_ABBR] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ROUTE_DIRECTION] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[operator] [varchar] (42) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
