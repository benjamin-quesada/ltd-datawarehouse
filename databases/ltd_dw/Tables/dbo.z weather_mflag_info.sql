CREATE TABLE [dbo].[z weather_mflag_info]
(
[mflag_id] [int] NOT NULL IDENTITY(1, 1),
[mflag_code] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[mflag_info] [varchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
