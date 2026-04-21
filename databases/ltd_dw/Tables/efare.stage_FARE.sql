CREATE TABLE [efare].[stage_FARE]
(
[fareLoadKey] [bigint] NOT NULL IDENTITY(1, 1),
[txID] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ts] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[type] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[mediaUsed] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[mediaType] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cardNumber] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[fareType] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[accountId] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[routeName] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[routeNumber] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[latitude] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[longitude] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[reader] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[passUsed] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[readerPosition] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[fare] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[fileloading] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
