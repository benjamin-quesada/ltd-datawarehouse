CREATE TABLE [pds].[Integration_EmpRoleHistory_Stage]
(
[person_id] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[company_code] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[role_code] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[role_name] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[start_date] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[end_date] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[manager_position_id] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[manager_position_name] [varchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[manager_person_id] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[manager_person_name] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[pos_code] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[position_id] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[job_code] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[job_id] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[emp_type] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[start_person_reason_code] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[start_person_reason] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[end_person_reason_code] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[end_person_reason] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[row_id] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[record_staged_date] [datetime2] NULL CONSTRAINT [DF__Integrati__recor__512D7228] DEFAULT (sysdatetime())
) ON [PRIMARY]
GO
