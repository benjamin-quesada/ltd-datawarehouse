CREATE TABLE [wrk].[passPMTwc]
(
[calendar_id] [int] NOT NULL,
[route_id] [int] NOT NULL,
[actual_miles] [decimal] (12, 3) NULL,
[Passenger_Miles] [decimal] (12, 3) NULL,
[Passenger_On] [int] NULL,
[Passenger_Off] [int] NULL
) ON [PRIMARY]
GO
