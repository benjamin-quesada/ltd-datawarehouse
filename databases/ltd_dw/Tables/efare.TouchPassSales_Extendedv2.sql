CREATE TABLE [efare].[TouchPassSales_Extendedv2]
(
[TxId] [bigint] NOT NULL,
[YYYYMM] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[saleTs] [datetime2] NOT NULL,
[saleLocalTs] [datetime2] NOT NULL,
[Reseller] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Product] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[AmtSales] [money] NULL,
[CountSales] [int] NULL,
[CreatedDate] [datetime2] NOT NULL CONSTRAINT [DF__TouchPass__Creat__2D69D708] DEFAULT (sysdatetime()),
[UpdatedDate] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [efare].[TouchPassSales_Extendedv2] ADD CONSTRAINT [PK__TouchPas__981E848EC775BC72] PRIMARY KEY CLUSTERED ([TxId], [Reseller], [Product], [saleTs]) WITH (FILLFACTOR=56) ON [PRIMARY]
GO
