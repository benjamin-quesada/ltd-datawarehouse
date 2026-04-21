CREATE TABLE [hastus].[bsi_headers]
(
[bsi_header_key] [bigint] NOT NULL IDENTITY(1, 1),
[rte_version] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trppt_stop_id] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tpat_route] [nvarchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rte_description] [varchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[time_from_point] [nvarchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[record_created_date] [datetime2] NOT NULL CONSTRAINT [DF__bsi_heade__recor__4387F963] DEFAULT (sysdatetime()),
[record_updated_date] [datetime2] NULL
) ON [PRIMARY]
GO
