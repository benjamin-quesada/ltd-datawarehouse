CREATE TABLE [apc].[boarding_projection]
(
[calendar_date] [date] NOT NULL,
[day_of_week_nbr] [int] NOT NULL,
[isHoliday] [tinyint] NOT NULL,
[HH] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[route_abbr] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[stop_abbr] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rdir_abbr] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[predicted_board] [float] NOT NULL,
[record_created_date] [datetime2] NOT NULL DEFAULT (sysdatetime())
)
GO
