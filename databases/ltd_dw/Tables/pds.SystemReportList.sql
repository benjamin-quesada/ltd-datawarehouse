CREATE TABLE [pds].[SystemReportList]
(
[report_id] [int] NOT NULL IDENTITY(1, 1),
[report_status] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[report_name_extracted] [varchar] (120) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[report_template] [varchar] (120) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[report_type] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[long_description] [varchar] (8000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[long_description_text] [varchar] (8000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[record_created_date] [datetime2] NULL CONSTRAINT [DF__SystemRep__recor__556091EC] DEFAULT (sysdatetime())
) ON [PRIMARY]
GO
ALTER TABLE [pds].[SystemReportList] ADD CONSTRAINT [PK_SystemReportList] PRIMARY KEY CLUSTERED ([report_id]) WITH (FILLFACTOR=56) ON [PRIMARY]
GO
CREATE FULLTEXT INDEX ON [pds].[SystemReportList] KEY INDEX [PK_SystemReportList] ON [Report Description]
GO
ALTER FULLTEXT INDEX ON [pds].[SystemReportList] ADD ([report_name_extracted] LANGUAGE 1033)
GO
ALTER FULLTEXT INDEX ON [pds].[SystemReportList] ADD ([long_description_text] LANGUAGE 1033)
GO
