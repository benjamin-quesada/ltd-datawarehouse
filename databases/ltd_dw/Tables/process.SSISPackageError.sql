CREATE TABLE [process].[SSISPackageError]
(
[Pkg_Error_Key] [int] NOT NULL IDENTITY(1, 1),
[Pk_ID] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Machine_Name] [nvarchar] (200) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Package_Name] [nvarchar] (200) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Task_Name] [nvarchar] (200) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Error_Code] [int] NULL,
[Error_Description] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Pkg_Error_DateTime] [datetime] NULL,
[record_created_date] [datetime2] NOT NULL CONSTRAINT [DF__SSISPacka__recor__33526120] DEFAULT (sysdatetime())
) ON [PRIMARY]
GO
