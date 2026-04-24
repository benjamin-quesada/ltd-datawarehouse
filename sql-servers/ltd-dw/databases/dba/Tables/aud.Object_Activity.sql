CREATE TABLE [aud].[Object_Activity]
(
[Procedure_Activity_ID] [int] NOT NULL IDENTITY(1, 1),
[server_name] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[database_name] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[host_name] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[System_User] [nvarchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[object_name] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[client_net_address] [nvarchar] (48) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[local_net_address] [nvarchar] (48) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[auth_Scheme] [nvarchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[last_read] [datetime] NULL,
[last_write] [datetime] NULL,
[most_recent_sql_handle] [varbinary] (64) NULL,
[Timestamp] [datetime] NOT NULL,
[object_type] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [aud].[Object_Activity] ADD CONSTRAINT [PK_Procedure_Activity] PRIMARY KEY CLUSTERED ([Procedure_Activity_ID]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_Procedure_Activity_host_name_System_user_Object_name_timestamp] ON [aud].[Object_Activity] ([host_name], [System_User], [object_name], [Timestamp]) ON [PRIMARY]
GO
