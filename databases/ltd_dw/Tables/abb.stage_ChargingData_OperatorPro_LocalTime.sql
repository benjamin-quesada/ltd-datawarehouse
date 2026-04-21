CREATE TABLE [abb].[stage_ChargingData_OperatorPro_LocalTime]
(
[Charge Session ID] [nvarchar] (90) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Session Start Time] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Session Stop Time] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SessionStartTimeLocal] [datetime] NULL,
[SessionStopTimeLocal] [datetime] NULL
) ON [PRIMARY]
GO
