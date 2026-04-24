CREATE TABLE [efare].[fare_taps_detail]
(
[fare_tap_detail_key] [bigint] NOT NULL IDENTITY(1, 1),
[calendar_id] [int] NOT NULL,
[route_name] [varchar] (90) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[stopId] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RN] [int] NULL,
[card_holder_key] [int] NULL,
[transaction_count] [int] NULL,
[record_created_date] [datetime2] NULL CONSTRAINT [DF__fare_taps__recor__3B62254D] DEFAULT (sysdatetime())
) ON [PRIMARY]
GO
ALTER TABLE [efare].[fare_taps_detail] ADD CONSTRAINT [pk_fare_tap_detail_key] PRIMARY KEY CLUSTERED ([fare_tap_detail_key]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_efare_fare_taps_detail_calendar_id_includes_5] ON [efare].[fare_taps_detail] ([calendar_id]) INCLUDE ([route_name], [stopId], [RN], [card_holder_key], [transaction_count]) ON [PRIMARY]
GO
