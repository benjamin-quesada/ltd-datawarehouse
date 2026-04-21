CREATE TABLE [pds].[Integration_EmpAddress_Stage]
(
[person_id] [int] NULL,
[employee_id] [varchar] (9) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[address_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[address] [varchar] (254) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[address_line1] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[address_line2] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[address_line3] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[address_line4] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[address_lines] [varchar] (120) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[city] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[county] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[state] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[state_name] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[zip] [varchar] (9) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[zip_code] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
