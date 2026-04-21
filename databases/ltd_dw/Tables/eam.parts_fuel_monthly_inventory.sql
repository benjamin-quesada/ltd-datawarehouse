CREATE TABLE [eam].[parts_fuel_monthly_inventory]
(
[PFMI_Key] [int] NOT NULL IDENTITY(1, 1),
[Calendar_Id] [numeric] (10, 0) NOT NULL,
[InvYear] [int] NOT NULL,
[InvMonth] [nvarchar] (33) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[InvGroup] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[InvSortOrder] [tinyint] NOT NULL,
[Fiscal Year] [int] NOT NULL,
[Fiscal Year Name] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Fiscal Period] [int] NOT NULL,
[part_no_and_suffix] [varchar] (65) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[part_part_no] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[part_suffix] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description_keyword] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description_short] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[product_category] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[product_category_description] [varchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[part_val_oh] [numeric] (14, 2) NOT NULL,
[qty_on_hand] [numeric] (15, 3) NOT NULL,
[cur_issue_price] [numeric] (14, 4) NOT NULL,
[extended] [numeric] (14, 4) NOT NULL,
[record_created_date] [datetime2] NOT NULL CONSTRAINT [DF__parts_fue__recor__564697A2] DEFAULT (sysdatetime())
) ON [PRIMARY]
GO
ALTER TABLE [eam].[parts_fuel_monthly_inventory] ADD CONSTRAINT [PK_parts_fuel_monthly_inventory] PRIMARY KEY CLUSTERED ([PFMI_Key]) ON [PRIMARY]
GO
