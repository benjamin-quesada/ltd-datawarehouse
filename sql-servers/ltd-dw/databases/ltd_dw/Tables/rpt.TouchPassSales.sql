CREATE TABLE [rpt].[TouchPassSales]
(
[YYYYMM] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Reseller] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Product] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[AmtSales] [money] NULL,
[CountSales] [int] NULL,
[CreatedDate] [datetime2] NOT NULL CONSTRAINT [DF__TouchPass__Creat__76694E71] DEFAULT (sysdatetime()),
[UpdatedDate] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [rpt].[TouchPassSales] ADD CONSTRAINT [PK__TouchPas__2D9D45419AF5EE60] PRIMARY KEY CLUSTERED ([YYYYMM], [Reseller], [Product]) WITH (FILLFACTOR=56) ON [PRIMARY]
GO
