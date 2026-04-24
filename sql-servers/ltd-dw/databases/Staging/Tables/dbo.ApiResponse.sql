CREATE TABLE [dbo].[ApiResponse]
(
[ApiResponseId] [int] NOT NULL IDENTITY(1, 1),
[ApiRequestId] [int] NOT NULL,
[ReceivedAt] [datetime] NOT NULL DEFAULT (getdate()),
[HttpStatusCode] [int] NULL,
[Response] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[ApiResponse] ADD PRIMARY KEY CLUSTERED ([ApiResponseId]) ON [PRIMARY]
GO
