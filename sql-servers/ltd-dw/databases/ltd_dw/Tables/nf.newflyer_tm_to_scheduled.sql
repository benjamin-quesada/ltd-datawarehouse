CREATE TABLE [nf].[newflyer_tm_to_scheduled]
(
[nf_tm_key] [int] NOT NULL IDENTITY(1, 1),
[calendar_id] [numeric] (10, 0) NOT NULL,
[TRIP_END_TIME] [numeric] (9, 0) NULL,
[cal_spm_key] [varchar] (38) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cal_arr_key] [varchar] (38) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cal_dep_key] [varchar] (38) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cal_nf_key] [varchar] (38) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[drive_id] [bigint] NULL,
[license_number] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[block_id] [numeric] (10, 0) NULL,
[block] [varchar] (9) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trip_id] [numeric] (10, 0) NULL,
[actual_duration] [int] NULL,
[rte] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rte_dir] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[operator] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[scheduled_time] [int] NULL,
[scheduled_license_number] [int] NULL,
[scheduled_operator] [varchar] (323) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[minOdo_TransitMaster] [numeric] (9, 2) NULL,
[maxOdo_TransitMaster] [numeric] (9, 2) NULL,
[record_created_date] [datetime2] NULL
) ON [PRIMARY]
GO
