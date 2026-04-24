CREATE TABLE [dbo].[PII_Information]
(
[Host_name] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DB_name] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Schema_name] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Table_name] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Column_name] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Data_type] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PII_Field] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
