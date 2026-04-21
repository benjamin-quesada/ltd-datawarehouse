CREATE TABLE [process].[FileLoad]
(
[FileLoadID] [int] NOT NULL IDENTITY(1, 1),
[FileSourceName] [nvarchar] (120) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[FileSourceGroup] [nvarchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[FileRowCount] [int] NOT NULL CONSTRAINT [DF__Fileload__FileRo__690797E6] DEFAULT ((0)),
[FileLoadDateTime] [datetime2] NULL CONSTRAINT [DF__Fileload__FileLo__69FBBC1F] DEFAULT (sysdatetime())
) ON [PRIMARY]
GO
