CREATE TABLE [process].[ltd_NetworkSearchStringResults]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[output] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[extension] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SearchCode] [varchar] (22) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
