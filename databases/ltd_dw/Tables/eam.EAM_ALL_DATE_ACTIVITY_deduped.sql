CREATE TABLE [eam].[EAM_ALL_DATE_ACTIVITY_deduped]
(
[eam_activity_key] [bigint] NOT NULL IDENTITY(1, 1),
[work_order_yr] [decimal] (10, 0) NULL,
[work_order_no] [int] NULL,
[label_name] [varchar] (90) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[the_date] [datetime] NULL,
[task_task_code] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[eq_equip_no] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[record_created_date] [datetime2] NOT NULL CONSTRAINT [DF__EAM_ALL_D__recor__688376C7] DEFAULT (sysdatetime()),
[record_updated_date] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [eam].[EAM_ALL_DATE_ACTIVITY_deduped] ADD CONSTRAINT [PK_EAM_ALL_DATE_ACTIVITY_dedupe] PRIMARY KEY CLUSTERED ([eam_activity_key]) ON [PRIMARY]
GO
