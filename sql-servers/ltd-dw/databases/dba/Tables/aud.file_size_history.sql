CREATE TABLE [aud].[file_size_history]
(
[fileAuditId] [int] NOT NULL IDENTITY(1, 1),
[serverName] [nvarchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[databaseName] [sys].[sysname] NOT NULL,
[dataFileSizeMB] [numeric] (38, 6) NULL,
[logFileSizeMB] [numeric] (38, 6) NULL,
[record_created_date] [datetime2] NULL DEFAULT (sysdatetime())
) ON [PRIMARY]
GO
