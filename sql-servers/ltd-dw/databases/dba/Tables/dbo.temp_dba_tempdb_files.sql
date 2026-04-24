CREATE TABLE [dbo].[temp_dba_tempdb_files]
(
[rn] [int] NOT NULL IDENTITY(1, 1),
[name] [sys].[sysname] NOT NULL,
[size] [int] NOT NULL,
[Size (MB)] [int] NULL,
[asof] [datetime2] NOT NULL DEFAULT (sysdatetime())
) ON [PRIMARY]
GO
