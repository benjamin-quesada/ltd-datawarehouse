CREATE TABLE [pds].[Integration_EmpAbsent]
(
[emp_absent_key] [bigint] NOT NULL IDENTITY(1, 1),
[person_id] [int] NOT NULL,
[context_user_id] [varchar] (22) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[row_id] [int] NOT NULL,
[employee_id] [int] NOT NULL,
[company_code] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[company] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[accrual_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[accrual] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[from_date] [date] NOT NULL,
[return_date] [date] NULL,
[time_taken] [decimal] (15, 3) NULL,
[is_active] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[is_external_time] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[update_code] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[update_description] [varchar] (90) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[comments] [varchar] (1024) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[leave_reason] [varchar] (90) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[leave_reason_description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[record_created_date] [datetime2] NOT NULL CONSTRAINT [DF__Integrati__recor__02915A40] DEFAULT (sysdatetime()),
[record_updated_date] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [pds].[Integration_EmpAbsent] ADD CONSTRAINT [PK_Integration_EmpAbsent] PRIMARY KEY CLUSTERED ([emp_absent_key]) ON [PRIMARY]
GO
