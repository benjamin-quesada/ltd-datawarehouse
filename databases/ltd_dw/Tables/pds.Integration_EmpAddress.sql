CREATE TABLE [pds].[Integration_EmpAddress]
(
[emp_address_id] [int] NOT NULL IDENTITY(1, 1),
[emp_address_status] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[person_id] [int] NULL,
[employee_id] [varchar] (9) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[address_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[address] [varchar] (254) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[address_line1] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[address_line2] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[address_line3] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[address_line4] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[address_lines] [varchar] (120) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[city] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[county] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[state] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[state_name] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[zip] [varchar] (9) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[zip_code] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[record_created_date] [datetime2] NULL CONSTRAINT [DF__Integrati__recor__3FDB6521] DEFAULT (sysdatetime()),
[record_updated_date] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [pds].[Integration_EmpAddress] ADD CONSTRAINT [PK_Integration_EmpAddress] PRIMARY KEY CLUSTERED ([emp_address_id]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_pds_Integration_EmpAddress_emp_address_id] ON [pds].[Integration_EmpAddress] ([emp_address_id]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_Integration_EmpAddress_emp_address_status_address_code] ON [pds].[Integration_EmpAddress] ([emp_address_status], [address_code]) INCLUDE ([person_id]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_Integration_EmpAddress_Includes4] ON [pds].[Integration_EmpAddress] ([emp_address_status], [person_id], [address_code], [address]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_Integration_EmpAddress_many] ON [pds].[Integration_EmpAddress] ([emp_address_status], [person_id], [address_code], [address]) INCLUDE ([employee_id], [address_line1], [address_line2], [address_line3], [address_line4], [address_lines], [city], [county], [state], [state_name], [zip], [zip_code]) ON [PRIMARY]
GO
