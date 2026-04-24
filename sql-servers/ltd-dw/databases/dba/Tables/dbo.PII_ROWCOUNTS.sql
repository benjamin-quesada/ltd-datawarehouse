CREATE TABLE [dbo].[PII_ROWCOUNTS]
(
[host] [varchar] (90) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[database_nm] [varchar] (90) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[schema_nm] [varchar] (90) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[table_nm] [varchar] (90) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[colCount] [int] NULL,
[rCount] [int] NULL,
[record_create_date] [datetime2] NULL DEFAULT (sysdatetime())
) ON [PRIMARY]
GO
