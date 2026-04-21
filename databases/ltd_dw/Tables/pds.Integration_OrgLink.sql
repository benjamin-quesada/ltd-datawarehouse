CREATE TABLE [pds].[Integration_OrgLink]
(
[org_link_id] [int] NOT NULL IDENTITY(1, 1),
[org_link_status] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[org_id] [int] NULL,
[parent_id] [int] NULL,
[link_type] [int] NULL,
[record_created_date] [datetime2] NULL CONSTRAINT [DF__Integrati__recor__08211BE3] DEFAULT (sysdatetime()),
[record_updated_date] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [pds].[Integration_OrgLink] ADD CONSTRAINT [PK_Integration_OrgLink] PRIMARY KEY CLUSTERED ([org_link_id]) ON [PRIMARY]
GO
