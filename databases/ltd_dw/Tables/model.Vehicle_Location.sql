CREATE TABLE [model].[Vehicle_Location]
(
[vehLocationKey] [int] NOT NULL IDENTITY(1, 1),
[sourceKey] [varchar] (90) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[license_number] [int] NULL,
[cal_spm_key] [bigint] NULL,
[GPS LAT] [decimal] (14, 5) NULL,
[GPS LON] [decimal] (14, 5) NULL,
[record_created_date] [datetime2] NOT NULL CONSTRAINT [DF__Vehicle_L__recor__5FBEF025] DEFAULT (sysdatetime()),
[record_updated_date] [datetime2] NULL
) ON [PRIMARY]
GO
