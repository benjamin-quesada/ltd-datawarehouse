CREATE TABLE [lcog].[data_deliveries_passenger]
(
[lcog_passenger_key] [int] NOT NULL IDENTITY(1, 1),
[srv] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[the_date] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[block] [int] NULL,
[trip_end] [char] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[time] [char] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[route] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[dir] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[stop] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[stop_name] [varchar] (75) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[latitude] [numeric] (10, 7) NULL,
[longitude] [numeric] (10, 7) NULL,
[bus] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[odometer] [numeric] (9, 2) NULL,
[ons] [int] NOT NULL,
[offs] [int] NOT NULL,
[load] [int] NULL,
[record_created_date] [datetime2] NOT NULL CONSTRAINT [DF__data_deli__recor__6F418A3C] DEFAULT (sysdatetime()),
[record_recipients] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[record_sent_date] [datetime2] NULL
) ON [PRIMARY]
GO
