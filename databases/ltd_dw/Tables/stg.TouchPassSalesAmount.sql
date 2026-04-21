CREATE TABLE [stg].[TouchPassSalesAmount]
(
[YYYYMM] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Reseller] [varchar] (120) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Product] [nvarchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[AmtSales] [money] NULL
) ON [PRIMARY]
GO
