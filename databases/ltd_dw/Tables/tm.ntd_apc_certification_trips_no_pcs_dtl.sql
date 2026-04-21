CREATE TABLE [tm].[ntd_apc_certification_trips_no_pcs_dtl]
(
[trip_no_pc_key] [bigint] NOT NULL IDENTITY(1, 1),
[FiscalYear] [int] NULL,
[Fiscal Year Name] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[calendar_id] [numeric] (10, 0) NULL,
[vehicle_id] [numeric] (5, 0) NULL,
[trip_id] [numeric] (10, 0) NULL,
[TRIP_END_TIME] [numeric] (9, 0) NULL,
[PROPERTY_TAG] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[board] [int] NULL,
[alight] [int] NULL,
[record_created_date] [datetime2] NOT NULL CONSTRAINT [DF__ntd_apc_c__recor__252996C2] DEFAULT (sysdatetime()),
[record_updated_date] [datetime2] NULL
) ON [PRIMARY]
GO
