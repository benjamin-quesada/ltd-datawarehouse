CREATE TABLE [nf].[ScheduleTM_WithNF_Drive]
(
[schedTMNFKey] [int] NOT NULL IDENTITY(1, 1),
[drive_id] [bigint] NULL,
[vehicle_id] [int] NULL,
[license_number] [int] NOT NULL,
[CalId] [int] NOT NULL,
[BLOCK_ID] [numeric] (10, 0) NULL,
[TRIP_ID] [numeric] (10, 0) NULL,
[LAST_NAME] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[FIRST_NAME] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MIDDLE_NAME] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ROUTE_ABBR] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ROUTE_NAME] [varchar] (75) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ROUTE_DIRECTION_ABBR] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ROUTE_DIRECTION_NAME] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
