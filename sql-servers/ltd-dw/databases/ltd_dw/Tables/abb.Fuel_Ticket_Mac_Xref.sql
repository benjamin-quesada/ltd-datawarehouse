CREATE TABLE [abb].[Fuel_Ticket_Mac_Xref]
(
[BUS NO] [varchar] (14) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MAC ID] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TRANSFER] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FIRST TRANSACTION] [datetime] NULL,
[LAST TRANSACTION] [datetime] NULL
) ON [PRIMARY]
GO
