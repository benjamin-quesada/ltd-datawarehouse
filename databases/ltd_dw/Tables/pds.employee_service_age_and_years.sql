CREATE TABLE [pds].[employee_service_age_and_years]
(
[age_svc_years_key] [bigint] NOT NULL IDENTITY(1, 1),
[CALENDAR_DATE] [date] NULL,
[emp_employee_id] [varchar] (9) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[age_at_cal_date] [int] NULL,
[age_at_hire_date] [int] NULL,
[hire_date] [date] NULL,
[termination_date] [date] NULL,
[start_years_of_service] [int] NULL,
[end_years_of_service] [int] NULL,
[record_created_date] [datetime2] NOT NULL CONSTRAINT [DF__employee___recor__2199C857] DEFAULT (sysdatetime()),
[record_updated_date] [datetime2] NULL
) ON [PRIMARY]
GO
