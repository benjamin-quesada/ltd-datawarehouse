CREATE TABLE [sbp].[passenger_count_by_mode]
(
[sbp_board_id] [int] NOT NULL IDENTITY(1, 1),
[calendar_id] [nvarchar] (17) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Mode] [varchar] (11) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[board] [int] NULL,
[record_create_date] [datetime2] NULL CONSTRAINT [DF__passenger__recor__09CA388A] DEFAULT (sysdatetime())
) ON [PRIMARY]
GO
