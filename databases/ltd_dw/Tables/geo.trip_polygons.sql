CREATE TABLE [geo].[trip_polygons]
(
[trip_poly_key] [int] NOT NULL IDENTITY(1, 1),
[CALENDAR_ID] [numeric] (10, 0) NOT NULL,
[TIME_TABLE_VERSION_ID] [int] NULL,
[BLOCK_ID] [int] NULL,
[TRIP_ID] [numeric] (10, 0) NULL,
[polywkt] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[polygeog] [sys].[geography] NULL,
[record_created_date] [datetime2] NOT NULL CONSTRAINT [DF__trip_poly__recor__10189FEC] DEFAULT (sysdatetime())
) ON [PRIMARY]
GO
