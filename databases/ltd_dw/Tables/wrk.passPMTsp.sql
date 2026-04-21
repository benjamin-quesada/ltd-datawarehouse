CREATE TABLE [wrk].[passPMTsp]
(
[calendar_id] [int] NOT NULL,
[route_abbr] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[actual_miles] [int] NULL,
[Passenger_Miles] [decimal] (12, 3) NULL,
[Passenger_On] [int] NULL,
[Passenger_Off] [int] NULL
) ON [PRIMARY]
GO
