CREATE TABLE [efare].[stage_SALE_Extendedv2]
(
[saleLoadKey] [int] NOT NULL IDENTITY(1, 1),
[TxId] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Ts] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Type] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FareType] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[AccountId] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PassUsed] [varchar] (90) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SalesUser] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SalesUsername] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SalesChannel] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[retailerShortName] [varchar] (120) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FundingSourceType] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[LocationDescription] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Cost] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[postedTs] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[lastModifiedTs] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[fileloading] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [efare].[stage_SALE_Extendedv2] ADD CONSTRAINT [PK_stage_SALE_Extendedv2] PRIMARY KEY CLUSTERED ([saleLoadKey]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_stage_SALE_Extendedv2_fileloading_includes15] ON [efare].[stage_SALE_Extendedv2] ([fileloading]) INCLUDE ([TxId], [Ts], [Type], [FareType], [AccountId], [PassUsed], [SalesUser], [SalesUsername], [SalesChannel], [retailerShortName], [FundingSourceType], [LocationDescription], [Cost], [postedTs], [lastModifiedTs]) ON [PRIMARY]
GO
