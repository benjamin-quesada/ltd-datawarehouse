CREATE TABLE [hastus].[avl_plc]
(
[avl_plc_key] [int] NOT NULL IDENTITY(1, 1),
[filedate] [date] NOT NULL,
[file_row_id] [int] NOT NULL,
[plc_identifier] [nvarchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[plc_description] [nvarchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[plc_reference_place] [nvarchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[plc_district] [nvarchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[plc_number] [nvarchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[plc_alter_name] [nvarchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[loca_x_coord] [nvarchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[loca_y_coord] [nvarchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[loca_longitude] [nvarchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[record_created_date] [datetime2] NOT NULL CONSTRAINT [DF__avl_plc__record___531455B6] DEFAULT (sysdatetime()),
[record_updated_date] [datetime2] NULL
) ON [PRIMARY]
GO
