CREATE TABLE [hastus].[layovers_by_the_minute]
(
[booking_id] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sched_type_id] [smallint] NOT NULL,
[place_id] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[minute] [smallint] NOT NULL
) ON [PRIMARY]
GO
