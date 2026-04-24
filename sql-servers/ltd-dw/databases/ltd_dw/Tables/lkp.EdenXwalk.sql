CREATE TABLE [lkp].[EdenXwalk]
(
[EdenXwalkKey] [int] NOT NULL IDENTITY(1, 1),
[historyEdenXwalkKey] [int] NULL,
[EdenXwalkCode] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[EdenXwalkName] [varchar] (120) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[EdenXwalkTouchPassName] [varchar] (120) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[EdenXwalkCreateDate] [datetime2] NOT NULL CONSTRAINT [DF__EdenXwalk__EdenX__0880433F] DEFAULT (sysdatetime()),
[EdenXwalkCreatedBy] [varchar] (90) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[EdenXwalkUpdatedLast] [datetime2] NULL,
[EdenXwalkUpdatedBy] [varchar] (90) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[EdenXwalkNoLongerActiveDate] [datetime] NULL,
[EdenXwalkHistoryRankorder] [int] NULL
) ON [PRIMARY]
GO
