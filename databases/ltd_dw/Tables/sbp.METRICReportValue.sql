CREATE TABLE [sbp].[METRICReportValue]
(
[sbpMETRICReportValueKey] [int] NOT NULL IDENTITY(1, 1),
[historysbpMETRICReportValueKey] [int] NULL,
[sbpMETRICReportValue] [varchar] (90) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sbpMETRICReportValueContext] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sbpMETRICReportValueCreateDate] [datetime2] NOT NULL CONSTRAINT [DF_sbpMETRICReportValue_sbpMETRICReportValueCreateDate] DEFAULT (sysdatetime()),
[sbpMETRICReportValueCreatedBy] [varchar] (90) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sbpMETRICReportValueCreateContext] [varchar] (256) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sbpMETRICReportValueUpdatedLast] [datetime2] NULL,
[sbpMETRICReportValueUpdatedBy] [varchar] (90) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sbpMETRICReportValueUpdateContext] [varchar] (256) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sbpMETRICReportValueHistoryRankorder] [int] NULL
) ON [PRIMARY]
GO
ALTER TABLE [sbp].[METRICReportValue] ADD CONSTRAINT [PK_METRICReportValue] PRIMARY KEY CLUSTERED ([sbpMETRICReportValueKey]) ON [PRIMARY]
GO
