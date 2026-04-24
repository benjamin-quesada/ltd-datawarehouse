CREATE TABLE [eam].[fuel_main_on_hand_history]
(
[insert_datetime] [datetime] NULL CONSTRAINT [DF_fuel_main_on_hand_history_insert_datetime] DEFAULT (getdate()),
[fuel_type] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tank_tank_no] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cur_price] [numeric] (13, 4) NULL,
[qty_on_hand] [numeric] (14, 3) NULL,
[value_on_hand] [numeric] (12, 2) NULL
) ON [PRIMARY]
GO
