CREATE TABLE [tm].[trip_geo_polygons]
(
[trip_poly_key] [int] NOT NULL IDENTITY(1, 1),
[CALENDAR_ID] [numeric] (10, 0) NOT NULL,
[TRIP_ID] [numeric] (10, 0) NULL,
[polywkt] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[polygeog] [sys].[geography] NULL,
[record_created_date] [datetime2] NOT NULL CONSTRAINT [DF__trip_acci__recor__3B4D16B4] DEFAULT (sysdatetime())
) ON [PRIMARY]
GO
