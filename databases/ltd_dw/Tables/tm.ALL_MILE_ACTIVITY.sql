CREATE TABLE [tm].[ALL_MILE_ACTIVITY]
(
[tm_mile_key] [bigint] NOT NULL IDENTITY(1, 1),
[label_name] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[the_date] [date] NULL,
[miles_value] [decimal] (18, 4) NULL,
[hours_value] [decimal] (18, 4) NULL,
[eq_equip_no] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[record_created_date] [datetime2] NULL CONSTRAINT [DF_TM_ALL_MILE_ACTIVITY_record_created_date] DEFAULT (sysdatetime()),
[record_updated_date] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [tm].[ALL_MILE_ACTIVITY] ADD CONSTRAINT [PK_EAM_ALL_MILE_ACTIVITY] PRIMARY KEY CLUSTERED ([tm_mile_key]) ON [PRIMARY]
GO
