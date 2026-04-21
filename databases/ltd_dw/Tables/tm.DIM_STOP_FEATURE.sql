CREATE TABLE [tm].[DIM_STOP_FEATURE]
(
[stop_feature_key] [int] NOT NULL IDENTITY(1, 1),
[stop_business_key] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[stop_feature_status] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[STOP_ABBR] [varchar] (9) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[STOP_ID] [numeric] (10, 0) NOT NULL,
[GEO_NODE_NAME] [varchar] (75) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[STOP_FEATURE_ID] [numeric] (10, 0) NOT NULL,
[STOP_FEATURE_TEXT] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[bus_shelter] [bit] NULL,
[ud_shelter_type] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[bench] [bit] NULL,
[physical] [bit] NULL,
[layby] [bit] NULL,
[info_booth] [bit] NULL,
[accessible] [bit] NULL,
[parking] [bit] NULL,
[parking_size] [int] NULL,
[parking_fare] [varchar] (90) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[allow_boarding] [bit] NULL,
[allow_debarking] [bit] NULL,
[ud_deactivation] [date] NULL,
[ud_access] [varchar] (90) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ud_parking] [bit] NULL,
[desc_scode] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[record_created_date] [datetime2] NOT NULL CONSTRAINT [DF__DIM_STOP___recor__08961D2F] DEFAULT (sysdatetime()),
[record_updated_date] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [tm].[DIM_STOP_FEATURE] ADD CONSTRAINT [PK_DIM_STOP_FEATURE] PRIMARY KEY CLUSTERED ([stop_feature_key]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_DIM_STOP_FEATURE_stop_business_key_stop_freaure_status] ON [tm].[DIM_STOP_FEATURE] ([stop_business_key], [stop_feature_status]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_DIM_STOP_FEATURE_many] ON [tm].[DIM_STOP_FEATURE] ([stop_business_key], [stop_feature_status]) INCLUDE ([STOP_ABBR], [STOP_ID], [GEO_NODE_NAME], [STOP_FEATURE_ID], [STOP_FEATURE_TEXT], [bus_shelter], [ud_shelter_type], [bench], [layby], [info_booth], [accessible], [parking], [parking_size], [parking_fare], [allow_boarding], [allow_debarking], [ud_deactivation], [ud_access], [ud_parking], [desc_scode]) ON [PRIMARY]
GO
