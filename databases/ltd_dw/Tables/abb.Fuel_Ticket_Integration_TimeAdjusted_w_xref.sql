CREATE TABLE [abb].[Fuel_Ticket_Integration_TimeAdjusted_w_xref]
(
[fuelTicketKey] [int] NOT NULL IDENTITY(1, 1),
[Fuel_String] [nvarchar] (85) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[recordTypeFuelXtn] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[chgtday] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[chgtime] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[license_number] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[userId] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[siteId] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[pumpID] [nvarchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FuelType] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[charge_session_id] [varchar] (90) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[quantity] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[meter1] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[quantity_deformatted] [decimal] (12, 4) NULL,
[record_created_date] [datetime2] NOT NULL CONSTRAINT [DF_TimeAdjusted_w_xref_record_created_date] DEFAULT (sysdatetime()),
[record_updated_date] [datetime2] NULL,
[record_sent_to_eam] [datetime2] NULL,
[record_sent_to_YrMo_file] [datetime2] NULL
) ON [PRIMARY]
GO
