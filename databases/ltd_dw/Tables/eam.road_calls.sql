CREATE TABLE [eam].[road_calls]
(
[roadcall_key] [int] NOT NULL IDENTITY(1, 1),
[work_order_yr] [int] NULL,
[work_order_no] [int] NULL,
[work_order_yr_no] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[eq_equip_no] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MilesAtLastRC] [int] NOT NULL,
[milesBetweenRC] [int] NULL,
[record_creeated_date] [datetime2] NOT NULL CONSTRAINT [DF__road_call__recor__78E42D8C] DEFAULT (sysdatetime())
) ON [PRIMARY]
GO
