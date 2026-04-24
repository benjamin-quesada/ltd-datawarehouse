CREATE TABLE [dbo].[ApiRequest]
(
[ApiRequestId] [int] NOT NULL IDENTITY(1, 1),
[EtlProcessActivityId] [int] NULL,
[SourceSystem] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[EndpointName] [varchar] (200) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RequestUrl] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[HttpMethod] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL DEFAULT ('GET'),
[RequestHeaders] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RequestBody] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CredentialName] [sys].[sysname] NULL,
[TimeoutSeconds] [smallint] NOT NULL DEFAULT ((30)),
[RequestedAt] [datetime] NOT NULL DEFAULT (getdate())
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[ApiRequest] ADD PRIMARY KEY CLUSTERED ([ApiRequestId]) ON [PRIMARY]
GO
