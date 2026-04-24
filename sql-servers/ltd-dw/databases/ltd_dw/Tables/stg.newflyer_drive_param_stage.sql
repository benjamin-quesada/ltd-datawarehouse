CREATE TABLE [stg].[newflyer_drive_param_stage]
(
[drive_param_stage_key] [int] NOT NULL IDENTITY(1, 1),
[parameter_spm_key] [bigint] NULL,
[parameter_type_key] [bigint] NULL,
[license_number] [int] NULL,
[last_input_value] [numeric] (18, 7) NULL,
[last_input_time] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[plastdate] [date] NULL,
[start_calendar_id] [int] NULL,
[start_spm] [int] NULL,
[record_created_date] [datetime2] NULL CONSTRAINT [DF__newflyer___recor__793A9C5A] DEFAULT (sysdatetime())
) ON [PRIMARY]
GO
