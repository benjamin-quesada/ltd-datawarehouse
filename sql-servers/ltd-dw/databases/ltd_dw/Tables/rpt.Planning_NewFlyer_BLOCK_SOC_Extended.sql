CREATE TABLE [rpt].[Planning_NewFlyer_BLOCK_SOC_Extended]
(
[calId] [int] NULL,
[license_number] [int] NULL,
[Badge] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[operator_name] [varchar] (23) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[drive_id] [bigint] NULL,
[block_abbr] [varchar] (9) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[kWhUsed] [decimal] (38, 5) NULL,
[HighAcceleration] [int] NULL,
[HighBraking] [int] NULL,
[BEGIN_SOC] [decimal] (18, 6) NULL,
[END_SOC] [decimal] (18, 6) NULL
) ON [PRIMARY]
GO
