CREATE TABLE [nf].[newflyer_vehicledata1_stage]
(
[vd1LoadKey] [int] NOT NULL IDENTITY(1, 1),
[fileloaddt] [datetime2] NULL CONSTRAINT [DF__newflyer___filel__1DC01722] DEFAULT (sysdatetime()),
[fileloadname] [nvarchar] (120) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[response] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
