CREATE TABLE [fact].[drive_veh_spm_tm_info]
(
[rn_key] [int] NOT NULL IDENTITY(1, 1),
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
ALTER TABLE [fact].[drive_veh_spm_tm_info] ADD CONSTRAINT [PK_drive_veh_spm_tm_info] PRIMARY KEY CLUSTERED ([rn_key]) ON [PRIMARY]
GO
