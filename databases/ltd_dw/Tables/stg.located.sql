CREATE TABLE [stg].[located]
(
[license_number] [int] NOT NULL,
[loc_cal_spm] [bigint] NULL,
[tm_cal_spm_vehicle] [varchar] (38) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[latitude] [decimal] (18, 9) NOT NULL,
[longitude] [decimal] (18, 9) NOT NULL,
[direction] [decimal] (18, 9) NOT NULL,
[speed] [decimal] (18, 9) NOT NULL,
[mileage] [decimal] (18, 9) NOT NULL,
[vehicle_status] [int] NOT NULL
) ON [PRIMARY]
GO
