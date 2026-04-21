CREATE TABLE [wrk].[eam_tm_stagedFuelData]
(
[EQ_equip_no] [varchar] (20) COLLATE SQL_Latin1_General_CP850_CI_AS NULL,
[ftk_date] [datetime] NULL,
[ftk_cal_id] [int] NULL,
[qty_fuel] [numeric] (14, 3) NULL,
[fuel_miles] [int] NULL
) ON [PRIMARY]
GO
