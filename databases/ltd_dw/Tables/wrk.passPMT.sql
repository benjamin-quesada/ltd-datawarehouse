CREATE TABLE [wrk].[passPMT]
(
[calendar_id] [int] NOT NULL,
[route_id] [int] NOT NULL,
[revenue_id] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[actual_miles] [decimal] (12, 3) NULL,
[Passenger_Miles] [decimal] (12, 3) NULL,
[Passenger_On] [int] NULL,
[Passenger_Off] [int] NULL
) ON [PRIMARY]
GO
