CREATE TABLE [pds].[Integration_EmpEmail]
(
[emp_email_key] [int] NOT NULL IDENTITY(1, 1),
[employee_id] [varchar] (90) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[emp_email] [varchar] (90) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[record_created_date] [datetime2] NULL CONSTRAINT [DF__Integrati__recor__14DA27AD] DEFAULT (sysdatetime())
) ON [PRIMARY]
GO
ALTER TABLE [pds].[Integration_EmpEmail] ADD CONSTRAINT [PK_Integration_EmpEmail] PRIMARY KEY CLUSTERED ([emp_email_key]) ON [PRIMARY]
GO
