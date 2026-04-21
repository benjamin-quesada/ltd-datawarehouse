CREATE TABLE [rpt].[Planning_NewFlyer_BLOCK_SOC]
(
[Planning_NewFlyer_BLOCK_SOC_Key] [int] NOT NULL IDENTITY(1, 1),
[calId] [int] NULL,
[license_number] [int] NOT NULL,
[badge] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[operator_name] [varchar] (64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[block_abbr] [varchar] (9) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[BEGIN_SOC] [decimal] (14, 5) NULL,
[END_SOC] [decimal] (14, 5) NULL,
[record_created_date] [datetime2] NOT NULL CONSTRAINT [DF__Planning___recor__06A7ABCF] DEFAULT (sysdatetime())
) ON [PRIMARY]
GO
