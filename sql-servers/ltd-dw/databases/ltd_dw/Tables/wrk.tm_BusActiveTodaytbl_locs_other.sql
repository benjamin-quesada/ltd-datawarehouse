CREATE TABLE [wrk].[tm_BusActiveTodaytbl_locs_other]
(
[unique_id] [int] NOT NULL IDENTITY(1, 1),
[bus] [varchar] (9) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[miles] [numeric] (9, 2) NULL
) ON [PRIMARY]
GO
ALTER TABLE [wrk].[tm_BusActiveTodaytbl_locs_other] ADD CONSTRAINT [PK__tm_BusAc__A2929130120AE5B7] PRIMARY KEY CLUSTERED ([unique_id]) ON [PRIMARY]
GO
