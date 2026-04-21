CREATE TABLE [dim].[TTV_ROUTE_PATTERN]
(
[ttv_route_pattern_key] [int] NOT NULL IDENTITY(1, 1),
[ttv] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[time_table_version_id] [int] NOT NULL,
[rte] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rte_dir] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[pattern] [int] NULL,
[pattern_abbr] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[interval_id] [numeric] (5, 0) NOT NULL,
[sequence] [numeric] (18, 0) NULL,
[interval_distance] [numeric] (9, 0) NULL,
[bread_crumb_distance] [numeric] (38, 0) NULL,
[from_stop] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[from_stop_description] [varchar] (75) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[to_stop] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[to_stop_description] [varchar] (75) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[activation_date] [datetime] NULL,
[deactivation_date] [datetime] NULL,
[record_created_date] [datetime2] NULL CONSTRAINT [DF__TTV_ROUTE__recor__5E39C7C2] DEFAULT (sysdatetime()),
[record_updated_date] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dim].[TTV_ROUTE_PATTERN] ADD CONSTRAINT [PK_TTV_ROUTE_PATTERN] PRIMARY KEY CLUSTERED ([ttv_route_pattern_key]) ON [PRIMARY]
GO
