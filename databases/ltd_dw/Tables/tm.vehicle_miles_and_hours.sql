CREATE TABLE [tm].[vehicle_miles_and_hours]
(
[veh_miles_hours_key] [int] NOT NULL IDENTITY(1, 1),
[calendar_id] [int] NOT NULL,
[cal_yr_key] AS (right(left([calendar_id],(5)),(4))),
[vehicle_number] [int] NULL,
[miles] [numeric] (10, 0) NULL,
[hours] [numeric] (13, 3) NULL,
[record_created_date] [datetime2] NULL CONSTRAINT [DF__vehicle_m__recor__07F6FEB1] DEFAULT (sysdatetime()),
[record_updated_date] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [tm].[vehicle_miles_and_hours] ADD CONSTRAINT [PK_vehicle_miles_and_hours] PRIMARY KEY CLUSTERED ([veh_miles_hours_key]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_vehicle_miles_and_hours] ON [tm].[vehicle_miles_and_hours] ([calendar_id]) INCLUDE ([vehicle_number]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_vehicle_miles_and_hours_vehicle_number_Includes4] ON [tm].[vehicle_miles_and_hours] ([vehicle_number]) INCLUDE ([calendar_id], [cal_yr_key], [miles], [hours]) ON [PRIMARY]
GO
