CREATE TABLE [aud].[dataedo_user_sessions]
(
[session_id_key] [bigint] NOT NULL IDENTITY(1, 1),
[session_id] [int] NOT NULL,
[user_login] [nvarchar] (1024) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[authentication] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[license_type] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[login_date] [date] NULL,
[login_datetime] [datetime] NOT NULL,
[login_date_id] [int] NULL,
[web_sessions] [int] NOT NULL,
[desktop_sessions] [int] NOT NULL,
[all_sessions] [int] NULL,
[role_actions] [varchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[record_created_date] [datetime2] NOT NULL DEFAULT (sysdatetime()),
[record_updated_date] [datetime2] NULL
) ON [PRIMARY]
GO
