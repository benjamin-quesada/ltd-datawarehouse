CREATE TABLE [eam].[work_order_yr_no]
(
[work_order_yr_no] [varchar] (65) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rn] [bigint] NULL,
[job_type] [varchar] (8000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[calid_entered] [int] NULL,
[date_entered] [datetime] NULL,
[hours_out_of_service] [numeric] (17, 6) NULL,
[hours_to_first_work] [numeric] (17, 6) NULL,
[hours_to_finished_work] [numeric] (17, 6) NULL,
[hours_to_closed] [numeric] (17, 6) NULL
) ON [PRIMARY]
GO
