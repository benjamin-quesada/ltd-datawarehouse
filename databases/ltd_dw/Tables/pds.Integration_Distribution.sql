CREATE TABLE [pds].[Integration_Distribution]
(
[distribution_id] [int] NOT NULL IDENTITY(1, 1),
[distribution_status] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[company_code] [varchar] (54) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[distribution_code] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[distribution_name] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[dist_abbreviation] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[factor] [numeric] (9, 4) NULL,
[dist_status_code] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[dist_status_date] [datetime2] NULL,
[dist_status_rsn_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[record_created_date] [datetime2] NULL CONSTRAINT [DF__Integrati__recor__468862B0] DEFAULT (sysdatetime()),
[record_updated_date] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [pds].[Integration_Distribution] ADD CONSTRAINT [PK_Integration_Distribution] PRIMARY KEY CLUSTERED ([distribution_id]) ON [PRIMARY]
GO
