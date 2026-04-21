CREATE TABLE [pds].[Integration_Org]
(
[pds_org_id] [int] NOT NULL IDENTITY(1, 1),
[pds_org_status] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[org_id] [int] NULL,
[org_code] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[org_name] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[abbreviation] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[abbr] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[country_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[structure_level] [int] NULL,
[is_parent] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cagl] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[org_status] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[org_status_date] [datetime2] NULL,
[org_status_rsn_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[location_code] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[record_created_date] [datetime2] NULL CONSTRAINT [DF__Integrati__recor__321755AF] DEFAULT (sysdatetime()),
[record_updated_date] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [pds].[Integration_Org] ADD CONSTRAINT [PK_Integration_Org] PRIMARY KEY CLUSTERED ([pds_org_id]) ON [PRIMARY]
GO
