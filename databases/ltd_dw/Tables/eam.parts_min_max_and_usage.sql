CREATE TABLE [eam].[parts_min_max_and_usage]
(
[parts_min_max_and_usage_key] [int] NOT NULL IDENTITY(1, 1),
[part_no] [varchar] (22) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[part_suffix] [int] NOT NULL,
[part_w_suffix] [varchar] (42) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
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
[record_created_date] [datetime2] NOT NULL CONSTRAINT [DF__parts_min__recor__16431B68] DEFAULT (sysdatetime()),
[record_updated_date] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [eam].[parts_min_max_and_usage] ADD CONSTRAINT [PK_parts_min_max_and_usage] PRIMARY KEY CLUSTERED ([parts_min_max_and_usage_key]) ON [PRIMARY]
GO
