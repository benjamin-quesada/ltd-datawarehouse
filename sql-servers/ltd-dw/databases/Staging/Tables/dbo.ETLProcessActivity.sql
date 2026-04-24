CREATE TABLE [dbo].[ETLProcessActivity]
(
[ETLProcessActivityID] [int] NOT NULL IDENTITY(1, 1),
[ETLProcessID] [int] NOT NULL,
[StartTime] [datetime] NOT NULL,
[EndTime] [datetime] NULL,
[ProcessRowCount] [int] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[ETLProcessActivity] ADD CONSTRAINT [PK_ETLProcessActivity] PRIMARY KEY CLUSTERED ([ETLProcessActivityID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[ETLProcessActivity] ADD CONSTRAINT [FK_ETLProcessActivity_EtlProcessID] FOREIGN KEY ([ETLProcessID]) REFERENCES [dbo].[ETLProcess] ([ETLProcessID])
GO
