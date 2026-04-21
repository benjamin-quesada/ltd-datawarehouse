CREATE TABLE [ops].[run]
(
[run_SID] [int] NOT NULL,
[runNumber] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[division] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[dayType] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[schedVersion] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[scheduleName] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[runPriority] [smallint] NULL,
[runType] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[appOrigin] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[runFlags] [smallint] NOT NULL,
[beginDate] [smalldatetime] NULL,
[endDate] [smalldatetime] NULL,
[runStatus] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[runcutFlags] [smallint] NOT NULL,
[primaryRoute] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[record_created_date] [datetime2] NOT NULL CONSTRAINT [DF__run__record_crea__6125797D] DEFAULT (getdate()),
[record_updated_date] [datetime2] NULL CONSTRAINT [DF__run__record_upda__62199DB6] DEFAULT (getdate())
) ON [PRIMARY]
GO
ALTER TABLE [ops].[run] ADD CONSTRAINT [PK_run] PRIMARY KEY CLUSTERED ([run_SID]) ON [PRIMARY]
GO
