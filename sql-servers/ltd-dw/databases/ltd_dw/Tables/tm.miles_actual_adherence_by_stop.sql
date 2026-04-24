CREATE TABLE [tm].[miles_actual_adherence_by_stop]
(
[ACTUAL_MILES_KEY] [bigint] NOT NULL IDENTITY(1, 1),
[ADHERENCE_BY_STOP_ID] [bigint] NULL,
[REVENUE_DISTANCE] [numeric] (17, 6) NULL,
[DEADHEAD_DISTANCE] [numeric] (17, 6) NULL,
[GARAGE_DISTANCE] [numeric] (17, 6) NULL,
[MESSAGE_TIME] [int] NULL,
[RECORD_CREATED_DATE] [datetime2] NOT NULL CONSTRAINT [DF__miles_act__RECOR__14B92EFB] DEFAULT (sysdatetime()),
[RECORD_UPDATED_DATE] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [tm].[miles_actual_adherence_by_stop] ADD CONSTRAINT [PK_ACTUAL_MILES_KEY] PRIMARY KEY CLUSTERED ([ACTUAL_MILES_KEY]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_miles_actual_adherence_by_stop_ADHERENCE_BY_STOP_ID] ON [tm].[miles_actual_adherence_by_stop] ([ADHERENCE_BY_STOP_ID]) ON [PRIMARY]
GO
