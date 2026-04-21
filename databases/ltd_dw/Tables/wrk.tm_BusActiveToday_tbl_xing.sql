CREATE TABLE [wrk].[tm_BusActiveToday_tbl_xing]
(
[unique_id] [int] NOT NULL IDENTITY(1, 1),
[bus] [varchar] (9) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[miles] [numeric] (9, 2) NULL,
[block] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[xing_spm] [int] NULL,
[adherence] [int] NULL
) ON [PRIMARY]
GO
ALTER TABLE [wrk].[tm_BusActiveToday_tbl_xing] ADD CONSTRAINT [PK__tm_BusAc__A2929130C1F6F1BA] PRIMARY KEY CLUSTERED ([unique_id]) ON [PRIMARY]
GO
