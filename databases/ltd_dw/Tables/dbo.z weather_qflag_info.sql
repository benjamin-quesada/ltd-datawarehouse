CREATE TABLE [dbo].[z weather_qflag_info]
(
[qflag_id] [int] NOT NULL IDENTITY(1, 1),
[qflag_code] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[qflag_info] [varchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
