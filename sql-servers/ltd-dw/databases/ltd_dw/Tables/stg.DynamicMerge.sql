CREATE TABLE [stg].[DynamicMerge]
(
[TableCatalog] [varchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TableSchema] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TableName] [varchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ColumnName] [varchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MergeOn] [varchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[UpdateOn] [varchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[InsertOn] [varchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ExceptSource] [varchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ExceptTarget] [varchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[IsPK] [bit] NULL CONSTRAINT [DF__DynamicMer__IsPK__60420BC5] DEFAULT ((0))
) ON [PRIMARY]
GO
