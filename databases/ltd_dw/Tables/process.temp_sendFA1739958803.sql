CREATE TABLE [process].[temp_sendFA1739958803]
(
[FA SR Number] [bigint] NOT NULL,
[Vehicle Number] [varchar] (42) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Service Required Category] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Bus Exchanged With] [varchar] (42) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Description of the Issue/Situation/Problem] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Sent By] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Sent Datetime] [varchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
