CREATE TABLE [sbp].[METRIC]
(
[sbpMETRICKey] [int] NOT NULL IDENTITY(1, 1),
[historysbpMETRICKey] [int] NULL,
[sbpMETRICNameDataedo] [varchar] (90) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sbpMETRICNameLabel] [varchar] (90) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sbpMETRICCode] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sbpMETRICDesc] [varchar] (256) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sbpMETRICGroup] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__METRIC__sbpMETRI__1C1DF2EF] DEFAULT ((0)),
[sbpMETRICDataType] [varchar] (90) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sbpMETRICCreateDate] [datetime2] NOT NULL CONSTRAINT [DF_sbpMETRIC_sbpMETRICCreateDate] DEFAULT (sysdatetime()),
[sbpMETRICCreatedBy] [varchar] (90) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sbpMETRICUpdatedLast] [datetime2] NULL,
[sbpMETRICUpdatedBy] [varchar] (90) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sbpMETRICNoLongerActiveDate] [datetime] NULL,
[sbpMETRICHistoryRankorder] [int] NULL
) ON [PRIMARY]
GO
