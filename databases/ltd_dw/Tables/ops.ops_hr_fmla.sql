CREATE TABLE [ops].[ops_hr_fmla]
(
[ops_hrfmla_key] [int] NOT NULL IDENTITY(1, 1),
[CaseNumber] [int] NULL,
[Department] [nvarchar] (90) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[LastName] [nvarchar] (55) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FirstName] [nvarchar] (55) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Employee ID] [int] NULL,
[Intermittent/Block] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[LeaveReason] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Expiration Date] [date] NULL,
[LeaveStatus] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Comments] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[record_created_date] [datetime2] NOT NULL CONSTRAINT [DF__ops_hr_fm__recor__4224CB02] DEFAULT (sysdatetime())
) ON [PRIMARY]
GO
