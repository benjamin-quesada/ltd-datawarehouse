CREATE TABLE [hastus].[note]
(
[note_id] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[note_preferred_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[note_text] [varchar] (3500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[note_usage] [varchar] (150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[note_public_access] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[note_owner] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[record_create_date] [datetime] NULL CONSTRAINT [DF__note__record_cre__7AF13DF7] DEFAULT (getdate())
) ON [PRIMARY]
GO
ALTER TABLE [hastus].[note] ADD CONSTRAINT [PK_note] PRIMARY KEY CLUSTERED ([note_id]) ON [PRIMARY]
GO
