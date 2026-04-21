CREATE TABLE [efare].[reporting_time]
(
[RN] [int] NOT NULL IDENTITY(1, 1),
[MN] [int] NOT NULL,
[H] [int] NULL,
[M] [int] NULL,
[S] [int] NULL,
[HHMM] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[HHMM_TE] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
