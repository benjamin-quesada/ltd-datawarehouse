CREATE TABLE [tm].[stage_significant_tps]
(
[bid] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[route] [nvarchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[dir] [nchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[direction] [nvarchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tp] [nvarchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[significant] [nvarchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[record_created_date] [datetime2] NOT NULL CONSTRAINT [DF__stage_sig__recor__55FC7EDF] DEFAULT (sysdatetime())
) ON [PRIMARY]
GO
