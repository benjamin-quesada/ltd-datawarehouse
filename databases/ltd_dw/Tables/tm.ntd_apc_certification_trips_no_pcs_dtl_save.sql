CREATE TABLE [tm].[ntd_apc_certification_trips_no_pcs_dtl_save]
(
[FiscalYear] [int] NULL,
[Fiscal Year Name] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[calendar_id] [numeric] (10, 0) NULL,
[vehicle_id] [numeric] (5, 0) NULL,
[trip_id] [numeric] (10, 0) NULL,
[TRIP_END_TIME] [numeric] (9, 0) NULL,
[PROPERTY_TAG] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[board] [int] NULL,
[alight] [int] NULL
) ON [PRIMARY]
GO
