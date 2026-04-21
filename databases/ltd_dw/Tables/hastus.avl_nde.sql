CREATE TABLE [hastus].[avl_nde]
(
[avl_nde_key] [int] NOT NULL IDENTITY(1, 1),
[filedate] [date] NOT NULL,
[file_row_id] [int] NOT NULL,
[stp_identifier] [nvarchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[stp_description] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[stp_place] [nvarchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[loca_x_coord] [nvarchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[loca_y_coord] [nvarchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[loca_intersect_1] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[loca_intersect_2] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[loca_inter_distance] [nvarchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[loca_offset] [nvarchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[stp_district] [nvarchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[stp_zone] [nvarchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[stp_is_public] [nvarchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[loca_dist_inter1] [nvarchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[loca_dist_inter2] [nvarchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[stp_street_segment_id] [nvarchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[stp_loca_latitude] [nvarchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[stp_loca_longitude] [nvarchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[record_created_date] [datetime2] NOT NULL CONSTRAINT [DF__avl_nde__record___5037E90B] DEFAULT (sysdatetime()),
[record_updated_date] [datetime2] NULL
) ON [PRIMARY]
GO
