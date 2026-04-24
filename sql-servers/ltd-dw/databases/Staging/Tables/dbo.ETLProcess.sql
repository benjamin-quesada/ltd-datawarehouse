CREATE TABLE [dbo].[ETLProcess]
(
[ETLProcessID] [int] NOT NULL IDENTITY(1, 1),
[ProcessName] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[SourceDBName] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[SourceObject] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[DestinationDBName] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[DestinationObject] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Description] [varchar] (200) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[ETLProcess] ADD CONSTRAINT [PK_ETLProcess] PRIMARY KEY CLUSTERED ([ETLProcessID]) ON [PRIMARY]
GO
