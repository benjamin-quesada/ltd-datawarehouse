CREATE TABLE [nf].[newflyer_vehicledata1]
(
[vehicledata1Key] [bigint] NOT NULL IDENTITY(1, 1),
[vehicle_id] [int] NULL,
[unit_id] [int] NULL,
[group_id] [int] NULL,
[group_name] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[client_id] [int] NULL,
[unit_serial] [int] NULL,
[license_number] [int] NULL,
[chassis_number] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[last_communication_time] [datetime] NULL,
[last_communication_time_local] [datetime] NULL,
[last_position_time] [datetime] NULL,
[last_position_time_local] [datetime] NULL,
[latitude] [decimal] (15, 8) NULL,
[longitude] [decimal] (15, 8) NULL,
[speed] [numeric] (4, 2) NULL,
[direction] [int] NULL,
[status] [int] NULL,
[last_event_time] [datetime] NULL,
[last_event_time_local] [datetime] NULL,
[last_event_type] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[current_driver] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[current_driver_number] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[driver_name] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[worker_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[current_drive] [bigint] NULL,
[last_mileage] [numeric] (17, 3) NULL,
[record_created_date] [datetime2] NULL CONSTRAINT [DF__newflyer___recor__70DA924D] DEFAULT (sysdatetime())
) ON [PRIMARY]
GO
ALTER TABLE [nf].[newflyer_vehicledata1] ADD CONSTRAINT [PK_newflyer_vehicledata1] PRIMARY KEY CLUSTERED ([vehicledata1Key]) ON [PRIMARY]
GO
