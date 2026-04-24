CREATE TABLE [process].[FileDrop]
(
[FileSendID] [int] NOT NULL IDENTITY(1, 1),
[FileDropName] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[FileDropGroup] [nvarchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[FileDropRowCount] [int] NOT NULL CONSTRAINT [DF__FileDrop__FileDr__59911583] DEFAULT ((0)),
[FileDropDateTime] [datetime2] NULL CONSTRAINT [DF__FileDrop__FileDr__5A8539BC] DEFAULT (sysdatetime())
) ON [PRIMARY]
GO
