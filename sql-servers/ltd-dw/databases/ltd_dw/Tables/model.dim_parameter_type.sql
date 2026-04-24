CREATE TABLE [model].[dim_parameter_type]
(
[parameter_type_key] [int] NOT NULL IDENTITY(1, 1),
[parameter_type] [int] NOT NULL,
[parameter_type_description] [varchar] (120) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
