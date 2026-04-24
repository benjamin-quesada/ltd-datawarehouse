CREATE TABLE [dbo].[SSRSv12_xml]
(
[ItemID] [uniqueidentifier] NOT NULL,
[Name] [nvarchar] (425) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Type] [int] NOT NULL,
[TypeDescription] [varchar] (14) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Content] [varbinary] (max) NULL,
[ContentVarchar] [varchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ContentXML] [xml] NULL
) ON [PRIMARY]
GO
