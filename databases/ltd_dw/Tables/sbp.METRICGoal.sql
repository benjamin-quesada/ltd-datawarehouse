CREATE TABLE [sbp].[METRICGoal]
(
[sbpMETRICGoalKey] [int] NOT NULL IDENTITY(1, 1),
[historysbpMETRICGoalKey] [int] NULL,
[historysbpMetricKey] [int] NULL,
[sbpMETRICGoal] [varchar] (90) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sbpMETRICGoalContext] [varchar] (256) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sbpMETRICGoalEffectiveDate] [date] NULL,
[sbpMETRICGoalExpireDate] [date] NULL,
[sbpMETRICGoalCreateDate] [datetime2] NULL CONSTRAINT [DF_sbpMETRICGoal_sbpMETRICGoalCreateDate] DEFAULT (sysdatetime()),
[sbpMETRICGoalCreatedBy] [varchar] (90) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sbpMETRICGoalUpdatedLast] [datetime2] NULL,
[sbpMETRICGoalUpdatedBy] [varchar] (90) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sbpMETRICGoalHistoryRankorder] [int] NULL
) ON [PRIMARY]
GO
ALTER TABLE [sbp].[METRICGoal] ADD CONSTRAINT [PK_METRICGoal] PRIMARY KEY CLUSTERED ([sbpMETRICGoalKey]) ON [PRIMARY]
GO
