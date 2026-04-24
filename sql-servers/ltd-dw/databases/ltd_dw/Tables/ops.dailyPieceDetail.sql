CREATE TABLE [ops].[dailyPieceDetail]
(
[ops_dailyPieceDetail_key] [int] NOT NULL IDENTITY(1, 1),
[division] [varchar] (4) COLLATE SQL_Latin1_General_CP850_CI_AS NOT NULL,
[timeCode] [varchar] (4) COLLATE SQL_Latin1_General_CP850_CI_AS NOT NULL,
[opDate] [smalldatetime] NOT NULL,
[blockRoute] [varchar] (6) COLLATE SQL_Latin1_General_CP850_CI_AS NOT NULL,
[schWorkTime] [int] NULL,
[actWorkTime] [int] NULL,
[blockID] [varchar] (6) COLLATE SQL_Latin1_General_CP850_CI_AS NOT NULL,
[workClass] [varchar] (4) COLLATE SQL_Latin1_General_CP850_CI_AS NOT NULL,
[keyTime] [int] NOT NULL,
[schAllowedTime] [int] NULL,
[actAllowedTime] [int] NULL,
[pieceDtFlag] [smallint] NULL,
[record_created_date] [datetime2] NOT NULL CONSTRAINT [DF__dailyPiec__recor__193D8962] DEFAULT (sysdatetime()),
[record_updated_date] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [ops].[dailyPieceDetail] ADD CONSTRAINT [PK_dailyPieceDetail] PRIMARY KEY CLUSTERED ([ops_dailyPieceDetail_key]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_dailyPieceDetail_division_timeCode_opDate_blockRoute_blockID_workClass_keyTime] ON [ops].[dailyPieceDetail] ([division], [timeCode], [opDate], [blockRoute], [blockID], [workClass], [keyTime]) ON [PRIMARY]
GO
