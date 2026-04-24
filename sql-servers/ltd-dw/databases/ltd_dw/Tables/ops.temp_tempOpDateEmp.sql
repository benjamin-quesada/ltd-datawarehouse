CREATE TABLE [ops].[temp_tempOpDateEmp]
(
[opdate] [date] NULL,
[emp_sid] [int] NOT NULL,
[work] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[absence] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[worked] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[DNC] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
