CREATE TABLE [hastus].[avl_pat]
(
[avl_pat_key] [int] NOT NULL IDENTITY(1, 1),
[filedate] [date] NOT NULL,
[file_row_id] [int] NOT NULL,
[tpat_route] [nvarchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tpat_external_id] [nvarchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tpat_direction] [nvarchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tpat_direction2] [nvarchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tpat_veh_display] [nvarchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tpat_in_serv] [nvarchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tpat_via] [nvarchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[via_desc] [nvarchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tpatpt_stop_id] [nvarchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tpatpt_load_place] [nvarchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tpatpt_veh_display_code] [nvarchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tpatpt_is_timing_point] [nvarchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[record_created_date] [datetime2] NOT NULL CONSTRAINT [DF__avl_pat__record___5220317D] DEFAULT (sysdatetime()),
[record_updated_date] [datetime2] NULL
) ON [PRIMARY]
GO
