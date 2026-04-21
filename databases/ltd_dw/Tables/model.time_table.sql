CREATE TABLE [model].[time_table]
(
[Hour] [int] NULL,
[Minute] [int] NULL,
[Second] [smallint] NULL,
[MESSAGE_TIME] [int] NOT NULL,
[HMSFMT] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[HMFMTSMALL] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[HMS] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[HHMMSS] [varchar] (8000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[H] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[M] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[S] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MU] [int] NULL,
[MU_FMT] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[HHMM_TE] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[HHMM_TE_FMT] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
