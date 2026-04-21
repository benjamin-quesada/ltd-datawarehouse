CREATE TABLE [efare].[card_account_xref]
(
[cardAccount_key] [bigint] NOT NULL IDENTITY(10000000, 1),
[cardNumber] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS MASKED WITH (FUNCTION = 'partial(7, "oxxvv", 0)') NULL,
[accountId] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS MASKED WITH (FUNCTION = 'partial(7, "oxxvv", 0)') NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_efare_card_account_xref_cardNumber_accountId] ON [efare].[card_account_xref] ([cardNumber], [accountId]) ON [PRIMARY]
GO
