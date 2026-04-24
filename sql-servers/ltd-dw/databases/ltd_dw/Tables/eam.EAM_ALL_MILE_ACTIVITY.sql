CREATE TABLE [eam].[EAM_ALL_MILE_ACTIVITY]
(
[eam_mile_key] [bigint] NOT NULL IDENTITY(1, 1),
[label_name] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[the_date] [date] NULL,
[meter_value] [decimal] (18, 4) NULL,
[eq_equip_no] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[record_created_date] [datetime2] NULL CONSTRAINT [DF_EAM_ALL_MILE_ACTIVITY_record_created_date] DEFAULT (sysdatetime())
) ON [PRIMARY]
GO
ALTER TABLE [eam].[EAM_ALL_MILE_ACTIVITY] ADD CONSTRAINT [PK_EAM_ALL_MILE_ACTIVITY] PRIMARY KEY CLUSTERED ([eam_mile_key]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_eam_EAM_ALL_MILE_ACTIVITY_6137] ON [eam].[EAM_ALL_MILE_ACTIVITY] ([eq_equip_no]) INCLUDE ([label_name], [the_date], [meter_value], [record_created_date]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_eam_EAM_ALL_MILE_ACTIVITY_6155] ON [eam].[EAM_ALL_MILE_ACTIVITY] ([eq_equip_no]) INCLUDE ([the_date], [meter_value]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_EAM_ALL_MILE_ACTIVITY] ON [eam].[EAM_ALL_MILE_ACTIVITY] ([label_name], [the_date], [meter_value], [eq_equip_no]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_EAM_ALL_MILE_ACTIVITY_the_date_includes3] ON [eam].[EAM_ALL_MILE_ACTIVITY] ([the_date]) INCLUDE ([label_name], [meter_value], [eq_equip_no]) ON [PRIMARY]
GO
