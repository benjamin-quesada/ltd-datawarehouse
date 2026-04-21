CREATE TABLE [hastus].[avl_crw]
(
[avl_crw_key] [int] NOT NULL IDENTITY(1, 1),
[filedate] [date] NOT NULL,
[file_row_id] [int] NOT NULL,
[csc_name] [nvarchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[csc_sched_type] [nvarchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[csc_sched_type2] [nvarchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[csc_scenario] [nvarchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[csc_booking] [nvarchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[csc_sched_unit] [nvarchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[csc_description] [nvarchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[pce_duty_id] [nvarchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[pce_duty_id2] [nvarchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[dty_oper_days_12] [nvarchar] (7) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[blk_int_number] [nvarchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[pce_position] [nvarchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[pce_report_place] [nvarchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[pce_time_start] [nvarchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[pce_place_end] [nvarchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[pce_time_end] [nvarchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[pce_clear_place] [nvarchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[pce_clear_time] [nvarchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[pce_internal_no] [nvarchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[record_created_date] [datetime2] NOT NULL CONSTRAINT [DF__avl_crw__record___4F43C4D2] DEFAULT (sysdatetime()),
[record_updated_date] [datetime2] NULL
) ON [PRIMARY]
GO
