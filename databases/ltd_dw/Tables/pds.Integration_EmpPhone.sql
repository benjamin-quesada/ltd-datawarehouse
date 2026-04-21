CREATE TABLE [pds].[Integration_EmpPhone]
(
[emp_phone_id] [int] NOT NULL IDENTITY(1, 1),
[emp_phone_status] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[person_id] [int] NULL,
[employee_id] [varchar] (9) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[phone_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[phone] [varchar] (254) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[area_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[phone_no] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[phone_number] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[extension] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[country_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[country] [varchar] (254) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[is_unlisted] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[is_primary] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[record_created_date] [datetime2] NULL CONSTRAINT [DF__Integrati__recor__43ABF605] DEFAULT (sysdatetime()),
[record_updated_date] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [pds].[Integration_EmpPhone] ADD CONSTRAINT [PK_Integration_EmpPhone] PRIMARY KEY CLUSTERED ([emp_phone_id]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_pds_Integration_EmpPhone] ON [pds].[Integration_EmpPhone] ([person_id], [phone_number], [emp_phone_status]) ON [PRIMARY]
GO
