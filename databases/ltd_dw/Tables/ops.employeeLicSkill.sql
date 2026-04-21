CREATE TABLE [ops].[employeeLicSkill]
(
[employeeLicSkill_key] [int] NOT NULL IDENTITY(1, 1),
[recType] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[emp_SID] [int] NOT NULL,
[code] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date1] [smalldatetime] NOT NULL,
[sequence] [smallint] NOT NULL,
[date2] [smalldatetime] NOT NULL,
[comments] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[stampDate] [smalldatetime] NULL,
[stampUser] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[text1] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[text2] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[lastDateWorked] [datetime] NULL,
[qualifPayCode] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[qualifPayTime] [int] NULL,
[qualifMode] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[createdProcCode] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[instructor] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[clientFlags] [smallint] NOT NULL,
[record_created_date] [datetime2] NOT NULL CONSTRAINT [DF__employeeL__recor__3022E8FC] DEFAULT (sysdatetime()),
[record_updated_date] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [ops].[employeeLicSkill] ADD CONSTRAINT [PK_employeeLicSkill] PRIMARY KEY CLUSTERED ([employeeLicSkill_key]) ON [PRIMARY]
GO
