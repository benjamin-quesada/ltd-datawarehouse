CREATE TABLE [lkp].[zip_code]
(
[zip] [nvarchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[type] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[decommissioned] [int] NULL,
[primary_city] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[acceptable_cities] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[unacceptable_cities] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[state] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[county] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[timezone] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[area_codes] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[world_region] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[country] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[latitude] [float] NULL,
[longitude] [float] NULL,
[irs_estimated_population_2015] [int] NULL
) ON [PRIMARY]
GO
