CREATE TABLE [stg].[newflyer_drive_event_stage]
(
[drive_event_stage_key] [bigint] NOT NULL IDENTITY(1, 1),
[event_spm_key] [varchar] (38) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[drive_id] [bigint] NULL,
[license_number] [int] NULL,
[drive_license_key] [varchar] (38) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[start_spm_key] [varchar] (38) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[end_spm_key] [varchar] (38) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[record_created_date] [datetime2] NULL CONSTRAINT [DF__newflyer___recor__087CDFEA] DEFAULT (sysdatetime())
) ON [PRIMARY]
GO
