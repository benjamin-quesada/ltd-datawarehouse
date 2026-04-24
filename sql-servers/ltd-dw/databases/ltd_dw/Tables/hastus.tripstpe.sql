CREATE TABLE [hastus].[tripstpe]
(
[vscver_id] [int] NULL,
[trip_no] [int] NULL,
[stop_position] [smallint] NULL,
[stop_id] [nvarchar] (9) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[passing_time] [nvarchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[inserted_by] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[inserted_datetime] [smalldatetime] NULL
) ON [PRIMARY]
GO
