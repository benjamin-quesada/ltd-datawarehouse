CREATE TABLE [pds].[Integration_EmpExtended]
(
[emp_extended_key] [int] NOT NULL IDENTITY(1, 1),
[person_id] [int] NULL,
[bdt] [date] NULL,
[record_created_date] [datetime2] NOT NULL CONSTRAINT [DF__Integrati__recor__39A32EB6] DEFAULT (sysdatetime()),
[record_updated_date] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [pds].[Integration_EmpExtended] ADD CONSTRAINT [PK_Integration_EmpExtended] PRIMARY KEY CLUSTERED ([emp_extended_key]) ON [PRIMARY]
GO
