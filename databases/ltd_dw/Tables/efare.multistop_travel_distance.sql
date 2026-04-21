CREATE TABLE [efare].[multistop_travel_distance]
(
[multistop_key] [bigint] NOT NULL IDENTITY(1, 1),
[transaction_card_account_key] [bigint] NULL,
[tsInLocalTime] [datetime] NULL,
[ts_dt] [date] NULL,
[fareType] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[route] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[stopId] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[latitude] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[longitude] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[next_stopid] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[next_stopid_lat] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[next_stopid_lon] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[next_board_time] [datetime] NULL,
[first_board] [datetime] NULL,
[last_board] [datetime] NULL,
[first_to_last_board_seconds] [int] NULL,
[tsInLocalTimeCalId] [int] NULL,
[tsInLocalTimeSPM] [int] NULL,
[tripSequence] [bigint] NULL,
[record_created_date] [datetime2] NOT NULL CONSTRAINT [DF__multistop__recor__000C5555] DEFAULT (sysdatetime())
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_efare_multistop_travel_distance_21837] ON [efare].[multistop_travel_distance] ([transaction_card_account_key], [tsInLocalTime]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_efare_multistop_travel_distance_20788] ON [efare].[multistop_travel_distance] ([ts_dt]) INCLUDE ([transaction_card_account_key], [tsInLocalTime], [fareType], [route], [stopId], [latitude], [longitude], [next_stopid], [next_stopid_lat], [next_stopid_lon], [next_board_time], [first_board], [last_board], [first_to_last_board_seconds], [tsInLocalTimeCalId], [tsInLocalTimeSPM], [tripSequence]) ON [PRIMARY]
GO
