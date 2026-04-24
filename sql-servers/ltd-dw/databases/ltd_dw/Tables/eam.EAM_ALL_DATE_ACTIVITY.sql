CREATE TABLE [eam].[EAM_ALL_DATE_ACTIVITY]
(
[eam_activity_key] [bigint] NOT NULL IDENTITY(1, 1),
[work_order_yr] [decimal] (10, 0) NULL,
[work_order_no] [int] NULL,
[label_name] [varchar] (90) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[the_date] [datetime] NULL,
[task_task_code] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[part_part_no] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[part_suffix] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[eq_equip_no] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[record_created_date] [datetime2] NOT NULL CONSTRAINT [DF__EAM_ALL_D__recor__55C5A80E] DEFAULT (sysdatetime())
) ON [PRIMARY]
GO
ALTER TABLE [eam].[EAM_ALL_DATE_ACTIVITY] ADD CONSTRAINT [PK_EAM_ALL_DATE_ACTIVITY] PRIMARY KEY CLUSTERED ([eam_activity_key]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_eam_EAM_ALL_DATE_ACTIVITY] ON [eam].[EAM_ALL_DATE_ACTIVITY] ([work_order_yr], [work_order_no], [label_name], [the_date], [eq_equip_no]) INCLUDE ([task_task_code], [part_part_no], [part_suffix]) ON [PRIMARY]
GO
