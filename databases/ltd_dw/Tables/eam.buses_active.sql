CREATE TABLE [eam].[buses_active]
(
[buses_active_key] [int] NOT NULL IDENTITY(1, 1),
[CALENDAR_ID] [int] NULL,
[PROPERTY_TAG] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[odo] [int] NULL,
[countMsgs] [int] NULL,
[record_created_date] [datetime2] NOT NULL CONSTRAINT [DF__buses_act__recor__119E61DC] DEFAULT (sysdatetime())
) ON [PRIMARY]
GO
