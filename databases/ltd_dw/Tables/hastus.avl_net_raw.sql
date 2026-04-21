CREATE TABLE [hastus].[avl_net_raw]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[filedate] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[RawLine] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
