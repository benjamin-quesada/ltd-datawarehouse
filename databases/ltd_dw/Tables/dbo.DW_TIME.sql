CREATE TABLE [dbo].[DW_TIME]
(
[DWTimeKey] [int] NOT NULL,
[Hour24] [int] NULL,
[Hour24ShortString] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Hour24MinString] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Hour24FullString] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Hour12] [int] NULL,
[Hour12ShortString] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Hour12MinString] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Hour12FullString] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[AmPmCode] [int] NULL,
[AmPmString] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Minute] [int] NULL,
[MinuteCode] [int] NULL,
[MinuteShortString] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MinuteFullString24] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MinuteFullString12] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[HalfHour] [int] NULL,
[HalfHourCode] [int] NULL,
[HalfHourShortString] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[HalfHourFullString24] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[HalfHourFullString12] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Second] [int] NULL,
[SecondShortString] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FullTimeString24] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FullTimeString12] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FullTime] [time] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[DW_TIME] ADD CONSTRAINT [PK_DW_TIME] PRIMARY KEY CLUSTERED ([DWTimeKey]) ON [PRIMARY]
GO
