CREATE TABLE [tm].[TM_MATCH_NF_DRIVES]
(
[tm_match_drive_key] [bigint] NOT NULL IDENTITY(1, 1),
[calendar_id] [numeric] (10, 0) NOT NULL,
[the_bus] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[block_id] [numeric] (10, 0) NULL,
[block] [varchar] (9) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trip_id] [numeric] (10, 0) NULL,
[min_arr] [int] NULL,
[max_dep] [int] NULL,
[trip_end] [char] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sched] [char] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sched_spm] [numeric] (10, 0) NULL,
[rte] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rte_dir] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[stop_no] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[stop_name] [varchar] (75) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[operator] [varchar] (23) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tmTripOdo] [numeric] (9, 2) NULL,
[drive_id] [bigint] NULL,
[event_spm] [int] NULL,
[record_created_date] [datetime2] NULL CONSTRAINT [DF__TM_MATCH___recor__2D7D891B] DEFAULT (sysdatetime())
) ON [PRIMARY]
GO
