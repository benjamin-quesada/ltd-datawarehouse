CREATE TABLE [dbo].[weather_current_stage]
(
[wthrLoadKey] [int] NOT NULL IDENTITY(1, 1),
[lat] [nvarchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[lon] [nvarchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[curr_weather] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[fileloading] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
