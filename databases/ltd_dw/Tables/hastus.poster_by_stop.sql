CREATE TABLE [hastus].[poster_by_stop]
(
[poster_stop_id] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[poster_description] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[poster_format] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[poster_route] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[poster_pattern] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[poster_prod_method] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[poster_type] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[record_created_date] [datetime2] NULL CONSTRAINT [DF__poster_by__recor__7DCDAAA2] DEFAULT (sysdatetime()),
[record_updated_date] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [hastus].[poster_by_stop] ADD CONSTRAINT [PK_poster_by_stop] PRIMARY KEY CLUSTERED ([poster_stop_id]) ON [PRIMARY]
GO
