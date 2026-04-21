CREATE TABLE [stg].[TouchPassSalesCount]
(
[YYYYMM] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Reseller] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Product] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[SalesCount] [int] NULL
) ON [PRIMARY]
GO
