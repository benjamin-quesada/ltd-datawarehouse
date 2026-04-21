CREATE TABLE [process].[PII_Column_Info]
(
[rowid] [int] NOT NULL IDENTITY(1, 1),
[db] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Column] [varchar] (90) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PII] [varchar] (90) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PII Data Domain] [varchar] (90) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[GDPR Classification] [varchar] (90) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[GDPR Data Domain] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[recordDate] [datetime2] NULL CONSTRAINT [DF__PII_Colum__recor__32767D0B] DEFAULT (sysdatetime())
) ON [PRIMARY]
GO
