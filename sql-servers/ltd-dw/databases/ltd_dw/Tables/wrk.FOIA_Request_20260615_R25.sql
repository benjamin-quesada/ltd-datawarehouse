CREATE TABLE [wrk].[FOIA_Request_20260615_R25]
(
[nt] [bigint] NULL,
[calendar_id] [numeric] (10, 0) NOT NULL,
[calendar_date] [datetime] NOT NULL,
[msg_time] [char] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rte_and_dir] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[stop] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[stop_name] [varchar] (75) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[service_type_general] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trip_end] [char] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[board] [int] NOT NULL,
[alight] [int] NOT NULL,
[pc_latitude] [numeric] (23, 10) NULL,
[pc_longitude] [numeric] (23, 10) NULL
)
GO
