CREATE TABLE [process].[FileSend]
(
[FileSendID] [int] NOT NULL IDENTITY(1, 1),
[FileSendName] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[FilesendGroup] [nvarchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[FileRowCount] [int] NOT NULL CONSTRAINT [DF__filesend__FileRo__2B554987] DEFAULT ((0)),
[FileSendDateTime] [datetime2] NULL CONSTRAINT [DF__filesend__FileSe__2C496DC0] DEFAULT (sysdatetime())
) ON [PRIMARY]
GO
