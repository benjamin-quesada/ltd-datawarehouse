CREATE TABLE [tm].[profile_LTD_objects]
(
[RowNumber] [int] NOT NULL IDENTITY(0, 1),
[EventClass] [int] NULL,
[TextData] [ntext] COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ApplicationName] [nvarchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[NTUserName] [nvarchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[LoginName] [nvarchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ClientProcessID] [int] NULL,
[SPID] [int] NULL,
[StartTime] [datetime] NULL,
[DatabaseID] [int] NULL,
[DatabaseName] [nvarchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[NTDomainName] [nvarchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ServerName] [nvarchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SessionLoginName] [nvarchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[BinaryData] [image] NULL
) ON [PRIMARY]
GO
ALTER TABLE [tm].[profile_LTD_objects] ADD CONSTRAINT [PK__profile___AAAC09D8937DE8AB] PRIMARY KEY CLUSTERED ([RowNumber]) ON [PRIMARY]
GO
