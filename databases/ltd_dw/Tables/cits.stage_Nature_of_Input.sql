CREATE TABLE [cits].[stage_Nature_of_Input]
(
[ID] [int] NOT NULL,
[filesource] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Nature of Input] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Category] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[IsActive] [bit] NOT NULL
) ON [PRIMARY]
GO
