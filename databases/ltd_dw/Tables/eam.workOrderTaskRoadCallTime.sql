CREATE TABLE [eam].[workOrderTaskRoadCallTime]
(
[roadCallKey] [bigint] NOT NULL IDENTITY(1, 1),
[work_order_yr] [int] NULL,
[work_order_no] [int] NULL,
[calendar_id] [int] NULL,
[work_order_status] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[wo_task_yr_no] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[eq_equip_no] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Miles_At_Service] [int] NULL,
[meter_diff] [int] NULL,
[MilesAtLastRC] [int] NULL,
[milesBetweenRC] [int] NULL,
[record_created_date] [datetime2] NOT NULL CONSTRAINT [DF__workOrder__recor__5FE90D57] DEFAULT (sysdatetime()),
[record_updated_date] [datetime2] NULL
) ON [PRIMARY]
GO
