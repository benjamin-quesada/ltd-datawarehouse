CREATE TABLE [efare].[stage_TXN]
(
[txnLoadKey] [int] NOT NULL IDENTITY(1, 1),
[Name] [varchar] (90) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Description] [varchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FareTx] [varchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[fileloading] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
