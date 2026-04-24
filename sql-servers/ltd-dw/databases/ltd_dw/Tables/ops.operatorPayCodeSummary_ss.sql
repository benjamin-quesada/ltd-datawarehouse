CREATE TABLE [ops].[operatorPayCodeSummary_ss]
(
[operatorPayCodeSummary_Key] [bigint] NOT NULL IDENTITY(1, 1),
[opDate] [date] NOT NULL,
[opYearDiff] [int] NOT NULL,
[payType] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[calcTime] [int] NULL,
[ff_negative_calc_times] [smallint] NOT NULL CONSTRAINT [DF__operatorP__ff_ne__50E05DD3] DEFAULT ((0)),
[ff_formattedCalcTime] [numeric] (17, 6) NULL,
[codeType] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[codeValue] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[description] [varchar] (90) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ff_projectCode] [varchar] (90) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ff_groupby] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[lastName] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[firstName] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[personnelID] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[operator_lastfirst] [varchar] (67) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[feeds_attendance] [int] NOT NULL,
[record_created_date] [datetime2] NOT NULL CONSTRAINT [DF__operatorP__recor__51D4820C] DEFAULT (sysdatetime()),
[record_updated_date] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [ops].[operatorPayCodeSummary_ss] ADD CONSTRAINT [PK_operatorPayCodeSummary_ss] PRIMARY KEY CLUSTERED ([operatorPayCodeSummary_Key]) ON [PRIMARY]
GO
