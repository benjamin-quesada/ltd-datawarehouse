CREATE TABLE [cits].[CITS_Deletes]
(
[CITS_delete_key] [int] NOT NULL IDENTITY(1, 1),
[ID] [int] NULL,
[FileSource] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cits_last_deleted_dt] [datetime2] NULL,
[cits_last_deleted_by] [nvarchar] (90) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[record_created_date] [datetime2] NOT NULL CONSTRAINT [DF__CITS_Dele__recor__50CF1623] DEFAULT (sysdatetime())
) ON [PRIMARY]
GO
