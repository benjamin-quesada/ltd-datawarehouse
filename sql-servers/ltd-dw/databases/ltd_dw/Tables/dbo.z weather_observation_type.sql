CREATE TABLE [dbo].[z weather_observation_type]
(
[wot_id] [int] NOT NULL IDENTITY(1, 1),
[weather_type_code] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[weather_type_desc] [varchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
