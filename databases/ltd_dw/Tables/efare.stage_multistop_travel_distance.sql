CREATE TABLE [efare].[stage_multistop_travel_distance]
(
[tsInLocalTime] [datetime] NULL,
[ts_dt] [date] NULL,
[transaction_card_account_key] [bigint] NULL,
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
[tripSequence] [bigint] NULL
) ON [PRIMARY]
GO
