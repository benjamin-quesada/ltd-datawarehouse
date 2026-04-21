CREATE TABLE [fact].[drive_veh_spm_tm_info_save]
(
[drive_id] [bigint] NULL,
[license_number] [int] NULL,
[drive_license_key] [varchar] (38) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[start_spm_key] [bigint] NULL,
[end_spm_key] [bigint] NULL,
[time_table_version_id] [smallint] NULL,
[BLOCK_ID] [numeric] (10, 0) NULL,
[ROUTE_ID] [numeric] (10, 0) NULL,
[ROUTE_DIRECTION_ID] [numeric] (10, 0) NULL,
[OPERATOR_ID] [numeric] (5, 0) NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_ltd_drive_veh_spm_tm_info_licenseStartEnd_Includes] ON [fact].[drive_veh_spm_tm_info_save] ([license_number], [start_spm_key], [end_spm_key]) INCLUDE ([drive_license_key]) WITH (FILLFACTOR=56) ON [PRIMARY]
GO
