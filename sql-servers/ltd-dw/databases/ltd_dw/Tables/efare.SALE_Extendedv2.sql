CREATE TABLE [efare].[SALE_Extendedv2]
(
[saleLoadKey] [int] NOT NULL IDENTITY(1, 1),
[TxId] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Ts] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Type] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FareType] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[AccountId] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[passUsed] [varchar] (90) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SalesUser] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SalesUsername] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SalesChannel] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[resellerShortName] [varchar] (120) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FundingSourceType] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[LocationDescription] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Cost] [decimal] (9, 2) NULL,
[postedTs] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[lastModifiedTs] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[fileloaded] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_efare_SALE_Extendedv2_15313] ON [efare].[SALE_Extendedv2] ([resellerShortName]) INCLUDE ([Ts], [Type], [passUsed]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_efare_SALE_Extendedv2_15310] ON [efare].[SALE_Extendedv2] ([resellerShortName]) INCLUDE ([Ts], [Type], [passUsed], [Cost]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_efare_SALE_Extendedv2_resellerShortName_includes_5] ON [efare].[SALE_Extendedv2] ([resellerShortName]) INCLUDE ([TxId], [Ts], [Type], [passUsed], [Cost]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_SALE_Extendedv2_TxId] ON [efare].[SALE_Extendedv2] ([TxId]) ON [PRIMARY]
GO
