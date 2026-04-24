CREATE TABLE [model].[tm_trips]
(
[trip_key] [int] NOT NULL IDENTITY(1, 1),
[calendar_id] [int] NOT NULL,
[trip_id] [int] NOT NULL,
[geo_node_id] [int] NOT NULL,
[TRIP_CAL_STOP_KEY] [varchar] (90) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[record_created_date] [datetime2] NOT NULL CONSTRAINT [DF_model.trips_record_created_date] DEFAULT (sysdatetime())
) ON [PRIMARY]
GO
ALTER TABLE [model].[tm_trips] ADD CONSTRAINT [PK_tm_trips] PRIMARY KEY CLUSTERED ([trip_key]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_model_tm_trips_calendar_id_include_record_created_date] ON [model].[tm_trips] ([calendar_id]) INCLUDE ([record_created_date]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_trips_calendar_id_trip_id_geo_node_id] ON [model].[tm_trips] ([calendar_id], [trip_id], [geo_node_id]) ON [PRIMARY]
GO
