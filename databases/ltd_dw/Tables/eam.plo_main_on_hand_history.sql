CREATE TABLE [eam].[plo_main_on_hand_history]
(
[insert_datetime] [datetime] NULL CONSTRAINT [DF_plo_main_on_hand_history_insert_datetime] DEFAULT (getdate()),
[part_part_no] [varchar] (22) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[prd_product_category] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[value_on_hand] [decimal] (14, 2) NULL,
[qty_on_hand] [decimal] (14, 2) NULL,
[cur_issue_price] [decimal] (14, 4) NULL,
[part_suffix] [int] NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_plo_main_on_hand_history_insert_datetime] ON [eam].[plo_main_on_hand_history] ([insert_datetime]) INCLUDE ([part_part_no], [prd_product_category], [value_on_hand], [qty_on_hand], [cur_issue_price], [part_suffix]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_plo_main_on_hand_history_part_suffix_insert_datetime] ON [eam].[plo_main_on_hand_history] ([part_suffix], [insert_datetime]) INCLUDE ([part_part_no], [prd_product_category], [value_on_hand], [qty_on_hand], [cur_issue_price]) ON [PRIMARY]
GO
EXEC sp_addextendedproperty N'1', N'replace [eam].[stage_parts_on_hand]', 'SCHEMA', N'eam', 'TABLE', N'plo_main_on_hand_history', NULL, NULL
GO
