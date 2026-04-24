CREATE TABLE [hastus].[avl_cal]
(
[avl_blk_key] [int] NOT NULL IDENTITY(1, 1),
[filedate] [date] NULL,
[file_row_id] [int] NOT NULL,
[p_DateStart] [date] NULL,
[p_DateEnd] [date] NULL,
[p_SchedUnit] [nvarchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[p_SchedSet] [nvarchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[scud_date] [date] NULL,
[DateCscSchedUnit] [nvarchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DateCscName] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DateCscTypeTitle] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DateCscType] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DateCscScen] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DateCscBooking] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DateVscSchedUnit] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DateVscName] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DateVscNameTxt] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DateVscType] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DateVscScen] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DateVscBooking] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[record_created_date] [datetime2] NOT NULL CONSTRAINT [DF__avl_cal__record___4E4FA099] DEFAULT (sysdatetime()),
[record_updated_date] [datetime2] NULL
) ON [PRIMARY]
GO
