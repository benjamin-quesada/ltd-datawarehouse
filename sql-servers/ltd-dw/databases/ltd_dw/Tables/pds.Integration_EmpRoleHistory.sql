CREATE TABLE [pds].[Integration_EmpRoleHistory]
(
[emp_role_his_key] [int] NOT NULL IDENTITY(1, 1),
[person_id] [int] NOT NULL,
[company_code] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[position_id] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[pos_code] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[role_code] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[role_name] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[start_date] [date] NOT NULL,
[end_date] [date] NULL,
[emp_type] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[start_person_reason_code] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[start_person_reason] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[end_person_reason_code] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[end_person_reason] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[record_created_date] [datetime2] NULL CONSTRAINT [DF__Integrati__recor__5F7B917F] DEFAULT (sysdatetime()),
[record_updated_date] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [pds].[Integration_EmpRoleHistory] ADD CONSTRAINT [PK_Integration_EmpRoleHistory] PRIMARY KEY CLUSTERED ([emp_role_his_key]) ON [PRIMARY]
GO
