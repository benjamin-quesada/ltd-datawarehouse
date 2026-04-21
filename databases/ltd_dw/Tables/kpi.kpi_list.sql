CREATE TABLE [kpi].[kpi_list]
(
[kpi_id] [int] NOT NULL IDENTITY(1, 1),
[history_kpi_id] [int] NULL,
[kpi_name] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[kpi_friendly_name] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[kpi_sproc] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[kpi_sme_xref] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[kpi_description_xref] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[kpi_noLongActive] [datetime] NULL,
[kpi_historyListRankOrder] [smallint] NULL,
[record_created_date] [datetime] NOT NULL CONSTRAINT [DF_kpi_kpi_list_record_created_date] DEFAULT (getdate()),
[record_created_by] [varchar] (70) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[record_update_date] [date] NULL,
[record_update_by] [varchar] (70) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [kpi].[kpi_list] ADD CONSTRAINT [PK_kpi_list] PRIMARY KEY CLUSTERED ([kpi_id]) ON [PRIMARY]
GO
