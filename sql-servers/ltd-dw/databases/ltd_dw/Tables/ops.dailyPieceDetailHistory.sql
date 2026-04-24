CREATE TABLE [ops].[dailyPieceDetailHistory]
(
[dailyPieceDetailHistoryKey] [int] NOT NULL IDENTITY(1, 1),
[division] [varchar] (4) COLLATE SQL_Latin1_General_CP850_CI_AS NULL,
[opDate] [smalldatetime] NULL,
[blockRoute] [varchar] (6) COLLATE SQL_Latin1_General_CP850_CI_AS NULL,
[blockID] [varchar] (6) COLLATE SQL_Latin1_General_CP850_CI_AS NULL,
[workClass] [varchar] (4) COLLATE SQL_Latin1_General_CP850_CI_AS NULL,
[keyTime] [int] NULL,
[modStampDate] [datetime] NULL,
[timeCode] [varchar] (4) COLLATE SQL_Latin1_General_CP850_CI_AS NULL,
[schWorkTime] [int] NULL,
[schAllowTime] [int] NULL,
[actWorkTime] [int] NULL,
[actAllowTime] [int] NULL,
[record_created_date] [datetime2] NOT NULL CONSTRAINT [DF__dailyPiec__recor__48B7925A] DEFAULT (sysdatetime()),
[record_updated_date] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [ops].[dailyPieceDetailHistory] ADD CONSTRAINT [pk_dailyPieceDetailHistory] PRIMARY KEY CLUSTERED ([dailyPieceDetailHistoryKey]) ON [PRIMARY]
GO
