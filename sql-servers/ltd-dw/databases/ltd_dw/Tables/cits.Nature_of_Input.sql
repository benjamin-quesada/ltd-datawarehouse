CREATE TABLE [cits].[Nature_of_Input]
(
[CITS_Nature_Key] [int] NOT NULL IDENTITY(1, 1),
[ID] [int] NULL,
[Nature of Input] [nvarchar] (90) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Category] [nvarchar] (90) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[IsActive] [bit] NOT NULL,
[filesource] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[record_created_date] [datetime2] NOT NULL CONSTRAINT [DF__Nature_of__recor__587037EB] DEFAULT (sysdatetime()),
[record_updated_date] [datetime2] NULL,
[record_update_count] [int] NULL CONSTRAINT [DF__Nature_of__recor__59645C24] DEFAULT ((0))
) ON [PRIMARY]
GO
