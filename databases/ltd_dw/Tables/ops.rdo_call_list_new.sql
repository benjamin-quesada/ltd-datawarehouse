CREATE TABLE [ops].[rdo_call_list_new]
(
[emp_sid] [int] NOT NULL,
[personnelid] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[lastname] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[firstname] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[vacationsendate] [smalldatetime] NULL,
[vacationsenlottery] [int] NULL,
[dateseniority] [smalldatetime] NOT NULL,
[lottery] [int] NULL,
[fonehome] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[fonecell] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[phonenum1] [varchar] (14) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[workweek] [varchar] (4) COLLATE SQL_Latin1_General_CP850_CI_AS NULL,
[vaccount] [int] NOT NULL,
[abscount] [int] NOT NULL,
[asncount] [int] NOT NULL,
[donotcall] [varchar] (4) COLLATE SQL_Latin1_General_CP850_CI_AS NULL
) ON [PRIMARY]
GO
