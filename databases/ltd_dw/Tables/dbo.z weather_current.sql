CREATE TABLE [dbo].[z weather_current]
(
[wthrkey] [int] NOT NULL IDENTITY(1, 1),
[lat] [float] NULL,
[lon] [float] NULL,
[dt] [datetime] NULL,
[temp] [float] NULL,
[feels_like] [float] NULL,
[pressure] [float] NULL,
[humidity] [float] NULL,
[clouds] [float] NULL,
[visibility] [float] NULL,
[wind_speed] [float] NULL,
[file_loaded] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
