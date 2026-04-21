CREATE TABLE [ftk].[kWh_fuel_ticket_files]
(
[FuelTicketKey] [int] NOT NULL IDENTITY(1, 1),
[historyFuelTicketKey] [int] NULL,
[FuelTicketDateStart] [date] NOT NULL,
[FuelTicketDateEnd] [date] NOT NULL,
[FuelTicketContext] [varchar] (120) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[PricePerkWh] [decimal] (7, 3) NOT NULL,
[FuelTicketCreatedBy] [varchar] (90) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[FuelTicketCreateDate] [datetime2] NOT NULL CONSTRAINT [DF__kWh_fuel___FuelT__1BE8E8C5] DEFAULT (sysdatetime()),
[FuelTicketUpdatedBy] [varchar] (90) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FuelTicketUpdatedLast] [datetime2] NULL,
[FuelTicketHistoryRankorder] [int] NULL,
[FuelTicketFileDropDate] [datetime2] NULL,
[FuelTicketFileDroppedBy] [varchar] (90) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
