CREATE TABLE [pds].[Integration_EmpDirectReport]
(
[emp_direct_report_id] [int] NOT NULL IDENTITY(1, 1),
[emp_direct_report_status] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[mgr_id] [int] NULL,
[mgr_position] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[person_id] [int] NULL,
[company_code] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[company] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[pos_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[pos_name] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[is_primary] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[job_code] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[job_name] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[structure_level] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[org_code] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[org_name] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[location_code] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[location_name] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[parent_position_id] [int] NULL,
[position_id] [int] NULL,
[emp_type] [int] NULL,
[name] [varchar] (210) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[record_created_date] [datetime2] NULL CONSTRAINT [DF__Integrati__recor__13C7D8B9] DEFAULT (sysdatetime()),
[record_updated_date] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [pds].[Integration_EmpDirectReport] ADD CONSTRAINT [PK_Integration_EmpDirectReport] PRIMARY KEY CLUSTERED ([emp_direct_report_id]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_Integration_EmpDirectReport_many] ON [pds].[Integration_EmpDirectReport] ([emp_direct_report_status], [person_id], [job_code], [position_id]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_pds_Integration_EmpDirectReport_person_id_mgr_id_Include1] ON [pds].[Integration_EmpDirectReport] ([person_id], [mgr_id]) INCLUDE ([record_created_date]) ON [PRIMARY]
GO
