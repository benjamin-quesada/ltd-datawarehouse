CREATE TABLE [hastus].[avl_net]
(
[avl_net_key] [int] NOT NULL IDENTITY(1, 1),
[filedate] [date] NULL,
[file_row_id] [int] NOT NULL,
[itn_stop_start] [nvarchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[itn_stop_end] [nvarchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[itn_distance] [nvarchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[itn_coord_x] [nvarchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[itn_coord_y] [nvarchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[itn_coord_long] [nvarchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[itn_coord_lat] [nvarchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[record_created_date] [datetime2] NOT NULL CONSTRAINT [DF__avl_net__record___512C0D44] DEFAULT (sysdatetime()),
[record_updated_date] [datetime2] NULL
) ON [PRIMARY]
GO
