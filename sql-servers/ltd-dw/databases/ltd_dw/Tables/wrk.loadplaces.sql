CREATE TABLE [wrk].[loadplaces]
(
[file_row_id] [int] NOT NULL,
[tpat_route] [nvarchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tpat_external_id] [nvarchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tpat_via] [nvarchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[via_desc] [nvarchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tpatpt_stop_id] [nvarchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tpatpt_is_timing_point] [nvarchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tpatpt_load_place] [nvarchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
