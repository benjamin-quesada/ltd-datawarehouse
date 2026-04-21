CREATE TABLE [ops].[absence]
(
[ops_absence_key] [int] NOT NULL IDENTITY(1, 1),
[emp_SID] [int] NOT NULL,
[absCode] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[absDateBegin] [smalldatetime] NOT NULL,
[absTimeBegin] [int] NOT NULL,
[absDateEnd] [smalldatetime] NOT NULL,
[absTimeEnd] [int] NULL,
[absFlags] [smallint] NOT NULL,
[stampBeginDate] [smalldatetime] NOT NULL,
[stampBeginUser] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[stampEndDate] [smalldatetime] NOT NULL,
[stampEndUser] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[callBegin] [smalldatetime] NOT NULL,
[callEnd] [smalldatetime] NOT NULL,
[prepayDate] [smalldatetime] NULL,
[prepayCode] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[comments] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[daysEffective] [smallint] NOT NULL,
[familyFMLA] [smallint] NOT NULL,
[personalFMLA] [smallint] NOT NULL,
[reviewFMLAStampDate] [datetime] NULL,
[reviewFMLAStampUser] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[mailFMLAStampDate] [datetime] NULL,
[mailFMLAStampUser] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[absenceReason] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[runNumber] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[empRelation] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[runPayOption] [smallint] NULL,
[record_created_date] [datetime2] NOT NULL CONSTRAINT [DF__Absence__record___1B8FE628] DEFAULT (sysdatetime()),
[record_updated_date] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [ops].[absence] ADD CONSTRAINT [PK_absence_absence_key] PRIMARY KEY CLUSTERED ([ops_absence_key]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_ops_Absence_absCode_Includes] ON [ops].[absence] ([absCode]) INCLUDE ([emp_SID], [absDateBegin], [absTimeBegin], [comments]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_ops_dailyAbsence_absDateBeg_absDateEnd_Include1] ON [ops].[absence] ([absDateBegin], [absDateEnd]) INCLUDE ([emp_SID]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_ops_dailyAbsence_absDateBeg_absTimeBeg_Include3] ON [ops].[absence] ([absDateBegin], [absDateEnd]) INCLUDE ([emp_SID], [absCode], [absTimeBegin]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_ops_absence_emp_SID_Includes4] ON [ops].[absence] ([emp_SID]) INCLUDE ([absCode], [absDateBegin], [absDateEnd], [comments]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_ops_absence_emp_SID_Include_absenceReason] ON [ops].[absence] ([emp_SID]) INCLUDE ([absenceReason]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_Absence_emp_SID_absCode_absDateBegin_absTimeBegin_Includes] ON [ops].[absence] ([emp_SID], [absCode], [absDateBegin], [absTimeBegin]) INCLUDE ([comments]) ON [PRIMARY]
GO
