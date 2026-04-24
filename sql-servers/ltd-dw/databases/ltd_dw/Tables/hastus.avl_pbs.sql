CREATE TABLE [hastus].[avl_pbs]
(
[avl_pbs_key] [bigint] NOT NULL IDENTITY(1, 1),
[poster_stop_id] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[poster_description] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[poster_format] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[poster_route] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[poster_pattern] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[poster_prod_method] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[poster_type] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[excluded] [date] NULL,
[record_created_date] [datetime2] NULL CONSTRAINT [DF__avl_pbs__record___2DCDC26E] DEFAULT (sysdatetime()),
[record_updated_date] [datetime2] NULL
) ON [PRIMARY]
GO
