CREATE TABLE [tm].[BLOCK]
(
[BLOCK_KEY] [int] NOT NULL IDENTITY(1, 1),
[BLOCK_ID] [numeric] (10, 0) NOT NULL,
[TIME_TABLE_VERSION_ID] [numeric] (5, 0) NOT NULL,
[BLOCK_ABBR] [varchar] (9) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[BLOCK_NUM] [numeric] (9, 0) NULL,
[PADDLE_NOTES] [varchar] (2000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SOURCE_BLOCK_ID] [numeric] (10, 0) NULL,
[MASTER_BLOCK_ID] [int] NULL,
[SERVICE_TYPE_ID] [numeric] (3, 0) NULL,
[OPERATING_MODE_ID] [numeric] (3, 0) NULL,
[record_created_date] [datetime2] NOT NULL CONSTRAINT [DF__BLOCK__record_cr__29EF7EF9] DEFAULT (sysdatetime()),
[record_updated_date] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [tm].[BLOCK] ADD CONSTRAINT [PK_BLOCK] PRIMARY KEY CLUSTERED ([BLOCK_KEY]) ON [PRIMARY]
GO
