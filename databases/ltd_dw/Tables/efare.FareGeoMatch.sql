CREATE TABLE [efare].[FareGeoMatch]
(
[fareMatchKey] [bigint] NOT NULL IDENTITY(1, 1),
[fareLoadKey] [bigint] NOT NULL,
[txID] [bigint] NOT NULL,
[ts] [datetime2] NOT NULL,
[type] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[mediaUsed] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[mediaType] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cardNumber] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[fareType] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[accountId] [bigint] NULL,
[routeName] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[routeNumber] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[fare_lat] [decimal] (18, 14) NULL,
[fare_lon] [decimal] (18, 14) NULL,
[reader] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[passUsed] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[readerPosition] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[fare] [money] NULL,
[geo_node_id] [int] NOT NULL,
[geo_node_lat] [decimal] (18, 14) NOT NULL,
[geo_node_lon] [decimal] (18, 14) NOT NULL,
[radius] [smallint] NOT NULL,
[Distance4326] [decimal] (32, 14) NULL,
[GeoNodeDistanceToFarePoint] [decimal] (18, 14) NULL,
[IsLocated] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[record_created_date] [datetime2] NOT NULL CONSTRAINT [DF__FareGeoMa__recor__1B50BA5D] DEFAULT (sysdatetime()),
[record_updated_date] [datetime2] NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_efare_FareGeoMatch_card_account] ON [efare].[FareGeoMatch] ([accountId], [cardNumber]) ON [PRIMARY]
GO
