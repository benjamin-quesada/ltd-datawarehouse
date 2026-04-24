CREATE TABLE [process].[PII_All_Count]
(
[rowid] [int] NOT NULL IDENTITY(1, 1),
[allRecords] [int] NULL,
[recordDate] [datetime2] NULL CONSTRAINT [DF__PII_All_C__recor__2F9A1060] DEFAULT (sysdatetime())
) ON [PRIMARY]
GO
