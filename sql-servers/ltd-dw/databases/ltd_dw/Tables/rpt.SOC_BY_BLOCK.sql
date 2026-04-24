CREATE TABLE [rpt].[SOC_BY_BLOCK]
(
[nf_start_msgspm_key] [varchar] (38) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[nf_end_msgspm_key] [varchar] (38) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[nf_Cal] [int] NULL,
[fullDate] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Start Time] [int] NULL,
[End Time] [int] NULL,
[Bus] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Duration] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Mileage (miles)] [numeric] (24, 8) NULL,
[SOC MAX (perc)] [numeric] (8, 2) NULL,
[SOC MIN (perc)] [numeric] (8, 2) NULL,
[time_table_version_id] [int] NULL,
[BLOCK_ID] [numeric] (10, 0) NULL,
[OPERATOR_ID] [numeric] (5, 0) NULL,
[OPERATOR_NAME] [varchar] (42) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
