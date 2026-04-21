CREATE TABLE [ops].[employee_info_seniority_with_pds]
(
[emp_seniority_key] [int] NOT NULL IDENTITY(1, 1),
[lastname] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[firstname] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[personnelid] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[status] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[lottery] [int] NULL,
[dateseniority] [smalldatetime] NULL,
[seniority_seq] [varchar] (13) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[retire_date] [smalldatetime] NULL,
[emp_sid] [int] NULL,
[dw_emp_id] [int] NULL,
[dw_status] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[seniority_date_pds] [datetime2] NULL,
[pds_person_id] [int] NULL,
[employee_id] [varchar] (9) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[hire_date] [datetime2] NULL,
[rehire_date_pds] [datetime2] NULL,
[termination_date_pds] [datetime2] NULL,
[review_date_pds] [datetime2] NULL,
[adjusted_service_date_pds] [datetime2] NULL,
[return_date_pds] [datetime2] NULL,
[record_created_date] [datetime2] NOT NULL CONSTRAINT [DF__employee___recor__138743DB] DEFAULT (sysdatetime()),
[record_updated_date] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [ops].[employee_info_seniority_with_pds] ADD CONSTRAINT [PK_employee_info_seniority_with_pds] PRIMARY KEY CLUSTERED ([emp_seniority_key]) ON [PRIMARY]
GO
