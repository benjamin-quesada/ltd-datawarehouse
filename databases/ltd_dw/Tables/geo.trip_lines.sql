CREATE TABLE [geo].[trip_lines]
(
[trip_line_key] [int] NOT NULL IDENTITY(1, 1),
[CALENDAR_ID] [numeric] (10, 0) NOT NULL,
[TIME_TABLE_VERSION_ID] [int] NULL,
[BLOCK_ID] [int] NULL,
[TRIP_ID] [numeric] (10, 0) NULL,
[linewkt] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[linegeog] [sys].[geography] NULL,
[record_created_date] [datetime2] NOT NULL CONSTRAINT [DF__trip_geo___recor__20EE2633] DEFAULT (sysdatetime())
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_geo_trip_lines_CALENDAR_ID_BLOCK_ID_TRIP_ID] ON [geo].[trip_lines] ([CALENDAR_ID], [BLOCK_ID], [TRIP_ID]) ON [PRIMARY]
GO
