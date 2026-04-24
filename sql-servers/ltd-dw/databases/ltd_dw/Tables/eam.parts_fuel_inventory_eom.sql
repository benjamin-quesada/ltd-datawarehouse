CREATE TABLE [eam].[parts_fuel_inventory_eom]
(
[PFDI_Key] [int] NOT NULL IDENTITY(1, 1),
[Calendar_Id] [int] NOT NULL,
[InvYear] [int] NULL,
[InvMonth] [nvarchar] (33) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[InvGroup] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[InvSortOrder] [tinyint] NOT NULL,
[Fiscal Year] [int] NOT NULL,
[Fiscal Year Name] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Fiscal Period] [int] NOT NULL,
[Inv Date] [date] NOT NULL,
[rn] [int] NOT NULL,
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
[record_created_date] [datetime2] NOT NULL CONSTRAINT [DF__parts_fue__recor__6B41B488] DEFAULT (sysdatetime()),
[Account_ID] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Account_Name] [varchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [eam].[parts_fuel_inventory_eom] ADD CONSTRAINT [PK_parts_fuel_inventory_eom] PRIMARY KEY CLUSTERED ([PFDI_Key]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_parts_fuel_inventory_eom_calendar_id] ON [eam].[parts_fuel_inventory_eom] ([Calendar_Id]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_eam_parts_fuel_inventory_eom_7695] ON [eam].[parts_fuel_inventory_eom] ([Calendar_Id], [Fiscal Period], [rn]) INCLUDE ([InvGroup], [InvSortOrder], [Fiscal Year], [Fiscal Year Name], [part_no_and_suffix], [part_part_no], [part_suffix], [description_keyword], [description_short], [product_category], [product_category_description], [part_val_oh], [qty_on_hand], [cur_issue_price], [extended], [Account_ID], [Account_Name]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_eam_parts_fuel_inventory_eom_7703] ON [eam].[parts_fuel_inventory_eom] ([Calendar_Id], [rn]) INCLUDE ([InvGroup], [InvSortOrder], [Fiscal Year], [Fiscal Year Name], [Fiscal Period], [part_no_and_suffix], [part_part_no], [part_suffix], [description_keyword], [description_short], [product_category], [product_category_description], [part_val_oh], [qty_on_hand], [cur_issue_price], [extended], [Account_ID], [Account_Name]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_parts_fuel_inventory_eom_inv_month] ON [eam].[parts_fuel_inventory_eom] ([InvYear]) INCLUDE ([InvMonth]) ON [PRIMARY]
GO
