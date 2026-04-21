CREATE TABLE [hastus].[avl_pbs_raw]
(
[filedate] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[poster_stop_id] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[poster_description] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[poster_format] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[poster_route] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[poster_pattern] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[poster_prod_method] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[poster_type] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
