CREATE TABLE [tm].[significant_tps]
(
[significant_tp_key] [int] NOT NULL IDENTITY(1, 1),
[bid] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[route] [nvarchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[dir] [nchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[direction] [nvarchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tp] [nvarchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[significant] [nvarchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[record_created_date] [datetime2] NOT NULL CONSTRAINT [DF__significa__recor__5CA97C6E] DEFAULT (sysdatetime())
) ON [PRIMARY]
GO
