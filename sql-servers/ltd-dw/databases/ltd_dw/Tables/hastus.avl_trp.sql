CREATE TABLE [hastus].[avl_trp]
(
[avl_trp_key] [bigint] NOT NULL IDENTITY(1, 1),
[filedate] [date] NOT NULL,
[file_row_id] [int] NOT NULL,
[trp_int_number] [int] NULL,
[trp_number] [nvarchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[trp_operating_days] [nvarchar] (7) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[trp_route_statistic] [nvarchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tpat_external_id] [nvarchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[trp_type] [nvarchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[trp_type_code] [nvarchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[trp_is_special] [nvarchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[trp_is_public] [nvarchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tstp_passing_time] [nvarchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[record_created_date] [datetime2] NOT NULL CONSTRAINT [DF__avl_trp__record___55F0C261] DEFAULT (sysdatetime()),
[record_updated_date] [datetime2] NULL
) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [ix_avl_trip_filedate_trp_number_trp_op_days] ON [hastus].[avl_trp] ([filedate], [trp_number], [trp_operating_days]) ON [PRIMARY]
GO
