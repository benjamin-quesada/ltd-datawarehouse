CREATE TABLE [ops].[employee]
(
[ops_Employee_key] [int] NOT NULL IDENTITY(1, 1),
[emp_SID] [int] NOT NULL,
[lastName] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[firstName] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[mi] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[stampDate] [smalldatetime] NULL,
[stampUser] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[vacationSenDate] [smalldatetime] NULL,
[vacationSenLottery] [int] NULL,
[personnelID] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[empFlags] [smallint] NOT NULL,
[lastDayWorked] [smalldatetime] NULL,
[lastPlatformWorked] [smalldatetime] NULL,
[clientDate1] [smalldatetime] NULL,
[clientDate2] [smalldatetime] NULL,
[systemUserID] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[vacGroup] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[clientCode1] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[clientCode2] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[record_created_date] [datetime2] NOT NULL CONSTRAINT [DF__employee__record__3C51BB75] DEFAULT (sysdatetime()),
[record_updated_date] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [ops].[employee] ADD CONSTRAINT [PK_ops_Employee_key] PRIMARY KEY CLUSTERED ([ops_Employee_key]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_employee_personnelID] ON [ops].[employee] ([personnelID]) ON [PRIMARY]
GO
