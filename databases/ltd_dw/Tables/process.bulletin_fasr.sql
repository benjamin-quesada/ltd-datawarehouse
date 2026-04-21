CREATE TABLE [process].[bulletin_fasr]
(
[bulletin_id] [int] NOT NULL,
[FASR_Key] [bigint] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [process].[bulletin_fasr] ADD CONSTRAINT [PK_fasr_bulletin_bulletin_id] PRIMARY KEY CLUSTERED ([bulletin_id]) ON [PRIMARY]
GO
ALTER TABLE [process].[bulletin_fasr] ADD CONSTRAINT [FK_bulletin_fasr_bulletin_bulletin_id] FOREIGN KEY ([bulletin_id]) REFERENCES [process].[bulletin] ([bulletin_id])
GO
