CREATE TABLE [efare].[tap_count_summaries]
(
[tap_count_key] [bigint] NOT NULL IDENTITY(1, 1),
[calendar_id] [int] NOT NULL,
[testsource] [varchar] (42) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[card_holder_key] [varchar] (56) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[testinfo] [nvarchar] (42) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[transaction_count] [int] NULL,
[record_created_date] [datetime2] NOT NULL CONSTRAINT [DF__tap_count__recor__055A4F00] DEFAULT (sysdatetime())
) ON [PRIMARY]
GO
ALTER TABLE [efare].[tap_count_summaries] ADD CONSTRAINT [PK_tap_count_summaries] PRIMARY KEY CLUSTERED ([tap_count_key]) ON [PRIMARY]
GO
