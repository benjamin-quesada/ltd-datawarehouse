CREATE TABLE [tm].[state_of_charge]
(
[state_of_charge_key] [bigint] NOT NULL IDENTITY(1, 1),
[CALENDAR_ID] [int] NULL,
[LOCAL_TIMESTAMP] [datetime] NULL,
[START_TIME] [datetime] NULL,
[END_TIME] [datetime] NULL,
[StateOfCharge] [numeric] (12, 6) NULL,
[LastStateofCharge] [numeric] (12, 6) NULL,
[ChargeRecovery] [numeric] (13, 6) NULL,
[SecondsToEmpty] [int] NULL,
[MinutesToEmpty] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MilesToEmpty] [numeric] (17, 6) NULL,
[BLOCK_ID] [numeric] (10, 0) NULL,
[ROUTE_ID] [int] NULL,
[ROUTE_DIRECTION_ID] [numeric] (5, 0) NULL,
[TRIP_ID] [numeric] (10, 0) NULL,
[VEHICLE_ID] [numeric] (5, 0) NULL,
[PROPERTY_TAG] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[SERVICE_TYPE_ABBR] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[REVENUE_ID] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[maxSOC] [numeric] (12, 6) NULL,
[minSOC] [numeric] (12, 6) NULL,
[record_created_date] [datetime2] NOT NULL CONSTRAINT [DF__state_of___recor__00DA2345] DEFAULT (sysdatetime()),
[record_updated_date] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [tm].[state_of_charge] ADD CONSTRAINT [PK_state_of_charge] PRIMARY KEY CLUSTERED ([state_of_charge_key]) ON [PRIMARY]
GO
