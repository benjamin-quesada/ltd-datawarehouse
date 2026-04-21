CREATE TABLE [dbo].[z weatherResponses]
(
[respId] [int] NOT NULL IDENTITY(1, 1),
[respLocation] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[respText] [varchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
