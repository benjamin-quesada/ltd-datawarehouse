CREATE TABLE [ops].[dailyEmployeeTimeDetail]
(
[dailyEmployeeTimeDetail_Key] [bigint] NOT NULL IDENTITY(1, 1),
[opDate] [smalldatetime] NOT NULL,
[division] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[emp_SID] [int] NOT NULL,
[detailSequence] [smallint] NOT NULL,
[paySource] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[payType] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[payDate] [smalldatetime] NOT NULL,
[workDivision] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[runNumber] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[blockRoute] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[blockID] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[workClass] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[keyTime] [int] NULL,
[originalTime] [int] NULL,
[paidTime] [int] NULL,
[calcTime] [int] NULL,
[timeAtStraight] [int] NULL,
[timeAtOT] [int] NULL,
[dailyTKDetailFlags] [int] NOT NULL,
[workAccount] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[recType] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[userID] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[userTime] [datetime] NULL,
[comment] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[record_created_date] [datetime2] NOT NULL CONSTRAINT [DF__dailyEmpl__recor__04DF8C89] DEFAULT (sysdatetime()),
[record_updated_date] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [ops].[dailyEmployeeTimeDetail] ADD CONSTRAINT [PK_dailyEmployeeTimeDetail_1] PRIMARY KEY CLUSTERED ([dailyEmployeeTimeDetail_Key]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_ops_dailyEmployeeTimeDetail_9] ON [ops].[dailyEmployeeTimeDetail] ([emp_SID], [opDate], [payType]) INCLUDE ([paySource], [payDate], [runNumber], [blockRoute], [blockID], [keyTime], [calcTime]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_dailyEmployeeTimeDetail_opDate_Include2] ON [ops].[dailyEmployeeTimeDetail] ([opDate]) INCLUDE ([emp_SID], [payType]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_dailyEmployeeTimeDetail_opDate_Includes3] ON [ops].[dailyEmployeeTimeDetail] ([opDate]) INCLUDE ([emp_SID], [payType], [calcTime]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_dailyEmployeeTimeDetail_opDate_division_emp_SID_paysource_paytype_paydate] ON [ops].[dailyEmployeeTimeDetail] ([opDate], [division], [emp_SID], [paySource], [payType], [payDate]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_dailyEmployeeTimeDetail_paytype_opdate_includes2] ON [ops].[dailyEmployeeTimeDetail] ([payType], [opDate]) INCLUDE ([emp_SID], [calcTime]) ON [PRIMARY]
GO
