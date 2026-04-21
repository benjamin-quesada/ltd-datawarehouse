CREATE TABLE [pds].[Integration_EmpLicense]
(
[emp_license_key] [int] NOT NULL IDENTITY(1, 1),
[person_id] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[license] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[license_code] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[effective_date] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[expiration_date] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[license_number] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[record_created_date] [datetime2] NOT NULL CONSTRAINT [DF__Integrati__recor__4622D83E] DEFAULT (sysdatetime()),
[record_updated_date] [datetime2] NULL
) ON [PRIMARY]
GO
