CREATE TABLE [ops].[ops_hr_saif]
(
[ops_hrsaif_key] [int] NOT NULL IDENTITY(1, 1),
[EmployeeID] [int] NULL,
[LastName] [nvarchar] (55) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FirstName] [nvarchar] (55) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Date of Injury] [datetime] NULL,
[Status] [nvarchar] (55) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[record_created_date] [datetime2] NOT NULL CONSTRAINT [DF__ops_hr_sa__recor__45F55BE6] DEFAULT (sysdatetime())
) ON [PRIMARY]
GO
