CREATE TABLE [eam].[partsMinMax_LeadTime]
(
[partsMinMax_LeadKey] [int] NOT NULL IDENTITY(1, 1),
[Year] [int] NULL,
[Month] [int] NULL,
[PART_part_no] [varchar] (22) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[part_suffix] [int] NOT NULL,
[Monthly Lead Time] [int] NOT NULL,
[Lead Time] [int] NULL,
[Cal Min Qty] [numeric] (38, 6) NULL,
[Cal Max Qty] [numeric] (38, 6) NULL,
[Cal Min Qty Round] [numeric] (38, 0) NULL,
[Cal Max Qty Round] [numeric] (38, 0) NULL,
[record_created_date] [datetime2] NOT NULL CONSTRAINT [DF__partsMinM__recor__7999BF87] DEFAULT (sysdatetime()),
[record_updated_date] [datetime2] NULL
) ON [PRIMARY]
GO
