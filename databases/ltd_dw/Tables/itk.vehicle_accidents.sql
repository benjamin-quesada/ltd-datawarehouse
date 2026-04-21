CREATE TABLE [itk].[vehicle_accidents]
(
[vehicle_accident_key] [int] NOT NULL IDENTITY(1, 1),
[FileNumber] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SelectionText] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CreatedBy] [nvarchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Occured] [datetime] NULL,
[EmployeeNumber] [numeric] (6, 0) NULL,
[specific] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[category] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[BusNumber] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RouteNumber] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Street] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CrossStreet] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[BodilyInjury] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PropertyDamage] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Preventable] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Type] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[record_created_date] [datetime2] NOT NULL CONSTRAINT [DF__vehicle_a__recor__653B2D50] DEFAULT (sysdatetime()),
[record_updated_date] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [itk].[vehicle_accidents] ADD CONSTRAINT [PK_vehicle_accidents] PRIMARY KEY CLUSTERED ([vehicle_accident_key]) ON [PRIMARY]
GO
