CREATE TABLE [process].[MergeLogs]
(
[MergeLogID] [int] NOT NULL IDENTITY(1, 1),
[MergeCode] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ObjectDestination] [varchar] (90) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ObjectSource] [varchar] (90) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ObjectProgram] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[recInsert] [int] NULL,
[recUpdate] [int] NULL,
[recDelete] [int] NULL,
[MergeBeginDatetime] [datetime] NOT NULL CONSTRAINT [DF__MergeLogs__Merge__431EB495] DEFAULT (sysdatetime()),
[MergeEndDatetime] [datetime] NULL
) ON [PRIMARY]
GO
ALTER TABLE [process].[MergeLogs] ADD CONSTRAINT [PK_MergeLogs] PRIMARY KEY CLUSTERED ([MergeLogID]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_MergeLogs1] ON [process].[MergeLogs] ([MergeCode], [ObjectDestination], [ObjectSource], [ObjectProgram], [recInsert], [recUpdate], [recDelete], [MergeEndDatetime]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_MergeLog_ObjectDestination_IncludeMergeBeginDatetime] ON [process].[MergeLogs] ([ObjectDestination]) INCLUDE ([MergeBeginDatetime]) WITH (FILLFACTOR=56) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_process_mergelogs_objectDestination_objectProgram_Include_MergeBeginDatetime] ON [process].[MergeLogs] ([ObjectDestination], [ObjectProgram]) INCLUDE ([MergeBeginDatetime]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_MergeLogs_ObjectSource_MergeBeginDatetime_Includes3] ON [process].[MergeLogs] ([ObjectSource], [MergeBeginDatetime]) INCLUDE ([ObjectDestination], [recInsert], [recUpdate], [recDelete]) ON [PRIMARY]
GO
