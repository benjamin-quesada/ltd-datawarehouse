CREATE TABLE [webstore].[RefundStage]
(
[RefundStageID] [int] NOT NULL IDENTITY(1, 1),
[EtlProcessActivityID] [int] NOT NULL,
[ApiRequestID] [int] NOT NULL,
[ID] [bigint] NOT NULL,
[ParentID] [bigint] NOT NULL,
[DateCreated] [datetime] NULL,
[DateCreatedGmt] [datetime] NULL,
[Amount] [decimal] (18, 2) NULL,
[Reason] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RefundedBy] [bigint] NULL,
[RefundedPayment] [bit] NULL,
[MetaData] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[LineItems] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ShippingLines] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TaxLines] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FeeLines] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Links] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[StagedAt] [datetime] NOT NULL DEFAULT (getdate())
) ON [PRIMARY]
GO
ALTER TABLE [webstore].[RefundStage] ADD PRIMARY KEY CLUSTERED ([RefundStageID]) ON [PRIMARY]
GO
