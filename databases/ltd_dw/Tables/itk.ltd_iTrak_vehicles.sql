CREATE TABLE [itk].[ltd_iTrak_vehicles]
(
[vehicle_number] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[series] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[year] [int] NULL,
[manufacturer] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[model] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[type] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[license_no] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[VIN] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
