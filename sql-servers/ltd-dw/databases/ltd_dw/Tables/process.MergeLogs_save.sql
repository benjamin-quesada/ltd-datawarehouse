CREATE TABLE [process].[MergeLogs_save]
(
[MergeLogID] [int] NOT NULL IDENTITY(1, 1),
[MergeCode] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ObjectDestination] [varchar] (90) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ObjectSource] [varchar] (90) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ObjectProgram] [varchar] (90) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[recInsert] [int] NULL,
[recUpdate] [int] NULL,
[recDelete] [int] NULL,
[MergeBeginDatetime] [datetime] NOT NULL CONSTRAINT [DF_process.MergeLogs_MergeBeginDatetime] DEFAULT (sysdatetime()),
[MergeEndDatetime] [datetime] NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_MergeLogs1] ON [process].[MergeLogs_save] ([MergeCode], [ObjectDestination], [ObjectSource], [ObjectProgram], [recInsert], [recUpdate], [recDelete], [MergeEndDatetime]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_MergeLog_ObjectDestination_IncludeMergeBeginDatetime] ON [process].[MergeLogs_save] ([ObjectDestination]) INCLUDE ([MergeBeginDatetime]) WITH (FILLFACTOR=56) ON [PRIMARY]
GO
