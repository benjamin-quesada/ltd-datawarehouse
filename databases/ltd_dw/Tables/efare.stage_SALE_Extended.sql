CREATE TABLE [efare].[stage_SALE_Extended]
(
[saleLoadKey] [int] NOT NULL IDENTITY(1, 1),
[TxId] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Ts] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Type] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FareType] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[AccountId] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SalesUser] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SalesUsername] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SalesChannel] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[retailerShortName] [varchar] (120) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FundingSourceType] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[LocationDescription] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Cost] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Comment] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[fileloading] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
