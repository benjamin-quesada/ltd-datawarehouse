CREATE TABLE [hastus].[avl_rte]
(
[avl_rte_key] [bigint] NOT NULL IDENTITY(1, 1),
[filedate] [date] NOT NULL,
[file_row_id] [int] NULL,
[rte_identifier] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rte_description] [varchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rte_service_type] [varchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rte_service_type2] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rte_service_mode] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rte_service_mode2] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[record_created_date] [datetime2] NOT NULL CONSTRAINT [DF__avl_rte__record___54FC9E28] DEFAULT (sysdatetime()),
[record_updated_date] [datetime2] NULL
) ON [PRIMARY]
GO
