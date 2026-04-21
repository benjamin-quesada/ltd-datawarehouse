CREATE TABLE [ops].[dailyAbsence]
(
[ops_dailyAbsence_Key] [int] NOT NULL IDENTITY(1, 1),
[emp_SID] [int] NOT NULL,
[division] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[opDate] [smalldatetime] NOT NULL,
[absCode] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[absDateBegin] [smalldatetime] NOT NULL,
[absTimeBegin] [int] NOT NULL,
[codeDateBegin] [smalldatetime] NOT NULL,
[paidTime] [int] NULL,
[workDateBegin] [smalldatetime] NOT NULL,
[absPayCode] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[premiumTime] [int] NULL,
[leaveTime] [int] NULL,
[includeInWorkTime] [int] NULL,
[detailFlags] [int] NOT NULL,
[accrualLeaveType] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[accrualLeaveYearID] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[initialTime] [int] NULL,
[record_created_date] [datetime2] NOT NULL CONSTRAINT [DF__dailyAbse__recor__1E6C52D3] DEFAULT (sysdatetime()),
[record_updated_date] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [ops].[dailyAbsence] ADD CONSTRAINT [PK_dailyAbsence_key] PRIMARY KEY CLUSTERED ([ops_dailyAbsence_Key]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_ops_dailyAbsence_absDateBegin] ON [ops].[dailyAbsence] ([absDateBegin]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_ops_dailyAbsence_absDateBeg_Include4] ON [ops].[dailyAbsence] ([absDateBegin]) INCLUDE ([emp_SID], [absCode], [absTimeBegin], [absPayCode]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_ops_dailyAbsence_emp_SID_absCode_absDateBeg_absTimeBeg_Include3] ON [ops].[dailyAbsence] ([absDateBegin]) INCLUDE ([emp_SID], [opDate], [absCode], [absTimeBegin], [paidTime], [absPayCode]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_ops_dailyAbsence_paidTimeopDateabsCode_Includes] ON [ops].[dailyAbsence] ([paidTime], [opDate], [absCode]) INCLUDE ([emp_SID], [division], [absDateBegin], [absTimeBegin]) ON [PRIMARY]
GO
