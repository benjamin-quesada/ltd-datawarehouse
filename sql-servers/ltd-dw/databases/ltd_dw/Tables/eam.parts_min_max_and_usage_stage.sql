CREATE TABLE [eam].[parts_min_max_and_usage_stage]
(
[part_no] [varchar] (22) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[part_suffix] [int] NULL,
[part_short_description] [varchar] (140) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[keyword] [varchar] (140) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[product_category] [varchar] (140) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[eq_number] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[eq_type] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[issued_year] [int] NULL,
[issued_month] [int] NULL,
[qty_issued] [numeric] (38, 2) NULL,
[qty_issued_life] [numeric] (38, 2) NULL,
[qty_receipt] [numeric] (38, 2) NULL,
[minQty] [numeric] (12, 2) NOT NULL,
[maxQty] [numeric] (12, 2) NOT NULL,
[On Hand Plus On Order] [numeric] (38, 2) NOT NULL,
[TotalQuantityOnOrderForAllLoc] [numeric] (38, 2) NOT NULL,
[PrimaryBinID] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[IsObsolete] [int] NULL,
[IsTBD] [int] NULL,
[QuantityOnHand] [numeric] (14, 2) NOT NULL,
[record_created_date] [datetime2] NOT NULL CONSTRAINT [DF__parts_min__repor__6D4105D5] DEFAULT (sysdatetime())
) ON [PRIMARY]
GO
