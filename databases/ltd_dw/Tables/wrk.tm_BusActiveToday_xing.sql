CREATE TABLE [wrk].[tm_BusActiveToday_xing]
(
[unique_id] [int] NOT NULL IDENTITY(1, 1),
[bus] [varchar] (9) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[miles] [numeric] (9, 2) NULL,
[block] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[xing_spm] [int] NULL,
[adherence] [int] NULL
) ON [PRIMARY]
GO
ALTER TABLE [wrk].[tm_BusActiveToday_xing] ADD CONSTRAINT [PK__tm_BusAc__A292913034413449] PRIMARY KEY CLUSTERED ([unique_id]) ON [PRIMARY]
GO
