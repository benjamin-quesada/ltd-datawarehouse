CREATE TABLE [tm].[logged_messages]
(
[tm_logged_message_key] [bigint] NOT NULL IDENTITY(1, 1),
[calendar_id] [int] NULL,
[local_timestamp] [datetime] NULL,
[calendar_date] [datetime] NOT NULL,
[day_type] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[veh] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[bus_class] [varchar] (11) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[artic] [int] NULL,
[emx_bus] [int] NULL,
[message_type_id] [smallint] NOT NULL,
[message_type_text] [varchar] (131) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[via_wlan] [int] NULL,
[odometer] [numeric] (7, 2) NULL,
[mdt_hhmmss] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[mdt_spm] [int] NULL,
[route] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[block] [varchar] (9) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[stop_no] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[stop_name] [varchar] (75) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[dir] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tp_id] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tp_name] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[operator] [varchar] (42) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[latitude] [int] NULL,
[longitude] [int] NULL,
[adherence] [smallint] NULL,
[validity] [smallint] NULL,
[FOM] [int] NULL,
[receiving_dgps] [int] NOT NULL,
[valid_odometer] [int] NOT NULL,
[valid_adherence] [int] NOT NULL,
[valid_position] [int] NOT NULL,
[sp_place] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[east_west_zone] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[north_south_zone] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[flag32] [int] NULL,
[route_version] [int] NULL,
[messages_version] [int] NULL,
[route_offset] [smallint] NULL,
[effective_service] [smallint] NULL,
[direction] [tinyint] NULL,
[time_point_offset] [smallint] NULL,
[stop_offset] [smallint] NULL,
[ons] [tinyint] NULL,
[offs] [tinyint] NULL,
[msg_group] [int] NULL,
[cat_1] [tinyint] NULL,
[cat_2] [tinyint] NULL,
[cat_3] [tinyint] NULL,
[cat_4] [tinyint] NULL,
[cat_5] [tinyint] NULL,
[cat_6] [tinyint] NULL,
[cat_7] [tinyint] NULL,
[cat_8] [tinyint] NULL,
[cat_9] [tinyint] NULL,
[cat_10] [tinyint] NULL,
[lower32] [int] NULL,
[upper32] [int] NULL,
[long_field_2] [int] NULL,
[current_driver] [int] NULL,
[free_text_msg] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[mdt_block_id] [int] NULL,
[blk_id] [numeric] (10, 0) NULL,
[transmitted_message_id] [bigint] NOT NULL,
[record_created_date] [datetime2] NOT NULL CONSTRAINT [DF__logged_me__recor__17EA6F97] DEFAULT (sysdatetime()),
[record_updated_date] [datetime2] NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_tm_logged_messages_26080] ON [tm].[logged_messages] ([calendar_date]) INCLUDE ([calendar_id], [veh], [message_type_id], [message_type_text], [via_wlan], [mdt_hhmmss], [mdt_spm], [latitude], [longitude], [east_west_zone], [north_south_zone]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_logged_messages_calendar_id_veh_odometer] ON [tm].[logged_messages] ([calendar_id], [route]) INCLUDE ([veh], [odometer]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_logged_messages_local_timestamp] ON [tm].[logged_messages] ([local_timestamp]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tm_logged_messages_local_timestamp_veh_latitude_longitude_includes_all] ON [tm].[logged_messages] ([local_timestamp], [veh], [latitude], [longitude]) INCLUDE ([calendar_id], [calendar_date], [day_type], [bus_class], [artic], [emx_bus], [message_type_id], [message_type_text], [via_wlan], [odometer], [mdt_hhmmss], [mdt_spm], [route], [block], [stop_no], [stop_name], [dir], [tp_id], [tp_name], [operator], [adherence], [validity], [FOM], [receiving_dgps], [sp_place], [east_west_zone], [north_south_zone], [route_version], [messages_version], [route_offset], [effective_service], [direction], [time_point_offset], [stop_offset], [ons], [offs], [msg_group], [current_driver], [free_text_msg], [mdt_block_id], [blk_id]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_tm_logged_messages_26070] ON [tm].[logged_messages] ([message_type_id], [local_timestamp]) INCLUDE ([veh], [artic], [emx_bus], [validity], [flag32]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_logged_messages_route_includes3] ON [tm].[logged_messages] ([route]) INCLUDE ([calendar_id], [veh], [odometer]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_ltd_logged_messages_transmitted_message_id] ON [tm].[logged_messages] ([transmitted_message_id]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_tm_logged_messages_26076] ON [tm].[logged_messages] ([veh], [valid_position], [local_timestamp]) INCLUDE ([artic], [emx_bus]) ON [PRIMARY]
GO
