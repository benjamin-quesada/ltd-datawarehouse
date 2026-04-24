CREATE TABLE [eam].[WorkOrderDetail]
(
[woDetailKey] [bigint] NOT NULL IDENTITY(1, 1),
[work_order_yr] [int] NULL,
[work_order_no] [int] NULL,
[wo_task_yr_no] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[work_order_status] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[eq_equip_no] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[calendar_id] [int] NULL,
[labor_date] [date] NULL,
[job_type] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[task_task_code] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[emp_empl_no] [varchar] (9) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[repair_group] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[repair_group_code] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[repair_category] [varchar] (28) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[category] [varchar] (28) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[HoursOutofServ] [int] NULL,
[DaysOutOfServ] [numeric] (17, 6) NULL,
[miles_at_service] [int] NULL,
[meter_prev_total] [int] NULL,
[meter_diff] [int] NULL,
[MilesSinceLastTask] [int] NULL,
[milesBetweenTasks] [int] NULL,
[record_created_date] [datetime2] NOT NULL CONSTRAINT [DF__WorkOrder__recor__66960AE6] DEFAULT (sysdatetime()),
[record_updated_date] [datetime2] NULL
) ON [PRIMARY]
GO
