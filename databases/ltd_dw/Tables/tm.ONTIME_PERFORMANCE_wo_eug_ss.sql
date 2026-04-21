CREATE TABLE [tm].[ONTIME_PERFORMANCE_wo_eug_ss]
(
[ontime_performance_key_wo_eug_ss] [bigint] NOT NULL IDENTITY(1, 1),
[svc] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[the_date] [datetime] NOT NULL,
[rte] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rte_dir] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[emx_block] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trip_end] [char] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sa_tps] [int] NOT NULL,
[time_points] [int] NULL,
[ontime] [numeric] (38, 0) NULL,
[early] [numeric] (38, 0) NULL,
[late] [numeric] (38, 0) NULL,
[missing] [numeric] (38, 0) NULL,
[not_missing] [int] NULL,
[report_created_date] [datetime2] NOT NULL CONSTRAINT [DF__ONTIME_PE__repor__04855B01] DEFAULT (sysdatetime()),
[report_updated_date] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [tm].[ONTIME_PERFORMANCE_wo_eug_ss] ADD CONSTRAINT [PK_ONTIME_PERFORMANCE_wo_eug_ss] PRIMARY KEY CLUSTERED ([ontime_performance_key_wo_eug_ss]) ON [PRIMARY]
GO
