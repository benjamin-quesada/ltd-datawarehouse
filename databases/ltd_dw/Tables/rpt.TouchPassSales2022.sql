CREATE TABLE [rpt].[TouchPassSales2022]
(
[YYYYMM] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Reseller] [varchar] (120) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[VendorCode] [nvarchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Product] [nvarchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[AmtSales] [money] NULL,
[CountSales] [int] NULL,
[ProductPrice] [money] NULL,
[ProductDiscounted] [money] NULL,
[CreatedDate] [datetime2] NOT NULL CONSTRAINT [DF__TouchPass__Creat__6605D213] DEFAULT (sysdatetime())
) ON [PRIMARY]
GO
ALTER TABLE [rpt].[TouchPassSales2022] ADD CONSTRAINT [PK__TouchPas__2D9D45418B3F6357] PRIMARY KEY CLUSTERED ([YYYYMM], [Reseller], [Product]) WITH (FILLFACTOR=56) ON [PRIMARY]
GO
