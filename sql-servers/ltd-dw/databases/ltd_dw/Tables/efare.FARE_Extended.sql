CREATE TABLE [efare].[FARE_Extended]
(
[fareLoadKey] [bigint] NOT NULL IDENTITY(1, 1),
[txId] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ts] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[type] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[mediaUsed] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[mediaType] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[fareType] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cardNumber] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[accountId] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cardAccount_key] [bigint] NULL,
[stopName] [varchar] (90) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[stopId] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[routeName] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[latitude] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[longitude] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[reader] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[vehicle] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[passUsed] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[productAbbreviation] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[trip] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[readerPosition] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[fare] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[routeTypeId] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[routeTypeName] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[fileloaded] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[postedTs] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[passFirstUsed] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[lastModifiedTs] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[stopGtfsId] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[stopGtfsCode] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[model_partition] [int] NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_efare_fare_extended_stop_id_include6] ON [efare].[FARE_Extended] ([stopId]) INCLUDE ([ts], [fareType], [cardNumber], [accountId], [cardAccount_key], [routeName]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_efare_FARE_Extended_stopId] ON [efare].[FARE_Extended] ([stopId]) INCLUDE ([ts], [type], [fareType], [cardAccount_key], [routeName], [latitude], [longitude]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_efare_FARE_Extended_stopId_latitude_longitude_include5] ON [efare].[FARE_Extended] ([stopId], [latitude], [longitude]) INCLUDE ([ts], [type], [fareType], [cardAccount_key], [routeName]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_FARE_Extended_txId] ON [efare].[FARE_Extended] ([txId]) ON [PRIMARY]
GO
