CREATE TABLE [dbo].[newflyer_charge_tickets]
(
[chargeTicketKey] [bigint] NOT NULL IDENTITY(1, 1),
[eq_equip_no] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[EV Charger Serial Nbr] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Connector Number] [smallint] NULL,
[Energy Delivered (kWh)] [decimal] (12, 3) NULL,
[Session Start Time] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Session Stop Time] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Duration Minutes] [numeric] (38, 6) NULL,
[soc_reported_byABB_start] [decimal] (12, 3) NULL,
[soc_reported_byABB_stop] [decimal] (12, 3) NULL,
[soc_reported_byBus_start] [numeric] (18, 7) NULL,
[soc_reported_byBus_stop] [numeric] (18, 7) NULL,
[odo] [numeric] (12, 3) NULL,
[event_type_description] [varchar] (254) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[event_category] [int] NULL,
[min_event_time] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[max_event_time] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[trimmed_event_name] [varchar] (254) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[record_created_date] [datetime2] NULL CONSTRAINT [DF__newflyer___recor__0A695708] DEFAULT (sysdatetime())
) ON [PRIMARY]
GO
