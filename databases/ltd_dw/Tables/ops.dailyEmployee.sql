CREATE TABLE [ops].[dailyEmployee]
(
[ops_dailyEmployee_key] [int] NOT NULL IDENTITY(1, 1),
[division] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[opDate] [smalldatetime] NOT NULL,
[emp_SID] [int] NOT NULL,
[workStatus] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[timeBegin] [int] NULL,
[timeEnd] [int] NULL,
[timeWorked] [int] NULL,
[workWeek] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[dailyGenFlags] [smallint] NOT NULL,
[otherDiv] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[noteText] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[dailyWorkFlags] [smallint] NOT NULL,
[dailyTKFlags] [smallint] NOT NULL,
[OTafterTime] [int] NOT NULL,
[section15Rate] [numeric] (5, 2) NULL,
[timeWorkedSleep] [int] NULL,
[timeBeginSleep] [int] NULL,
[timeEndSleep] [int] NULL,
[actingForEmp_SID] [int] NULL,
[boardRating] [smallint] NULL,
[dailyPayRules] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[clientFlags] [smallint] NULL,
[boardStatus] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[weeklyPayRules] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tradeEmp_SID] [int] NULL,
[record_created_date] [datetime2] NOT NULL CONSTRAINT [DF__dailyEmpl__recor__18B3797D] DEFAULT (sysdatetime()),
[record_updated_date] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [ops].[dailyEmployee] ADD CONSTRAINT [PK_ops_dailyEmployee_key] PRIMARY KEY CLUSTERED ([ops_dailyEmployee_key]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [i_ops_dailyEmployee_opDate_Includes] ON [ops].[dailyEmployee] ([opDate]) INCLUDE ([division], [emp_SID]) ON [PRIMARY]
GO
