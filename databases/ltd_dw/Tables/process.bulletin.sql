CREATE TABLE [process].[bulletin]
(
[bulletin_id] [int] NOT NULL IDENTITY(1, 1),
[topic_code] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[subject] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[message] [varchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[message_html] [varchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[message_text] [varchar] (160) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sent] [bit] NOT NULL CONSTRAINT [DF_bulletin_sent] DEFAULT ((0)),
[sent_time] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [process].[bulletin] ADD CONSTRAINT [PK_bulletin_bulletin_id] PRIMARY KEY CLUSTERED ([bulletin_id]) ON [PRIMARY]
GO
