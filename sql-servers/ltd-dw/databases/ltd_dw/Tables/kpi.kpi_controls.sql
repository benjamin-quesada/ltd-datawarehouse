CREATE TABLE [kpi].[kpi_controls]
(
[kpi_user_id] [int] NOT NULL IDENTITY(1, 1),
[history_kpi_user_id] [int] NULL,
[kpi_user_email] [varchar] (70) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[kpi_nbr] [smallint] NOT NULL,
[kpi_start_dt] [date] NOT NULL,
[kpi_end_dt] [date] NOT NULL,
[kpi_historyControlRankorder] [smallint] NULL,
[record_created_date] [datetime] NOT NULL CONSTRAINT [DF__kpi_contr__recor__349EBC9F] DEFAULT (getdate()),
[record_created_by] [varchar] (70) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[record_updated_date] [datetime] NULL,
[record_updated_by] [varchar] (70) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [kpi].[kpi_controls] ADD CONSTRAINT [PK_kpi_controls] PRIMARY KEY CLUSTERED ([kpi_user_id]) ON [PRIMARY]
GO
