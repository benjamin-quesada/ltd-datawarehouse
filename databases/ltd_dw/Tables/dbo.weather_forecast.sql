CREATE TABLE [dbo].[weather_forecast]
(
[wthrForecastKey] [int] NOT NULL IDENTITY(1, 1),
[lat] [nvarchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[lon] [nvarchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[dt] [datetime2] (3) NULL,
[temp] [float] NULL,
[humidity] [float] NULL,
[clouds] [float] NULL,
[visibility] [float] NULL,
[wind_speed] [float] NULL,
[wind_gust] [float] NULL,
[weatherMain] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[weatherDesc] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[file_loaded] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[weather_forecast] ADD CONSTRAINT [PK_weather_forecast] PRIMARY KEY CLUSTERED ([wthrForecastKey]) ON [PRIMARY]
GO
