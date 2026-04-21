CREATE TABLE [eam].[workOrderTaskCategoryTime]
(
[work_key] [int] NOT NULL IDENTITY(1, 1),
[X_datetime_insert] [datetime] NULL,
[calendar_id] AS ((100000000)+CONVERT([int],CONVERT([varchar](32),CONVERT([date],[labor_date],(0)),(112)),(0))),
[work_order_yr] [int] NULL,
[work_order_no] [int] NULL,
[estimate] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[job_type] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[wcl_work_class] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[work_order_status] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[datetime_out_service] [datetime] NULL,
[datetime_in_service] [datetime] NULL,
[datetime_closed] [datetime] NULL,
[datetime_unit_in] [datetime] NULL,
[qty_est_hours] [numeric] (12, 2) NULL,
[meter_1_life_total] [int] NULL,
[meter_1_reading] [int] NULL,
[TASK_task_code] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[task_type] [varchar] (90) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[task_reason] [varchar] (90) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[emp_empl_no] [varchar] (9) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[labor_rate] [numeric] (12, 2) NULL,
[labor_hours] [numeric] (12, 2) NULL,
[labor_date] [date] NULL,
[wo_task_inserted] [datetime] NULL,
[wo_task_calendar_id] [int] NULL,
[wo_task_yr_no] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[employee_name] [varchar] (122) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[eq_equip_no] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[life_miles] [int] NULL,
[ltd_bus_class] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[bio_diesel] [int] NOT NULL,
[atric] [int] NOT NULL,
[emx_bus] [int] NOT NULL,
[hybrid] [int] NOT NULL,
[electric] [int] NOT NULL,
[max_fuel] [int] NOT NULL,
[active] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[unit_is_active] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ltd_bus_class_adj] [int] NULL,
[repair_group] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[repair_group_code] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[repair_category] [varchar] (28) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[backupCategory] [varchar] (28) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[task_code] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[category] [varchar] (28) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[record_created_date] [datetime2] NULL CONSTRAINT [DF__workOrder__recor__7E6D9477] DEFAULT (sysdatetime()),
[record_updated_date] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [eam].[workOrderTaskCategoryTime] ADD CONSTRAINT [PK_workOrderTaskCategoryTime] PRIMARY KEY CLUSTERED ([work_key]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_workOrderTaskCategoryTime_calendar_id_includes_all] ON [eam].[workOrderTaskCategoryTime] ([calendar_id]) INCLUDE ([work_order_yr], [work_order_no], [wcl_work_class], [work_order_status], [datetime_out_service], [datetime_in_service], [meter_1_reading], [wo_task_yr_no], [eq_equip_no], [category]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_workOrderTaskCategoryTime_category_work_order_yr_Includes] ON [eam].[workOrderTaskCategoryTime] ([category], [work_order_yr]) INCLUDE ([work_order_no], [meter_1_life_total], [meter_1_reading], [wo_task_calendar_id], [wo_task_yr_no], [eq_equip_no], [ltd_bus_class], [repair_group], [repair_group_code], [repair_category]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_workOrderTaskCategoryTime_recordcreateddate] ON [eam].[workOrderTaskCategoryTime] ([record_created_date]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_workOrderTaskCategoryTime_recordupdatedate] ON [eam].[workOrderTaskCategoryTime] ([record_updated_date]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_workOrderTaskCategoryTime_work_order_yr_work_order_no_more_includes] ON [eam].[workOrderTaskCategoryTime] ([work_order_yr], [work_order_no], [job_type], [emp_empl_no], [labor_rate], [labor_date], [wo_task_calendar_id], [eq_equip_no]) INCLUDE ([estimate], [wcl_work_class], [work_order_status], [datetime_out_service], [datetime_in_service], [datetime_closed], [datetime_unit_in], [qty_est_hours], [meter_1_life_total], [meter_1_reading], [TASK_task_code], [task_type], [task_reason], [labor_hours], [wo_task_yr_no], [employee_name], [life_miles], [ltd_bus_class], [bio_diesel], [atric], [emx_bus], [hybrid], [electric], [max_fuel], [active], [unit_is_active], [ltd_bus_class_adj], [repair_group], [repair_group_code], [backupCategory], [category]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_workOrderTaskCategoryTime_work_order_yr_work_order_no_more] ON [eam].[workOrderTaskCategoryTime] ([work_order_yr], [work_order_no], [job_type], [TASK_task_code], [emp_empl_no], [labor_rate], [labor_date], [eq_equip_no]) ON [PRIMARY]
GO
