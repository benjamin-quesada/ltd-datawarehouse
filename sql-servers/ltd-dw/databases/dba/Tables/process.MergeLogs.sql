CREATE TABLE [process].[MergeLogs]
(
[MergeLogID] [int] NOT NULL IDENTITY(1, 1),
[MergeType] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[MergeCode] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ObjectDestination] [varchar] (90) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ObjectSource] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ObjectProgram] [varchar] (90) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[recInsert] [int] NULL,
[recUpdate] [int] NULL,
[recDelete] [int] NULL,
[MergeBeginDatetime] [datetime] NOT NULL CONSTRAINT [DF_process.MergeLogs_MergeBeginDatetime] DEFAULT (sysdatetime()),
[MergeEndDatetime] [datetime] NULL
) ON [PRIMARY]
GO
