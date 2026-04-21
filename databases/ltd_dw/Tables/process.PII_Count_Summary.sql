CREATE TABLE [process].[PII_Count_Summary]
(
[rowId] [int] NOT NULL IDENTITY(1, 1),
[rn] [int] NOT NULL,
[srv] [varchar] (90) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[db] [varchar] (90) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tableNm] [varchar] (90) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tablesch] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rcount] [int] NULL,
[recordDate] [datetime2] NULL CONSTRAINT [DF__PII_Count__recor__345EC57D] DEFAULT (sysdatetime())
) ON [PRIMARY]
GO
