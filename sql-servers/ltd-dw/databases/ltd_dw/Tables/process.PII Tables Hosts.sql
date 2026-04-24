CREATE TABLE [process].[PII Tables Hosts]
(
[rowId] [int] NOT NULL IDENTITY(1, 1),
[server] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[db] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Schema] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TableView] [varchar] (90) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Type] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Column] [varchar] (90) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Source] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Title] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Data type] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Nullable] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Default] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PII] [varchar] (90) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PII Data Domain] [varchar] (90) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[GDPR Classification] [varchar] (90) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[GDPR Data Domain] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[recordDate] [datetime2] NULL CONSTRAINT [DF__PII Table__recor__36470DEF] DEFAULT (sysdatetime())
) ON [PRIMARY]
GO
