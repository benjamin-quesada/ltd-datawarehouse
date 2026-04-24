CREATE TABLE [wrk].[opsPayCodeSumm2]
(
[opDate] [date] NULL,
[opYearDiff] [int] NULL,
[payType] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[codeType] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[codeValue] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Description] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ff_projectCode] [varchar] (88) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ff_groupby] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[lastName] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[firstname] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[personnelID] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[operator_lastfirst] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[feeds_attendance] [int] NOT NULL,
[calcTime] [int] NULL,
[ff_negative_calc_times] [int] NULL,
[ff_formattedCalcTime] [numeric] (17, 6) NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_temp_opsPayCodeSumm2] ON [wrk].[opsPayCodeSumm2] ([personnelID], [payType], [codeType], [codeValue], [feeds_attendance], [opYearDiff], [Description], [ff_projectCode], [opDate]) ON [PRIMARY]
GO
