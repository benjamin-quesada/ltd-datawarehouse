CREATE TABLE [dbo].[SubWeather]
(
[F1] [datetime] NULL,
[F2] [datetime] NULL,
[F3] [datetime] NULL,
[Temp] [float] NULL,
[Hi_a] [float] NULL,
[Low] [float] NULL,
[Out] [float] NULL,
[Dew] [float] NULL,
[Wind] [float] NULL,
[Wind1] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Wind2] [float] NULL,
[Hi1] [float] NULL,
[Hi2] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Wind3] [float] NULL,
[Heat] [float] NULL,
[THW] [float] NULL,
[THSW] [float] NULL,
[F18] [float] NULL,
[F19] [float] NULL,
[Rain] [float] NULL,
[Solar] [float] NULL,
[Solar1] [float] NULL,
[Hi Solar] [float] NULL,
[UV ] [float] NULL,
[UV 1] [float] NULL,
[Hi_b] [float] NULL,
[Heat1] [float] NULL,
[Cool] [float] NULL,
[F29] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[x] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[350] [float] NULL,
[3501] [float] NULL,
[F33] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[SubWeather] TO [public]
GO
