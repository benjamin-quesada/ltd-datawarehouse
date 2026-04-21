CREATE TABLE [eam].[stage_parts_on_hand_old]
(
[insert_datetime] [smalldatetime] NOT NULL CONSTRAINT [def_stage_parts_on_hand_insert_datetime] DEFAULT (getdate()),
[part_part_no] [varchar] (22) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[prd_product_category] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[value_on_hand] [decimal] (14, 2) NOT NULL,
[qty_on_hand] [decimal] (14, 2) NOT NULL,
[cur_issue_price] [decimal] (14, 4) NOT NULL,
[part_suffix] [int] NOT NULL
) ON [PRIMARY]
GO
