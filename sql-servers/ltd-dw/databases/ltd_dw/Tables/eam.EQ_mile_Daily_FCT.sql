CREATE TABLE [eam].[EQ_mile_Daily_FCT]
(
[eq_mile_key] [int] NOT NULL IDENTITY(1, 1),
[calendar_id] [int] NOT NULL,
[eq_key] [int] NOT NULL,
[mileage] [int] NOT NULL,
[delete_date] [datetime] NOT NULL,
[record_created_date] [datetime] NOT NULL CONSTRAINT [DF__EQ_mile_D__recor__68E8F8DB] DEFAULT (getdate()),
[record_updated_date] [datetime] NULL,
[pm_due_mileage] [int] NULL,
[pm_actual_mileage] [int] NULL,
[fuel_mileage] [int] NULL,
[out_of_service_mileage] [int] NULL
) ON [PRIMARY]
GO
ALTER TABLE [eam].[EQ_mile_Daily_FCT] ADD CONSTRAINT [pk_EQ_mile_Daily_FCT] PRIMARY KEY CLUSTERED ([eq_mile_key]) ON [PRIMARY]
GO
