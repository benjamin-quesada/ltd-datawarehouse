CREATE TABLE [ops].[absencePay]
(
[ops_absencePay_Key] [int] NOT NULL IDENTITY(1, 1),
[emp_SID] [int] NOT NULL,
[absCode] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[absDateBegin] [smalldatetime] NOT NULL,
[absTimeBegin] [int] NOT NULL,
[codeDateBegin] [smalldatetime] NOT NULL,
[absPayCode] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[codeDateEnd] [smalldatetime] NOT NULL,
[stampCodeDate] [smalldatetime] NOT NULL,
[stampCodeUser] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[absPayDivision] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[absPayFlags] [smallint] NOT NULL,
[absPayTime] [int] NULL,
[absPayAmount] [int] NULL,
[stampNoPayDate] [smalldatetime] NULL,
[stampNoPayUser] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[comments] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[maxWorkTime] [int] NULL,
[record_created_date] [datetime2] NOT NULL CONSTRAINT [DF__absencePa__recor__52963419] DEFAULT (sysdatetime()),
[record_updated_date] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [ops].[absencePay] ADD CONSTRAINT [pk_absencePay] PRIMARY KEY CLUSTERED ([ops_absencePay_Key]) ON [PRIMARY]
GO
