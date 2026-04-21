CREATE TABLE [efare].[SALE_COMMENT]
(
[saleCommentKey] [bigint] NOT NULL IDENTITY(1, 1),
[txId] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[respstat] [nvarchar] (90) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[retref] [nvarchar] (90) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[account] [nvarchar] (42) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[token] [nvarchar] (42) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[profileid] [nvarchar] (42) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[amount] [money] NULL,
[merchid] [nvarchar] (42) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[respcode] [nvarchar] (90) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[resptext] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[respproc] [nvarchar] (90) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[batchid] [nvarchar] (42) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[avsresp] [nvarchar] (90) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cvvresp] [nvarchar] (90) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[authcode] [nvarchar] (90) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[commcard] [nvarchar] (90) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[fileloaded] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
