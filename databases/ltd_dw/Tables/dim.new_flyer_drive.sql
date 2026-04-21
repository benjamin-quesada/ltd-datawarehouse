CREATE TABLE [dim].[new_flyer_drive]
(
[drive_key] [int] NOT NULL IDENTITY(1, 1),
[start_spm_key] [bigint] NULL,
[end_spm_key] [bigint] NULL,
[drive_license_key] [bigint] NULL,
[drive_id] [bigint] NULL,
[license_number] [int] NULL,
[start_latitude] [decimal] (13, 8) NULL,
[start_longitude] [decimal] (13, 8) NULL,
[end_latitude] [decimal] (13, 8) NULL,
[end_longitude] [decimal] (13, 8) NULL,
[start_time] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[end_time] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[trip_start_spm] [bigint] NULL,
[trip_end_spm] [bigint] NULL,
[trip_start_calendar_id] [int] NULL,
[trip_end_calendar_id] [int] NULL,
[start_trip_glenwood] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[end_trip_glenwood] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dim].[new_flyer_drive] ADD CONSTRAINT [PK_new_flyer_drive] PRIMARY KEY CLUSTERED ([drive_key]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_new_flyer_drive_license_number_many_includes] ON [dim].[new_flyer_drive] ([license_number], [trip_start_calendar_id], [start_spm_key], [end_spm_key], [trip_start_spm], [trip_end_spm]) INCLUDE ([drive_license_key], [drive_id]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_new_flyer_drive_start_end_spm_keys_Includes] ON [dim].[new_flyer_drive] ([start_spm_key], [end_spm_key]) INCLUDE ([drive_license_key], [drive_id], [license_number], [trip_start_spm], [trip_end_spm], [trip_start_calendar_id]) ON [PRIMARY]
GO
