CREATE TABLE [hastus].[note_stg]
(
[note_id] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[note_preferred_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[note_text] [varchar] (3500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[note_usage] [varchar] (150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[note_public_access] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[note_owner] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
