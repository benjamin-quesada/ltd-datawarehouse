CREATE TABLE [process].[IndexOptimization]
(
[SessionKey] [bigint] NOT NULL,
[Timing] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[objectid] [int] NULL,
[ObjectName] [nvarchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[indexid] [int] NULL,
[partitionnum] [int] NULL,
[frag] [float] NULL,
[name] [sys].[sysname] NULL,
[asofDateTime] [datetime2] NOT NULL CONSTRAINT [DF__IndexOpti__asofD__41B8C09B] DEFAULT (sysdatetime())
) ON [PRIMARY]
GO
