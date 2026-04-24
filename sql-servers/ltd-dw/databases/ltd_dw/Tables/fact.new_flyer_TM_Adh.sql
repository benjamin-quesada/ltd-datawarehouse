CREATE TABLE [fact].[new_flyer_TM_Adh]
(
[cal_msgspm_key] [varchar] (38) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[calendar_id] [numeric] (10, 0) NOT NULL,
[time_table_version_id] [int] NOT NULL,
[veh] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[BLOCK_ID] [numeric] (10, 0) NULL,
[ROUTE_DIRECTION_ID] [numeric] (5, 0) NULL,
[ROUTE_ID] [int] NULL,
[RTE] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[RTE_DIR] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[BLOCK_STOP_ORDER] [int] NOT NULL,
[GEO_NODE_ABBR] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[OPERATOR_ID] [numeric] (5, 0) NULL,
[LATITUDE] [numeric] (12, 0) NULL,
[LONGITUDE] [numeric] (12, 0) NULL,
[ADHERENCE] [numeric] (5, 0) NULL,
[record_created_date] [datetime2] NULL CONSTRAINT [DF__new_flyer__recor__3E88198C] DEFAULT (sysdatetime()),
[record_updated_date] [datetime2] NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_INIT_new_flyer_TM_Adh_calendar_id_6] ON [fact].[new_flyer_TM_Adh] ([calendar_id]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_new_flyer_TM_Adh_calendar_id_7429] ON [fact].[new_flyer_TM_Adh] ([calendar_id]) INCLUDE ([cal_msgspm_key], [time_table_version_id], [veh], [BLOCK_ID], [ROUTE_DIRECTION_ID], [ROUTE_ID], [RTE], [RTE_DIR], [BLOCK_STOP_ORDER], [GEO_NODE_ABBR], [OPERATOR_ID], [LATITUDE], [LONGITUDE]) ON [PRIMARY]
GO
