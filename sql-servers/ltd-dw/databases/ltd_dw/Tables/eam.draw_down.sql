CREATE TABLE [eam].[draw_down]
(
[rn] [bigint] NULL,
[work_order_yr] [int] NULL,
[work_order_no] [int] NULL,
[work_order_yr_no] [varchar] (65) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[account_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[usr_closed_by] [nvarchar] (90) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[usr_finished_by] [nvarchar] (90) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[EQ_equip_no] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[busclass] [int] NULL,
[datetime_closed] [datetime] NULL,
[datetime_open] [datetime] NULL,
[warranty] [varchar] (7) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[comml_cost] [numeric] (12, 4) NULL,
[EMP_empl_no] [varchar] (9) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[indirect_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[eam_labor_cost] [numeric] (38, 6) NULL,
[ltd_calculated_labor_cost] [numeric] (38, 6) NULL,
[parts_issued_value] [numeric] (38, 6) NULL,
[parts_total_cost] [numeric] (38, 6) NULL,
[REAS_reas_for_repair] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[comment_area] [text] COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Description] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
